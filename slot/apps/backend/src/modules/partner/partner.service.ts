import { BadRequestException, Injectable, NotFoundException } from "@nestjs/common";
import { DataSource } from "typeorm";
import {
  Booking,
  Seat,
  SeatStatus,
  BookingStatus,
  Service,
  SalonService,
  Salon,
  Combo,
} from "../../entities";

@Injectable()
export class PartnerService {
  constructor(private readonly dataSource: DataSource) {}

  private async resolveSalonId(salonId?: string): Promise<string> {
    if (!salonId) throw new BadRequestException('A salon context is required.');
    return salonId;
  }

  async getSalon(salonId?: string) {
    const id = await this.resolveSalonId(salonId);
    const salon = await this.dataSource.getRepository(Salon).findOne({ where: { id } });
    if (!salon) throw new NotFoundException('Salon not found.');
    return salon;
  }

  async updateSalon(salonId: string | undefined, dto: {
    name?: string; address?: string; city?: string; area?: string;
    openingTime?: string; closingTime?: string; timezone?: string;
    coverImage?: string;
  }) {
    const salon = await this.getSalon(salonId);
    if (dto.timezone) {
      try { new Intl.DateTimeFormat('en-US', { timeZone: dto.timezone }).format(); }
      catch { throw new BadRequestException('Invalid IANA timezone.'); }
    }
    if (dto.name !== undefined) salon.name = dto.name;
    if (dto.address !== undefined) salon.address = dto.address;
    if (dto.city !== undefined) salon.city = dto.city;
    if (dto.area !== undefined) salon.area = dto.area;
    if (dto.openingTime !== undefined) salon.opening_time = dto.openingTime;
    if (dto.closingTime !== undefined) salon.closing_time = dto.closingTime;
    if (dto.timezone !== undefined) salon.timezone = dto.timezone;
    if (dto.coverImage !== undefined) salon.cover_image = dto.coverImage;
    return this.dataSource.getRepository(Salon).save(salon);
  }

  async getDashboard(salonId?: string) {
    const targetSalonId = await this.resolveSalonId(salonId);

    const seats = await this.dataSource.getRepository(Seat).find({
      where: { salon_id: targetSalonId, is_active: true },
    });

    const availableSeats = seats.filter(
      (s) => s.status === SeatStatus.AVAILABLE,
    ).length;
    const inServiceSeats = seats.filter(
      (s) => s.status === SeatStatus.IN_SERVICE,
    ).length;

    const salon = await this.dataSource.getRepository(Salon).findOne({ where: { id: targetSalonId } });
    if (!salon) throw new NotFoundException('Salon not found.');
    const bookings = await this.dataSource.getRepository(Booking)
      .createQueryBuilder('b')
      .leftJoinAndSelect('b.customer', 'customer')
      .leftJoinAndSelect('b.seat', 'seat')
      .leftJoinAndSelect('b.services', 'services')
      .where('b.salon_id = :salonId', { salonId: targetSalonId })
      .andWhere('(b.start_at AT TIME ZONE :timezone)::date = (NOW() AT TIME ZONE :timezone)::date', { timezone: salon.timezone })
      .orderBy('b.start_at', 'ASC')
      .getMany();

    const todayBookingsCount = bookings.length;
    const waitingCount = bookings.filter(
      (b) => b.status === BookingStatus.WAITING,
    ).length;
    const totalRevenue = bookings.filter((booking) => booking.status === BookingStatus.DONE).reduce(
      (sum, b) => sum + parseFloat(b.total_amount?.toString() || "0"),
      0,
    );

    return {
      todayRevenue: totalRevenue,
      revenueComparison: null,
      todayBookings: todayBookingsCount,
      availableSeats,
      waitingCustomers: waitingCount,
      inServiceCustomers: inServiceSeats,
      liveFloor: seats.map((s) => ({
        id: s.id,
        seatNumber: s.seat_number,
        label: s.label,
        status: s.status,
      })),
      upNext: bookings.slice(0, 5).map((b) => ({
        id: b.id,
        title: b.customer?.name || "Customer",
        services:
          b.services && b.services.length > 0 ? b.services[0].service_name : "",
        time: b.start_at.toISOString(),
        seat: b.seat?.label || "Seat",
        status: b.status,
      })),
      businessInsights: {
        title: "Performance Insights",
        subtitle: `${todayBookingsCount} bookings processed today`,
      },
    };
  }

  async getReports(period: string = "Week", salonId?: string) {
    const targetSalonId = await this.resolveSalonId(salonId);
    const normalizedPeriod = ['Day', 'Week', 'Month'].includes(period) ? period : 'Week';
    const periodDays = normalizedPeriod === 'Day' ? 1 : normalizedPeriod === 'Month' ? 30 : 7;
    const start = new Date(Date.now() - periodDays * 86400000);
    const bookings = await this.dataSource.getRepository(Booking)
      .createQueryBuilder('b')
      .leftJoinAndSelect('b.services', 'services')
      .where('b.salon_id = :salonId', { salonId: targetSalonId })
      .andWhere('b.start_at >= :start', { start })
      .orderBy('b.start_at', 'ASC')
      .getMany();
    const totalBookings = bookings.length;
    const completed = bookings.filter((booking) => booking.status === BookingStatus.DONE);
    const completedCount = completed.length;
    const cancelledCount = bookings.filter((booking) => booking.status === BookingStatus.CANCELLED).length;
    const totalRevenue = completed.reduce((sum, booking) => sum + Number(booking.total_amount), 0);

    const avgTicket =
      totalBookings > 0 ? (totalRevenue / totalBookings).toFixed(0) : "0";

    const buckets = new Map<string, number>();
    for (const booking of completed) {
      const key = normalizedPeriod === 'Day'
        ? `${booking.start_at.getUTCHours().toString().padStart(2, '0')}:00`
        : booking.start_at.toISOString().slice(0, 10);
      buckets.set(key, (buckets.get(key) || 0) + Number(booking.total_amount));
    }
    const chartData = Array.from(buckets, ([day, value]) => ({ day, value }));
    const serviceCounts = new Map<string, number>();
    for (const booking of bookings) {
      for (const service of booking.services || []) {
        serviceCounts.set(service.service_name, (serviceCounts.get(service.service_name) || 0) + 1);
      }
    }
    const mostPopularService = Array.from(serviceCounts.entries()).sort((a, b) => b[1] - a[1])[0]?.[0] || null;

    const periodLabel =
      normalizedPeriod === "Day"
        ? "DAILY REVENUE"
        : normalizedPeriod === "Month"
          ? "MONTHLY REVENUE"
          : "WEEKLY REVENUE";

    return {
      period: normalizedPeriod,
      periodLabel,
      totalRevenue,
      revenueChange: null,
      chartData,
      metrics: {
        totalBookings,
        completedBookings: completedCount,
        cancelledBookings: cancelledCount,
        averageTicket: `₹${avgTicket}`,
        mostPopularService,
        topCombo: null,
        peakBookingTime: null,
        repeatCustomers: null,
      },
    };
  }

  async seedDefaultServices(salonId: string): Promise<SalonService[]> {
    const serviceRepo = this.dataSource.getRepository(Service);
    const salonServiceRepo = this.dataSource.getRepository(SalonService);

    const defaultCatalog = [
      { name: "Haircut & Styling", category: "Hair", price: 250, durationMinutes: 30 },
      { name: "Beard Grooming & Shape", category: "Shave", price: 150, durationMinutes: 20 },
      { name: "Hair Wash & Conditioning", category: "Hair", price: 200, durationMinutes: 20 },
      { name: "Head Massage & Spa", category: "Spa", price: 350, durationMinutes: 25 },
      { name: "Facial & Skin Cleanup", category: "Facial", price: 500, durationMinutes: 40 },
    ];

    const seeded: SalonService[] = [];
    for (const item of defaultCatalog) {
      let svc = await serviceRepo.findOne({ where: { name: item.name } });
      if (!svc) {
        svc = await serviceRepo.save(
          serviceRepo.create({
            name: item.name,
            category: item.category,
            target_gender: "UNISEX",
          }),
        );
      }

      let existingSs = await salonServiceRepo.findOne({
        where: { salon_id: salonId, service_id: svc.id },
      });
      if (!existingSs) {
        existingSs = await salonServiceRepo.save(
          salonServiceRepo.create({
            salon_id: salonId,
            service_id: svc.id,
            price: item.price,
            duration_minutes: item.durationMinutes,
            is_available: true,
          }),
        );
      }
      existingSs.service = svc;
      seeded.push(existingSs);
    }
    return seeded;
  }

  async getServices(salonId?: string) {
    const targetSalonId = await this.resolveSalonId(salonId);
    try {
      let list = await this.dataSource.getRepository(SalonService).find({
        where: { salon_id: targetSalonId },
        relations: ["service"],
      });

      if (list.length === 0 && targetSalonId) {
        list = await this.seedDefaultServices(targetSalonId);
      }

      return list.map((ss) => ({
        id: ss.id,
        name: ss.service?.name || "Salon Service",
        category: ss.service?.category || "Hair",
        price: parseFloat(ss.price.toString()),
        durationMinutes: ss.duration_minutes,
        isAvailable: ss.is_available,
      }));
    } catch (_) {
      return [];
    }
  }

  async addService(
    dto: {
      name: string;
      category?: string;
      price: number;
      durationMinutes: number;
    },
    salonId?: string,
  ) {
    const targetSalonId = await this.resolveSalonId(salonId);
    const serviceRepo = this.dataSource.getRepository(Service);
    const salonServiceRepo = this.dataSource.getRepository(SalonService);

    let service = await serviceRepo.findOne({ where: { name: dto.name } });
    if (!service) {
      service = await serviceRepo.save(
        serviceRepo.create({
          name: dto.name,
          category: dto.category || "Hair",
        }),
      );
    }

    const salonService = await salonServiceRepo.save(
      salonServiceRepo.create({
        salon_id: targetSalonId,
        service_id: service.id,
        price: dto.price,
        duration_minutes: dto.durationMinutes,
        is_available: true,
      }),
    );

    return {
      id: salonService.id,
      name: service.name,
      category: service.category,
      price: parseFloat(salonService.price.toString()),
      durationMinutes: salonService.duration_minutes,
      isAvailable: salonService.is_available,
    };
  }

  async updateService(
    id: string,
    dto: {
      name?: string;
      category?: string;
      price?: number;
      durationMinutes?: number;
      isAvailable?: boolean;
    },
    salonId?: string,
  ) {
    const salonServiceRepo = this.dataSource.getRepository(SalonService);
    const serviceRepo = this.dataSource.getRepository(Service);
    const salonService = await salonServiceRepo.findOne({
      where: salonId ? { id, salon_id: salonId } : { id },
      relations: ["service"],
    });
    if (!salonService) {
      throw new NotFoundException(`Salon service with ID ${id} not found`);
    }

    if (dto.price !== undefined) salonService.price = dto.price;
    if (dto.durationMinutes !== undefined)
      salonService.duration_minutes = dto.durationMinutes;
    if (dto.isAvailable !== undefined)
      salonService.is_available = dto.isAvailable;
    const savedSalonService = await salonServiceRepo.save(salonService);

    if (salonService.service && (dto.name !== undefined || dto.category !== undefined)) {
      const replacement = await serviceRepo.save(serviceRepo.create({
        name: dto.name ?? salonService.service.name,
        category: dto.category ?? salonService.service.category,
        target_gender: salonService.service.target_gender,
        description: salonService.service.description,
      }));
      salonService.service_id = replacement.id;
      salonService.service = replacement;
      await salonServiceRepo.save(salonService);
    }

    return {
      id: savedSalonService.id,
      name: salonService.service?.name || "",
      category: salonService.service?.category || "",
      price: parseFloat(savedSalonService.price.toString()),
      durationMinutes: savedSalonService.duration_minutes,
      isAvailable: savedSalonService.is_available,
    };
  }

  async getCombos(salonId?: string) {
    const targetSalonId = await this.resolveSalonId(salonId);
    const comboRepo = this.dataSource.getRepository(Combo);
    const list = await comboRepo.find({ where: { salon_id: targetSalonId } });

    return list.map((c) => {
      const price = parseFloat(c.price.toString());
      const origPrice = c.original_price
        ? parseFloat(c.original_price.toString())
        : Math.round(price * 1.25);
      return {
        id: c.id,
        name: c.name,
        description: c.description || "",
        price,
        originalPrice: origPrice,
        original_price: origPrice,
        discountTag: c.is_bestseller ? "BESTSELLER" : "COMBO OFFER",
        durationMinutes: c.duration_minutes,
      };
    });
  }

  async addCombo(
    dto: {
      name: string;
      description?: string;
      price: number;
      originalPrice?: number;
      original_price?: number;
      discountTag?: string;
      durationMinutes?: number;
    },
    salonId?: string,
  ) {
    const targetSalonId = await this.resolveSalonId(salonId);
    const comboRepo = this.dataSource.getRepository(Combo);
    const origPrice = dto.originalPrice || dto.original_price || Math.round(dto.price * 1.25);

    const combo = await comboRepo.save(
      comboRepo.create({
        salon_id: targetSalonId,
        name: dto.name,
        description: dto.description || "",
        price: dto.price,
        original_price: origPrice,
        duration_minutes: dto.durationMinutes || 45,
        is_bestseller:
          (dto.discountTag || "").toUpperCase().includes("BEST") ||
          (dto.discountTag || "").toUpperCase().includes("SAVE"),
      }),
    );

    const serviceRepo = this.dataSource.getRepository(Service);
    const salonServiceRepo = this.dataSource.getRepository(SalonService);
    const svc = await serviceRepo.save(
      serviceRepo.create({
        name: combo.name,
        category: "Combo",
        target_gender: "UNISEX",
        description: combo.description || "",
      }),
    );
    await salonServiceRepo.save(
      salonServiceRepo.create({
        id: combo.id,
        salon_id: targetSalonId,
        service_id: svc.id,
        price: combo.price,
        duration_minutes: combo.duration_minutes,
        is_available: true,
      }),
    );

    return {
      id: combo.id,
      name: combo.name,
      description: combo.description,
      price: parseFloat(combo.price.toString()),
      discountTag: dto.discountTag || "SPECIAL OFFER",
    };
  }
}

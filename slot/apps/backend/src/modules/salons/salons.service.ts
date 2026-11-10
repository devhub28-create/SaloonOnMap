import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { DataSource, LessThanOrEqual, MoreThanOrEqual, Repository } from "typeorm";
import {
  Salon,
  SalonService,
  Combo,
  Booking,
  BookingStatus,
  Seat,
  Staff,
  Offer,
  BookingHold,
  HoldStatus,
  Review,
} from "../../entities";

function getDistanceKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const R = 6371;
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 10) / 10;
}

const AREA_COORDINATES: Record<
  string,
  { lat: number; lng: number; label: string }
> = {
  vijaynagar: { lat: 22.7533, lng: 75.8937, label: "Vijay Nagar, Indore" },
  palasia: { lat: 22.7244, lng: 75.8839, label: "Palasia, Indore" },
  bhawarkua: { lat: 22.6916, lng: 75.8672, label: "Bhawarkua, Indore" },
  saketnagar: { lat: 22.7196, lng: 75.8942, label: "Saket Nagar, Indore" },
  abroad: { lat: 22.73, lng: 75.89, label: "AB Road, Indore" },
  indore: { lat: 22.7196, lng: 75.8577, label: "Indore, Madhya Pradesh" },
  indiranagar: { lat: 12.9784, lng: 77.6408, label: "Indiranagar, Bengaluru" },
  koramangala: { lat: 12.9352, lng: 77.6245, label: "Koramangala, Bengaluru" },
  hsr: { lat: 12.9121, lng: 77.6446, label: "HSR Layout, Bengaluru" },
  whitefield: { lat: 12.9698, lng: 77.75, label: "Whitefield, Bengaluru" },
  mgroad: { lat: 12.9756, lng: 77.6066, label: "MG Road, Bengaluru" },
};

export const DEFAULT_SALON_COVER_IMAGE =
  "https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&q=80&w=1000";

export function ensureSalonCover<T extends { cover_image?: string | null }>(
  salon: T,
): T {
  if (!salon.cover_image || salon.cover_image.trim().length === 0) {
    salon.cover_image = DEFAULT_SALON_COVER_IMAGE;
  }
  return salon;
}

export function formatComboWithCutPrice(c: Combo): any {
  const price = parseFloat(c.price?.toString() || "0");
  let origPrice = c.original_price
    ? parseFloat(c.original_price.toString())
    : null;
  if (!origPrice || origPrice <= price) {
    origPrice = Math.round(price * 1.25);
  }
  return {
    ...c,
    price,
    original_price: origPrice,
    originalPrice: origPrice,
  };
}

@Injectable()
export class SalonsService {
  constructor(
    @InjectRepository(Salon)
    private readonly salonRepository: Repository<Salon>,
    @InjectRepository(SalonService)
    private readonly salonServiceRepository: Repository<SalonService>,
    @InjectRepository(Combo)
    private readonly comboRepository: Repository<Combo>,
    @InjectRepository(Booking)
    private readonly bookingRepository: Repository<Booking>,
    @InjectRepository(Seat)
    private readonly seatRepository: Repository<Seat>,
    @InjectRepository(Staff)
    private readonly staffRepository: Repository<Staff>,
    @InjectRepository(Offer)
    private readonly offerRepository: Repository<Offer>,
    @InjectRepository(BookingHold)
    private readonly holdRepository: Repository<BookingHold>,
    private readonly dataSource: DataSource,
  ) {}

  async getActiveOffers() {
    const now = new Date();
    return this.offerRepository.find({
      where: {
        is_active: true,
        valid_from: LessThanOrEqual(now),
        valid_until: MoreThanOrEqual(now),
      },
      relations: ["salon"],
      order: { valid_until: "ASC" },
    });
  }

  private resolveUserLocation(
    userLat?: number,
    userLng?: number,
    areaName?: string,
  ) {
    const areaKey = (areaName || "").toLowerCase().replace(/[^a-z]/g, "");
    let refLat = userLat ? Number(userLat) : undefined;
    let refLng = userLng ? Number(userLng) : undefined;
    let label = areaName || "Vijay Nagar, Indore";

    if (AREA_COORDINATES[areaKey]) {
      refLat = AREA_COORDINATES[areaKey].lat;
      refLng = AREA_COORDINATES[areaKey].lng;
      label = AREA_COORDINATES[areaKey].label;
    } else if (refLat && refLng) {
      label = areaName || "Detected Location";
    } else {
      refLat = 22.7533;
      refLng = 75.8937;
      label = areaName || "Vijay Nagar, Indore";
    }

    return { lat: refLat, lng: refLng, label };
  }

  async getCustomerHome(
    gender: string = "MEN",
    customerId?: string,
    userLat?: number,
    userLng?: number,
    areaName?: string,
  ) {
    const targetGender = gender.toUpperCase() === "WOMEN" ? "WOMEN" : "MEN";
    const query = this.salonRepository
      .createQueryBuilder("s")
      .where("s.is_active = true");
    query.andWhere("(s.target_gender = :g OR s.target_gender = 'UNISEX')", {
      g: targetGender,
    });
    const allSalons = await query.getMany();

    const refCoords = this.resolveUserLocation(userLat, userLng, areaName);

    const salonsWithDistance = allSalons.map((salon) => {
      ensureSalonCover(salon);
      const sLat = Number(salon.latitude) || 12.9784;
      const sLng = Number(salon.longitude) || 77.6408;
      const dist = getDistanceKm(refCoords.lat, refCoords.lng, sLat, sLng);
      return {
        ...salon,
        distanceKm: dist,
        formattedDistance: `${dist} km`,
      };
    });

    salonsWithDistance.sort((a, b) => {
      const aMatch = a.target_gender === targetGender ? 0 : 1;
      const bMatch = b.target_gender === targetGender ? 0 : 1;
      if (aMatch !== bMatch) return aMatch - bMatch;
      return a.distanceKm - b.distanceKm;
    });

    const featuredSalon = salonsWithDistance[0] || null;

    let services: SalonService[] = [];
    let combos: Combo[] = [];
    if (featuredSalon) {
      const allServices = await this.salonServiceRepository.find({
        where: { salon_id: featuredSalon.id, is_available: true },
        relations: ["service", "salon"],
        take: 12,
      });
      const rawCombos = await this.comboRepository.find({
        where: { salon_id: featuredSalon.id },
        take: 5,
      });
      combos = rawCombos.map(formatComboWithCutPrice);
      const comboIds = new Set(combos.map((c) => c.id));
      services = allServices
        .filter((s) => !comboIds.has(s.id) && s.service?.category !== "Combo")
        .slice(0, 6);
    }

    let upcomingBooking = null;
    if (customerId) {
      upcomingBooking = await this.bookingRepository.findOne({
        where: { customer_id: customerId, status: BookingStatus.CONFIRMED },
        relations: ["salon", "seat", "staff", "services"],
        order: { start_at: "ASC" },
      });
    }

    return {
      gender,
      userLocation: {
        area: refCoords.label,
        latitude: refCoords.lat,
        longitude: refCoords.lng,
      },
      heroBanner:
        gender === "WOMEN"
          ? {
              title: "A little glow-up?",
              subtitle: "Hair spa + styling from ₹1,199",
              cta: "Book now",
            }
          : {
              title: "Sharp cut. Zero wait.",
              subtitle: "20% off first chair booking",
              cta: "Book now",
            },
      popularServices: services,
      powerCombo: combos[0] || null,
      upcomingBooking: upcomingBooking
        ? {
            id: upcomingBooking.id,
            referenceCode: upcomingBooking.reference_code,
            salonName: upcomingBooking.salon.name,
            dateStr: "Today",
            timeStr: "4:15 PM",
            servicesSummary: "Haircut + Beard Sculpt",
          }
        : null,
      recommendedSalons: salonsWithDistance,
    };
  }

  async getAllSalons(
    search?: string,
    gender?: string,
    userLat?: number,
    userLng?: number,
    areaName?: string,
  ) {
    const query = this.salonRepository
      .createQueryBuilder("s")
      .where("s.is_active = true");
    if (search) {
      query.andWhere(
        "(s.name ILIKE :search OR s.area ILIKE :search OR s.city ILIKE :search)",
        { search: `%${search}%` },
      );
    }
    if (gender) {
      const g = gender.toUpperCase();
      query.andWhere("(s.target_gender = :g OR s.target_gender = 'UNISEX')", {
        g,
      });
    }

    const allSalons = await query.getMany();

    const refCoords = this.resolveUserLocation(userLat, userLng, areaName);

    const salonsWithDistance = allSalons.map((salon) => {
      ensureSalonCover(salon);
      const sLat = Number(salon.latitude) || 12.9784;
      const sLng = Number(salon.longitude) || 77.6408;
      const dist = getDistanceKm(refCoords.lat, refCoords.lng, sLat, sLng);
      return {
        ...salon,
        distanceKm: dist,
        formattedDistance: `${dist} km`,
      };
    });

    salonsWithDistance.sort((a, b) => a.distanceKm - b.distanceKm);

    return salonsWithDistance;
  }

  async getSalonById(id: string) {
    const salon = await this.salonRepository.findOne({ where: { id } });
    if (!salon) {
      throw new NotFoundException(`Salon with ID ${id} not found`);
    }
    ensureSalonCover(salon);
    const allServices = await this.salonServiceRepository.find({
      where: { salon_id: id, is_available: true },
      relations: ["service"],
    });
    const rawCombos = await this.comboRepository.find({ where: { salon_id: id } });
    const combos = rawCombos.map(formatComboWithCutPrice);
    const comboIds = new Set(combos.map((c) => c.id));
    const services = allServices.filter(
      (s) => !comboIds.has(s.id) && s.service?.category !== "Combo",
    );

    let reviews: Review[] = [];
    try {
      reviews = await this.dataSource.getRepository(Review).find({
        where: { salon_id: id },
        order: { created_at: "DESC" },
        take: 10,
      });
    } catch (_) {}

    return {
      salon,
      services,
      combos,
      reviews,
    };
  }

  async getAvailableSlots(salonId: string, dateStr?: string, durationMinutes?: number) {
    const isValidUuid = (id?: string) =>
      typeof id === "string" &&
      /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(
        id,
      );

    if (!isValidUuid(salonId)) {
      throw new NotFoundException(`Salon with ID ${salonId} not found`);
    }
    const salon = await this.salonRepository.findOne({
      where: { id: salonId, is_active: true },
    });
    if (!salon)
      throw new NotFoundException(`Salon with ID ${salonId} not found`);
    const targetSalonId = salon.id;

    const seats = await this.seatRepository.find({
      where: { salon_id: targetSalonId, is_active: true },
      order: { seat_number: "ASC" },
    });

    const staff = await this.staffRepository.find({
      where: { salon_id: targetSalonId },
      order: { created_at: "ASC" },
    });

    const todayInSalon = new Intl.DateTimeFormat('en-CA', {
      timeZone: salon.timezone,
      year: 'numeric', month: '2-digit', day: '2-digit',
    }).format(new Date());
    const selectedDate = /^\d{4}-\d{2}-\d{2}$/.test(dateStr || "") ? dateStr! : todayInSalon;
    const dayStart = this.zonedDateTimeToUtc(selectedDate, '00:00', salon.timezone);
    const dayEnd = this.zonedDateTimeToUtc(selectedDate, '23:59', salon.timezone);
    if (isNaN(dayStart.getTime()) || dayStart.getTime() > Date.now() + 90 * 86400000) {
      throw new NotFoundException('Requested availability date is invalid or outside the 90-day booking window.');
    }
    const bookings = await this.bookingRepository
      .createQueryBuilder("booking")
      .where("booking.salon_id = :salonId", { salonId: targetSalonId })
      .andWhere("booking.status IN ('CONFIRMED', 'WAITING', 'IN_SERVICE')")
      .andWhere("booking.start_at BETWEEN :dayStart AND :dayEnd", {
        dayStart,
        dayEnd,
      })
      .getMany();
    const holds = await this.holdRepository
      .createQueryBuilder('hold')
      .where('hold.salon_id = :salonId', { salonId: targetSalonId })
      .andWhere('hold.status = :status', { status: HoldStatus.ACTIVE })
      .andWhere('hold.expires_at > NOW()')
      .andWhere('hold.start_at < :dayEnd AND hold.end_at > :dayStart', { dayStart, dayEnd })
      .getMany();
    const [openHour, openMinute] = salon.opening_time.split(":").map(Number);
    const [closeHour, closeMinute] = salon.closing_time.split(":").map(Number);
    const cursor = this.zonedDateTimeToUtc(selectedDate, `${openHour.toString().padStart(2, '0')}:${openMinute.toString().padStart(2, '0')}`, salon.timezone);
    const closing = this.zonedDateTimeToUtc(selectedDate, `${closeHour.toString().padStart(2, '0')}:${closeMinute.toString().padStart(2, '0')}`, salon.timezone);
    const requiredDuration = Math.max(30, durationMinutes || 30);
    const timeSlots: Array<{
      time: string;
      available: boolean;
      availableSeatIds: string[];
      occupiedSeatIds: string[];
      label?: string;
    }> = [];
    while (cursor < closing) {
      const slotEnd = new Date(cursor.getTime() + requiredDuration * 60 * 1000);
      const isPast = cursor.getTime() <= Date.now();
      const exceedsClosing = slotEnd > closing;
      const occupiedSeatIds = new Set(
        [...bookings, ...holds]
          .filter(
            (booking) => booking.start_at < slotEnd && booking.end_at > cursor,
          )
          .map((booking) => booking.seat_id),
      );
      const availableSeatIds = (isPast || exceedsClosing)
        ? []
        : seats.filter((seat) => !occupiedSeatIds.has(seat.id)).map((seat) => seat.id);
      const time = new Intl.DateTimeFormat('en-US', {
        timeZone: salon.timezone, hour: '2-digit', minute: '2-digit', hour12: true,
      }).format(cursor);
      const available = availableSeatIds.length > 0;
      timeSlots.push({
        time,
        available,
        availableSeatIds,
        occupiedSeatIds: isPast ? seats.map((s) => s.id) : Array.from(occupiedSeatIds),
        ...(!available ? { label: isPast ? "Full" : (occupiedSeatIds.size >= seats.length ? "Occupied" : "Full") } : {}),
      });
      cursor.setMinutes(cursor.getMinutes() + 30);
    }

    return {
      date: selectedDate,
      timeSlots,
      seats: seats.map((s) => ({ id: s.id, label: s.label, status: s.status })),
      staff:
        staff.length > 0
          ? staff.map((st) => ({
              id: st.id,
              name: st.name,
              role: st.role_title,
              status: st.status,
            }))
          : [],
    };
  }

  private zonedDateTimeToUtc(date: string, time: string, timeZone: string): Date {
    const [year, month, day] = date.split('-').map(Number);
    const [hour, minute] = time.split(':').map(Number);
    const target = Date.UTC(year, month - 1, day, hour, minute);
    let guess = target;
    for (let i = 0; i < 2; i++) {
      const parts = new Intl.DateTimeFormat('en-US', {
        timeZone, year: 'numeric', month: '2-digit', day: '2-digit',
        hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
      }).formatToParts(new Date(guess));
      const values = Object.fromEntries(parts.map((part) => [part.type, part.value]));
      const observed = Date.UTC(Number(values.year), Number(values.month) - 1, Number(values.day), Number(values.hour), Number(values.minute));
      guess += target - observed;
    }
    return new Date(guess);
  }
}

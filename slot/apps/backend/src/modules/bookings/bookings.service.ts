import {
  Injectable,
  ConflictException,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { DataSource } from "typeorm";
import {
  Booking,
  BookingStatus,
  BookingHold,
  HoldStatus,
  Seat,
  SeatStatus,
  BookingService as BookingServiceEntity,
  BookingStatusHistory,
  SalonService,
  User,
  Combo,
  Service,
} from "../../entities";
import { EventsGateway } from "../events/events.gateway";
import { BookingStateMachine } from "./booking-state-machine";
import { normalizePhoneNumber } from "../auth/otp-provider";
import { BookingHoldsService } from "../booking-holds/booking-holds.service";
import { randomUUID } from "crypto";
import { ArrayMaxSize, ArrayMinSize, IsArray, IsOptional, IsPhoneNumber, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

const isValidUuid = (id?: string) =>
  typeof id === "string" &&
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(
    id,
  );

export class ConfirmBookingDto {
  @IsUUID()
  holdId: string;
  @IsOptional()
  @IsUUID()
  customerId: string;
  @IsOptional()
  @IsString()
  @MaxLength(128)
  idempotencyKey?: string;
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
  @IsOptional()
  @IsString()
  paymentStatus?: string;
  @IsOptional()
  @IsArray()
  @ArrayMaxSize(20)
  @IsUUID('4', { each: true })
  serviceIds?: string[];
}

export class WalkInBookingDto {
  @IsUUID()
  salonId: string;
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  customerName: string;
  @IsOptional()
  @IsString()
  customerPhone?: string;
  @IsOptional()
  @IsUUID()
  seatId?: string;
  @IsOptional()
  @IsUUID()
  staffId?: string;
  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  serviceIds?: string[];
  @IsOptional()
  totalPrice?: number;
  @IsOptional()
  totalDuration?: number;
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}

@Injectable()
export class BookingsService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly eventsGateway: EventsGateway,
    private readonly bookingHoldsService: BookingHoldsService,
  ) {}

  async confirmBooking(dto: ConfirmBookingDto) {
    if (dto.idempotencyKey) {
      const existing = await this.dataSource.getRepository(Booking).findOne({
        where: { idempotency_key: dto.idempotencyKey },
        relations: ["salon", "seat", "staff", "services"],
      });
      if (existing) {
        if (existing.customer_id !== dto.customerId) {
          throw new ConflictException("Idempotency key is already in use.");
        }
        return this.formatBookingResponse(existing);
      }
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      let hold: BookingHold | null = null;

      if (isValidUuid(dto.holdId)) {
        hold = await queryRunner.manager
          .createQueryBuilder(BookingHold, "h")
          .setLock("pessimistic_write")
          .where("h.id = :holdId", { holdId: dto.holdId })
          .getOne();
      }

      if (!hold) {
        throw new NotFoundException(
          "No active booking hold found for confirmation.",
        );
      }

      if (hold.customer_id !== dto.customerId) {
        throw new BadRequestException(
          "This booking hold belongs to another customer.",
        );
      }
      if (
        hold.status !== HoldStatus.ACTIVE ||
        hold.expires_at.getTime() <= Date.now()
      ) {
        throw new ConflictException(
          "This booking hold has expired. Select the slot again.",
        );
      }

      let seat = await queryRunner.manager
        .createQueryBuilder(Seat, "s")
        .setLock("pessimistic_write")
        .where("s.id = :seatId", { seatId: hold.seat_id })
        .getOne();

      if (!seat) {
        throw new NotFoundException(`Seat with ID ${hold.seat_id} not found`);
      }

      const refCode = `#MM${randomUUID().replace(/-/g, "").slice(0, 12).toUpperCase()}`;

      const customerId = isValidUuid(dto.customerId)
        ? dto.customerId
        : hold.customer_id;
      const staffId = isValidUuid(hold.staff_id) ? hold.staff_id : undefined;

      const booking = queryRunner.manager.create(Booking, {
        reference_code: refCode,
        customer_id: customerId,
        salon_id: hold.salon_id,
        seat_id: hold.seat_id,
        staff_id: staffId,
        hold_id: hold.id,
        idempotency_key: dto.idempotencyKey,
        start_at: hold.start_at,
        end_at: hold.end_at,
        status: BookingStatus.CONFIRMED,
        payment_status: "PAY_AT_SALON_PENDING",
        total_amount: hold.total_price,
        notes: dto.notes,
      });

      const savedBooking = await queryRunner.manager.save(Booking, booking);

      const requestedServiceIds = hold.service_ids || [];
      if (requestedServiceIds.length === 0) {
        throw new BadRequestException(
          "At least one valid salon service is required.",
        );
      }
      const validServices = await this.resolveSalonServicesAndCombos(
        queryRunner.manager,
        hold.salon_id,
        requestedServiceIds,
      );
      for (const validService of validServices) {
        const bookingService = queryRunner.manager.create(
          BookingServiceEntity,
          {
            booking_id: savedBooking.id,
            salon_service_id: validService.id,
            service_name: validService.service?.name || "",
            price: validService.price,
            duration_minutes: validService.duration_minutes,
          },
        );
        await queryRunner.manager.save(BookingServiceEntity, bookingService);
      }

      const statusHistory = queryRunner.manager.create(BookingStatusHistory, {
        booking_id: savedBooking.id,
        new_status: BookingStatus.CONFIRMED,
        reason: "Initial confirmation",
      });
      await queryRunner.manager.save(BookingStatusHistory, statusHistory);

      hold.status = HoldStatus.CONVERTED;
      await queryRunner.manager.save(BookingHold, hold);

      await queryRunner.commitTransaction();

      const fullBooking = await this.dataSource.getRepository(Booking).findOne({
        where: { id: savedBooking.id },
        relations: ["salon", "seat", "staff", "services", "customer"],
      });

      this.eventsGateway.notifyBookingCreated(hold.salon_id, fullBooking);

      return this.formatBookingResponse(fullBooking);
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async updateBookingStatus(
    bookingId: string,
    targetStatus: BookingStatus,
    actorId?: string,
    reason?: string,
    salonId?: string,
  ) {
    let booking: Booking | null = null;

    if (isValidUuid(bookingId)) {
      booking = await this.dataSource.getRepository(Booking).findOne({
        where: salonId
          ? { id: bookingId, salon_id: salonId }
          : { id: bookingId },
        relations: ["seat"],
      });
    }

    if (!booking) {
      booking = await this.dataSource.getRepository(Booking).findOne({
        where: salonId
          ? { reference_code: bookingId, salon_id: salonId }
          : { reference_code: bookingId },
        relations: ["seat"],
      });
    }

    if (!booking) {
      throw new NotFoundException(`Booking with ID ${bookingId} not found`);
    }

    BookingStateMachine.validateTransition(booking.status, targetStatus);

    const oldStatus = booking.status;
    booking.status = targetStatus;
    const updated = await this.dataSource.getRepository(Booking).save(booking);

    // Save Status History
    await this.dataSource.getRepository(BookingStatusHistory).save({
      booking_id: booking.id,
      previous_status: oldStatus,
      new_status: targetStatus,
      changed_by: actorId,
      reason: reason || "Status updated by partner/admin",
    });

    // Update Seat state if DONE or CANCELLED
    if (booking.seat) {
      if (
        targetStatus === BookingStatus.DONE ||
        targetStatus === BookingStatus.CANCELLED
      ) {
        booking.seat.status = SeatStatus.AVAILABLE;
        await this.dataSource.getRepository(Seat).save(booking.seat);
        this.eventsGateway.notifySeatUpdated(booking.salon_id, booking.seat);
      } else if (targetStatus === BookingStatus.IN_SERVICE) {
        booking.seat.status = SeatStatus.IN_SERVICE;
        await this.dataSource.getRepository(Seat).save(booking.seat);
        this.eventsGateway.notifySeatUpdated(booking.salon_id, booking.seat);
      }
    }

    this.eventsGateway.notifyBookingUpdated(booking.salon_id, updated);

    return updated;
  }

  async cancelCustomerBooking(
    bookingId: string,
    customerId: string,
    reason?: string,
  ) {
    if (!isValidUuid(bookingId))
      throw new NotFoundException(`Booking with ID ${bookingId} not found`);
    const booking = await this.dataSource.getRepository(Booking).findOne({
      where: { id: bookingId, customer_id: customerId },
    });
    if (!booking)
      throw new NotFoundException(`Booking with ID ${bookingId} not found`);
    if (booking.start_at.getTime() - Date.now() < 30 * 60 * 1000) {
      throw new BadRequestException(
        "Bookings cannot be cancelled within 30 minutes of the start time.",
      );
    }
    return this.updateBookingStatus(
      bookingId,
      BookingStatus.CANCELLED,
      customerId,
      reason,
    );
  }

  async createWalkInBooking(dto: WalkInBookingDto) {
    const startAt = new Date(Date.now() + 60 * 1000);

    const hasValidPhone =
      dto.customerPhone &&
      dto.customerPhone.trim().replace(/\D/g, "").length >= 7;
    const phone = hasValidPhone
      ? normalizePhoneNumber(dto.customerPhone!)
      : `+9190${Date.now().toString().slice(-8)}`;

    let customer = await this.dataSource.getRepository(User).findOne({
      where: { phone },
    });
    if (!customer) {
      customer = await this.dataSource.getRepository(User).save(
        this.dataSource.getRepository(User).create({
          phone,
          name: dto.customerName.trim() || "Walk-in Customer",
          role: "CUSTOMER" as any,
        }),
      );
    }
    const customerId = customer.id;

    // 1. Resolve seat: explicit seatId -> available seat -> any active seat -> auto-create default seats
    let seat = isValidUuid(dto.seatId)
      ? await this.dataSource.getRepository(Seat).findOne({
          where: { id: dto.seatId, salon_id: dto.salonId, is_active: true },
        })
      : null;

    if (!seat) {
      seat = await this.dataSource.getRepository(Seat).findOne({
        where: { salon_id: dto.salonId, is_active: true, status: SeatStatus.AVAILABLE },
        order: { seat_number: "ASC" },
      });
    }

    if (!seat) {
      seat = await this.dataSource.getRepository(Seat).findOne({
        where: { salon_id: dto.salonId, is_active: true },
        order: { seat_number: "ASC" },
      });
    }

    if (!seat) {
      const seats: Seat[] = [];
      for (let i = 1; i <= 4; i++) {
        seats.push(
          this.dataSource.getRepository(Seat).create({
            salon_id: dto.salonId,
            seat_number: i,
            label: `Chair ${i}`,
            status: SeatStatus.AVAILABLE,
            is_active: true,
          }),
        );
      }
      const savedSeats = await this.dataSource.getRepository(Seat).save(seats);
      seat = savedSeats[0];
    }

    // 2. Resolve serviceIds: explicit IDs -> available services -> auto-seed default services
    let serviceIds = (dto.serviceIds || []).filter(isValidUuid);
    if (serviceIds.length === 0) {
      let availableSs = await this.dataSource.getRepository(SalonService).findOne({
        where: { salon_id: dto.salonId, is_available: true },
        relations: ["service"],
      });
      if (!availableSs) {
        const serviceRepo = this.dataSource.getRepository(Service);
        const salonServiceRepo = this.dataSource.getRepository(SalonService);
        let defaultSvc = await serviceRepo.findOne({ where: { name: "Haircut & Styling" } });
        if (!defaultSvc) {
          defaultSvc = await serviceRepo.save(
            serviceRepo.create({
              name: "Haircut & Styling",
              category: "Hair",
              target_gender: "UNISEX",
            }),
          );
        }
        availableSs = await salonServiceRepo.save(
          salonServiceRepo.create({
            salon_id: dto.salonId,
            service_id: defaultSvc.id,
            price: 250,
            duration_minutes: 30,
            is_available: true,
          }),
        );
        availableSs.service = defaultSvc;
      }
      if (availableSs) {
        serviceIds = [availableSs.id];
      }
    }

    const hold = await this.bookingHoldsService.createHold({
      customerId,
      salonId: dto.salonId,
      seatId: seat.id,
      staffId: dto.staffId,
      serviceIds,
      startAt: startAt.toISOString(),
      endAt: startAt.toISOString(),
      totalPrice: dto.totalPrice || 0,
      totalDuration: dto.totalDuration || 0,
    });

    const phoneDisplay = hasValidPhone ? ` (${phone})` : "";
    const noteText = dto.notes?.trim() ? ` · Note: ${dto.notes.trim()}` : "";
    const bookingNotes = `Walk-in: ${dto.customerName}${phoneDisplay}${noteText}`.trim();

    const confirmed = await this.confirmBooking({
      holdId: hold.holdId,
      customerId,
      serviceIds,
      notes: bookingNotes,
    });

    // Automatically transition seat to IN_SERVICE for the walk-in customer
    await this.dataSource.getRepository(Seat).update(seat.id, {
      status: SeatStatus.IN_SERVICE,
    });

    return confirmed;
  }

  async getCustomerBookings(customerId?: string, statusFilter?: string) {
    if (!isValidUuid(customerId)) {
      return [];
    }
    const query = this.dataSource
      .getRepository(Booking)
      .createQueryBuilder("b")
      .leftJoinAndSelect("b.salon", "salon")
      .leftJoinAndSelect("b.seat", "seat")
      .leftJoinAndSelect("b.staff", "staff")
      .leftJoinAndSelect("b.services", "services")
      .orderBy("b.start_at", "DESC");

    query.andWhere("b.customer_id = :customerId", { customerId });

    if (statusFilter === "UPCOMING") {
      query.andWhere("b.status IN ('CONFIRMED', 'WAITING')");
    } else if (statusFilter === "COMPLETED") {
      query.andWhere("b.status IN ('DONE')");
    } else if (statusFilter === "CANCELLED") {
      query.andWhere("b.status IN ('CANCELLED')");
    }

    const list = await query.getMany();
    return list.map((b) => this.formatBookingResponse(b));
  }

  async getPartnerBookings(salonId?: string, statusFilter?: string) {
    if (!isValidUuid(salonId)) {
      return [];
    }

    const query = this.dataSource
      .getRepository(Booking)
      .createQueryBuilder("b")
      .leftJoinAndSelect("b.salon", "salon")
      .leftJoinAndSelect("b.seat", "seat")
      .leftJoinAndSelect("b.staff", "staff")
      .leftJoinAndSelect("b.customer", "customer")
      .leftJoinAndSelect("b.services", "services")
      .orderBy("b.start_at", "ASC");

    if (isValidUuid(salonId)) {
      query.andWhere("b.salon_id = :salonId", { salonId });
    }

    if (statusFilter && statusFilter !== "ALL") {
      query.andWhere("b.status = :status", {
        status: statusFilter as BookingStatus,
      });
    }

    const list = await query.getMany();
    return list.map((b) => this.formatBookingResponse(b));
  }

  private formatBookingResponse(booking: Booking) {
    const customerName = booking.notes?.startsWith("Walk-in:")
      ? booking.notes.replace("Walk-in:", "").trim()
      : booking.customer?.name || booking.customer?.phone || "Customer";

    const serviceName =
      booking.services && booking.services.length > 0
        ? booking.services[0].service_name
        : "";

    return {
      id: booking.id,
      referenceCode: booking.reference_code,
      customerName: customerName,
      salonName: booking.salon?.name || "",
      address: booking.salon?.address || "",
      seatLabel: booking.seat?.label || "",
      stylistName: booking.staff?.name || "",
      serviceName: serviceName,
      startAt: booking.start_at,
      endAt: booking.end_at,
      status: booking.status,
      paymentStatus: booking.payment_status,
      totalAmount: booking.total_amount,
      salon: booking.salon
        ? {
            id: booking.salon.id,
            name: booking.salon.name,
            address: booking.salon.address,
          }
        : null,
      seat: booking.seat
        ? { id: booking.seat.id, label: booking.seat.label }
        : null,
      staff: booking.staff
        ? { id: booking.staff.id, name: booking.staff.name }
        : null,
      reference_code: booking.reference_code,
      total_amount: booking.total_amount,
      total_price: booking.total_amount,
      price: booking.total_amount,
    };
  }

  private async resolveSalonServicesAndCombos(
    manager: any,
    salonId: string,
    serviceIds: string[],
  ): Promise<SalonService[]> {
    const validIds = [...new Set((serviceIds || []).filter(isValidUuid))];
    if (validIds.length === 0) {
      throw new BadRequestException("At least one valid service is required.");
    }

    const services = await manager
      .createQueryBuilder(SalonService, "ss")
      .leftJoinAndSelect("ss.service", "service")
      .where("ss.salon_id = :salonId", { salonId })
      .andWhere("ss.id IN (:...validIds)", { validIds })
      .andWhere("ss.is_available = true")
      .getMany();

    const foundIds = new Set(services.map((s: SalonService) => s.id));
    const missingIds = validIds.filter((id: string) => !foundIds.has(id));

    if (missingIds.length > 0) {
      const combos = await manager
        .createQueryBuilder(Combo, "combo")
        .where("combo.salon_id = :salonId", { salonId })
        .andWhere("combo.id IN (:...missingIds)", { missingIds })
        .getMany();

      const foundComboIds = new Set(combos.map((c: Combo) => c.id));
      const unresolvedIds = missingIds.filter((id: string) => !foundComboIds.has(id));
      if (unresolvedIds.length > 0) {
        throw new BadRequestException(
          "One or more selected services are unavailable at this salon.",
        );
      }

      for (const combo of combos) {
        let existingSs = await manager.findOne(SalonService, {
          where: { id: combo.id },
          relations: ["service"],
        });
        if (!existingSs) {
          const svc = await manager.save(
            manager.create(Service, {
              name: combo.name,
              category: "Combo",
              target_gender: "UNISEX",
              description: combo.description || "",
            }),
          );
          existingSs = await manager.save(
            manager.create(SalonService, {
              id: combo.id,
              salon_id: salonId,
              service_id: svc.id,
              price: combo.price,
              duration_minutes: combo.duration_minutes,
              is_available: true,
            }),
          );
          existingSs.service = svc;
        }
        services.push(existingSs);
      }
    }

    return services;
  }
}

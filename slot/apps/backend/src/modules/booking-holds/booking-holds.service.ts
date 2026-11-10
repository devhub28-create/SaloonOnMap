import {
  Injectable,
  ConflictException,
  NotFoundException,
  BadRequestException,
} from "@nestjs/common";
import { DataSource, LessThan } from "typeorm";
import {
  BookingHold,
  HoldStatus,
  Seat,
  SeatStatus,
  Salon,
  User,
  SalonService,
  Staff,
  Combo,
  Service,
} from "../../entities";
import { ArrayMaxSize, ArrayMinSize, IsArray, IsISO8601, IsNumber, IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateHoldDto {
  @IsOptional()
  @IsUUID()
  customerId: string;
  @IsUUID()
  salonId: string;
  @IsUUID()
  seatId: string;
  @IsOptional()
  @IsUUID()
  staffId?: string;
  @IsArray()
  @ArrayMinSize(1)
  @ArrayMaxSize(20)
  @IsUUID('4', { each: true })
  serviceIds: string[];
  @IsISO8601()
  startAt: string;
  @IsOptional()
  @IsISO8601()
  endAt: string;
  @IsOptional()
  @IsNumber()
  totalPrice: number;
  @IsOptional()
  @IsNumber()
  totalDuration: number;
}

const isValidUuid = (id?: string) =>
  typeof id === "string" &&
  /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/.test(
    id,
  );

@Injectable()
export class BookingHoldsService {
  constructor(private readonly dataSource: DataSource) {}

  async createHold(dto: CreateHoldDto) {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      await queryRunner.manager.update(
        BookingHold,
        { status: HoldStatus.ACTIVE, expires_at: LessThan(new Date()) },
        { status: HoldStatus.EXPIRED },
      );
      // 1. Lock the seat row for atomic concurrency check
      let seat: Seat | null = null;

      if (isValidUuid(dto.seatId)) {
        seat = await queryRunner.manager
          .createQueryBuilder(Seat, "seat")
          .setLock("pessimistic_write")
          .where("seat.id = :seatId", { seatId: dto.seatId })
          .getOne();
      }

      if (seat && seat.is_active) {
        dto.seatId = seat.id;
        dto.salonId = seat.salon_id;
      } else {
        throw new NotFoundException(
          `No seats found for salon ID ${dto.salonId}`,
        );
      }

      let customer: User | null = null;
      if (isValidUuid(dto.customerId)) {
        customer = await queryRunner.manager
          .createQueryBuilder(User, "user")
          .where("user.id = :customerId", { customerId: dto.customerId })
          .getOne();
      }

      if (customer) {
        dto.customerId = customer.id;
      } else {
        throw new NotFoundException(
          `Customer with ID ${dto.customerId} not found`,
        );
      }

      const services = await this.resolveSalonServicesAndCombos(
        queryRunner.manager,
        seat.salon_id,
        dto.serviceIds,
      );
      const serviceIds = services.map((s) => s.id);
      const totalDuration = services.reduce(
        (sum, service) => sum + service.duration_minutes,
        0,
      );
      const totalPrice = services.reduce(
        (sum, service) => sum + Number(service.price),
        0,
      );

      const startAtDate = new Date(dto.startAt);
      if (isNaN(startAtDate.getTime()) || startAtDate.getTime() <= Date.now()) {
        throw new BadRequestException("Booking start time must be in the future.");
      }
      const endAtDate = new Date(
        startAtDate.getTime() + totalDuration * 60 * 1000,
      );

      let staffId: string | undefined;
      if (dto.staffId) {
        if (!isValidUuid(dto.staffId)) {
          throw new BadRequestException("Invalid staff identifier.");
        }
        const staff = await queryRunner.manager.findOne(Staff, {
          where: { id: dto.staffId, salon_id: seat.salon_id },
        });
        if (!staff) {
          throw new BadRequestException(
            "Selected staff member does not belong to this salon.",
          );
        }
        staffId = staff.id;
      }

      // 2. Check for overlapping confirmed bookings or active holds on the same seat
      const overlappingBookings = await queryRunner.manager
        .createQueryBuilder("bookings", "b")
        .where("b.seat_id = :seatId", { seatId: dto.seatId })
        .andWhere("b.status IN ('CONFIRMED', 'WAITING', 'IN_SERVICE')")
        .andWhere("b.start_at < :endAt AND b.end_at > :startAt", {
          startAt: startAtDate,
          endAt: endAtDate,
        })
        .getCount();

      const overlappingHolds = await queryRunner.manager
        .createQueryBuilder(BookingHold, "h")
        .where("h.seat_id = :seatId", { seatId: dto.seatId })
        .andWhere("h.status = :activeStatus", { activeStatus: HoldStatus.ACTIVE })
        .andWhere("h.expires_at > NOW()")
        .andWhere("h.start_at < :endAt AND h.end_at > :startAt", {
          startAt: startAtDate,
          endAt: endAtDate,
        })
        .getCount();

      if (overlappingBookings > 0 || overlappingHolds > 0) {
        throw new ConflictException(
          "Selected seat is already booked or held for another customer. Please select another seat or time slot.",
        );
      }

      // 3. Create active 300-second hold
      const holdSeconds = parseInt(
        process.env.BOOKING_HOLD_SECONDS || "300",
        10,
      );
      const expiresAt = new Date(Date.now() + holdSeconds * 1000);

      const hold = queryRunner.manager.create(BookingHold, {
        customer_id: dto.customerId,
        salon_id: dto.salonId,
        seat_id: dto.seatId,
        staff_id: staffId,
        start_at: startAtDate,
        end_at: endAtDate,
        status: HoldStatus.ACTIVE,
        expires_at: expiresAt,
        total_price: totalPrice,
        total_duration: totalDuration,
        service_ids: serviceIds,
      });

      const savedHold = await queryRunner.manager.save(BookingHold, hold);

      await queryRunner.commitTransaction();

      return {
        holdId: savedHold.id,
        expiresAt: savedHold.expires_at.toISOString(),
        expiresInSeconds: holdSeconds,
        status: savedHold.status,
      };
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
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

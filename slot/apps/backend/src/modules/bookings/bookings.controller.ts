import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Param,
  Query,
  Headers,
  UseGuards,
  Request,
} from "@nestjs/common";
import { ApiTags, ApiOperation } from "@nestjs/swagger";
import {
  BookingsService,
  ConfirmBookingDto,
  WalkInBookingDto,
} from "./bookings.service";
import { BookingStatus } from "../../entities";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { TenantGuard } from "../auth/guards/tenant.guard";
import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';

class UpdateStatusDto {
  @IsEnum(BookingStatus)
  status: BookingStatus;
  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;
}

class CancelBookingDto {
  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;
}

@ApiTags("Bookings")
@Controller()
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post("bookings")
  @UseGuards(JwtAuthGuard)
  @ApiOperation({
    summary: "Confirm booking from active hold with idempotency support",
  })
  async confirmBooking(
    @Body() dto: ConfirmBookingDto,
    @Request() req: any,
    @Headers("idempotency-key") idempotencyHeader?: string,
  ) {
    return this.bookingsService.confirmBooking({
      ...dto,
      customerId: req.user.id,
      idempotencyKey: dto.idempotencyKey || idempotencyHeader,
    });
  }

  @Patch("bookings/:id/status")
  @UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
  @Roles("SALON_OWNER", "SALON_STAFF", "ADMIN")
  @ApiOperation({
    summary:
      "Transition booking status (CONFIRMED -> WAITING -> IN_SERVICE -> DONE)",
  })
  async updateStatus(
    @Param("id") id: string,
    @Body() dto: UpdateStatusDto,
    @Request() req: any,
  ) {
    return this.bookingsService.updateBookingStatus(
      id,
      dto.status,
      req.user.id,
      dto.reason,
      req.tenantSalonId,
    );
  }

  @Patch("bookings/:id/cancel")
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: "Cancel booking" })
  async cancelBooking(
    @Param("id") id: string,
    @Body() dto: CancelBookingDto,
    @Request() req: any,
  ) {
    return this.bookingsService.cancelCustomerBooking(
      id,
      req.user.id,
      dto.reason,
    );
  }

  @Post("partner/walkin")
  @UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
  @Roles("SALON_OWNER", "SALON_STAFF", "ADMIN")
  @ApiOperation({
    summary: "Create walk-in booking respecting seat/staff availability",
  })
  async createWalkIn(@Body() dto: WalkInBookingDto, @Request() req: any) {
    return this.bookingsService.createWalkInBooking({
      ...dto,
      salonId: req.tenantSalonId || dto.salonId,
    });
  }

  @Get("customer/bookings")
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: "Get customer bookings list" })
  async getCustomerBookings(
    @Request() req: any,
    @Query("status") status?: string,
  ) {
    return this.bookingsService.getCustomerBookings(req.user.id, status);
  }

  @Get("partner/bookings")
  @UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
  @Roles("SALON_OWNER", "SALON_STAFF", "ADMIN")
  @ApiOperation({ summary: "Get partner live bookings list" })
  async getPartnerBookings(
    @Request() req: any,
    @Query("salonId") salonId?: string,
    @Query("status") status?: string,
  ) {
    return this.bookingsService.getPartnerBookings(
      req.tenantSalonId || salonId,
      status,
    );
  }
}

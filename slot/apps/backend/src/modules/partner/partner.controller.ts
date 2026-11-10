import {
  BadRequestException,
  Controller,
  Get,
  Post,
  Patch,
  Query,
  Body,
  Param,
  UseGuards,
  Req,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { PartnerService } from "./partner.service";
import {
  BookingsService,
  WalkInBookingDto,
} from "../bookings/bookings.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { TenantGuard } from "../auth/guards/tenant.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { BookingStatus } from "../../entities";
import { IsBoolean, IsEnum, IsInt, IsNumber, IsOptional, IsString, IsUUID, Max, MaxLength, Min, MinLength } from 'class-validator';

class UpdateBookingStatusDto {
  @IsEnum(BookingStatus)
  status: BookingStatus;
  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;
}

class AddServiceDto {
  @IsString() @MinLength(2) @MaxLength(100) name: string;
  @IsOptional() @IsString() @MaxLength(60) category?: string;
  @IsNumber() @Min(0) price: number;
  @IsInt() @Min(5) @Max(480) durationMinutes: number;
  @IsOptional() @IsUUID() salonId?: string;
}

class UpdateServiceDto {
  @IsOptional() @IsString() @MinLength(2) @MaxLength(100) name?: string;
  @IsOptional() @IsString() @MaxLength(60) category?: string;
  @IsOptional() @IsNumber() @Min(0) price?: number;
  @IsOptional() @IsInt() @Min(5) @Max(480) durationMinutes?: number;
  @IsOptional() @IsBoolean() isAvailable?: boolean;
}

class AddComboDto {
  @IsString() @MinLength(2) @MaxLength(100) name: string;
  @IsOptional() @IsString() @MaxLength(500) description?: string;
  @IsNumber() @Min(0) price: number;
  @IsOptional() @IsNumber() @Min(0) originalPrice?: number;
  @IsOptional() @IsNumber() @Min(0) original_price?: number;
  @IsOptional() @IsString() @MaxLength(50) discountTag?: string;
  @IsOptional() @IsInt() @Min(5) @Max(480) durationMinutes?: number;
  @IsOptional() @IsUUID() salonId?: string;
}

class UpdateSalonDto {
  @IsOptional() @IsString() @MinLength(2) @MaxLength(120) name?: string;
  @IsOptional() @IsString() @MinLength(5) @MaxLength(300) address?: string;
  @IsOptional() @IsString() @MaxLength(80) city?: string;
  @IsOptional() @IsString() @MaxLength(80) area?: string;
  @IsOptional() @IsString() @MaxLength(5) openingTime?: string;
  @IsOptional() @IsString() @MaxLength(5) closingTime?: string;
  @IsOptional() @IsString() @MaxLength(80) timezone?: string;
  @IsOptional() @IsString() coverImage?: string;
}

@ApiTags("Partner Dashboard & Reports")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
@Roles("ADMIN", "SUPER_ADMIN", "SALON_OWNER", "SALON_STAFF")
@Controller("partner")
export class PartnerController {
  constructor(
    private readonly partnerService: PartnerService,
    private readonly bookingsService: BookingsService,
  ) {}

  @Get('salon')
  @ApiOperation({ summary: 'Get the authenticated partner salon profile' })
  async getSalon(@Req() req: any) {
    return this.partnerService.getSalon(req.tenantSalonId);
  }

  @Patch('salon')
  @Roles('SALON_OWNER', 'ADMIN')
  @ApiOperation({ summary: 'Update the authenticated partner salon profile' })
  async updateSalon(@Req() req: any, @Body() dto: UpdateSalonDto) {
    return this.partnerService.updateSalon(req.tenantSalonId, dto);
  }

  @Get("dashboard")
  @ApiOperation({ summary: "Get authoritative partner dashboard live metrics" })
  async getDashboard(@Req() req: any, @Query("salonId") salonId?: string) {
    const effectiveSalonId = req.tenantSalonId || salonId;
    return this.partnerService.getDashboard(effectiveSalonId);
  }

  @Get("bookings")
  @ApiOperation({ summary: "Get partner bookings list" })
  async getBookings(
    @Req() req: any,
    @Query("salonId") salonId?: string,
    @Query("status") status?: string,
  ) {
    const effectiveSalonId = req.tenantSalonId || salonId;
    return this.bookingsService.getPartnerBookings(effectiveSalonId, status);
  }

  @Post("walkin")
  @ApiOperation({
    summary: "Create walk-in booking reusing concurrency engine",
  })
  async addWalkIn(@Req() req: any, @Body() dto: WalkInBookingDto) {
    const effectiveSalonId = req.tenantSalonId || dto.salonId;
    if (!effectiveSalonId) {
      throw new BadRequestException(
        "salonId is required to create a walk-in booking.",
      );
    }
    return this.bookingsService.createWalkInBooking({
      ...dto,
      salonId: effectiveSalonId,
    });
  }

  @Patch("bookings/:id/status")
  @ApiOperation({
    summary: "Update booking status (check-in, start, complete, cancel)",
  })
  async updateStatus(
    @Req() req: any,
    @Param("id") id: string,
    @Body() dto: UpdateBookingStatusDto,
  ) {
    return this.bookingsService.updateBookingStatus(
      id,
      dto.status,
      req.user?.id,
      dto.reason,
      req.tenantSalonId,
    );
  }

  @Get("reports")
  @ApiOperation({ summary: "Get partner reports and business insights" })
  async getReports(
    @Req() req: any,
    @Query("period") period?: string,
    @Query("salonId") salonId?: string,
  ) {
    const effectiveSalonId = req.tenantSalonId || salonId;
    return this.partnerService.getReports(period || "Week", effectiveSalonId);
  }

  @Get("services")
  @ApiOperation({ summary: "Get partner salon services" })
  async getServices(@Req() req: any, @Query("salonId") salonId?: string) {
    const effectiveSalonId = req.tenantSalonId || salonId;
    return this.partnerService.getServices(effectiveSalonId);
  }

  @Post("services")
  @ApiOperation({ summary: "Add a new partner salon service" })
  async addService(
    @Req() req: any,
    @Body()
    dto: AddServiceDto,
  ) {
    const effectiveSalonId = req.tenantSalonId || dto.salonId;
    return this.partnerService.addService(dto, effectiveSalonId);
  }

  @Patch("services/:id")
  @ApiOperation({ summary: "Update a partner salon service" })
  async updateService(
    @Req() req: any,
    @Param("id") id: string,
    @Body()
    dto: UpdateServiceDto,
  ) {
    return this.partnerService.updateService(id, dto, req.tenantSalonId);
  }

  @Get("combos")
  @ApiOperation({ summary: "Get partner salon combos" })
  async getCombos(@Req() req: any, @Query("salonId") salonId?: string) {
    const effectiveSalonId = req.tenantSalonId || salonId;
    return this.partnerService.getCombos(effectiveSalonId);
  }

  @Post("combos")
  @ApiOperation({ summary: "Add a new partner salon combo" })
  async addCombo(
    @Req() req: any,
    @Body()
    dto: AddComboDto,
  ) {
    const effectiveSalonId = req.tenantSalonId || dto.salonId;
    return this.partnerService.addCombo(dto, effectiveSalonId);
  }
}

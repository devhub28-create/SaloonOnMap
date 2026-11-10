import {
  Controller,
  Get,
  Patch,
  Put,
  Param,
  Body,
  Query,
  Req,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiOperation } from "@nestjs/swagger";
import { SeatsService } from "./seats.service";
import { SeatStatus } from "../../entities";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { TenantGuard } from "../auth/guards/tenant.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { IsEnum, IsInt, IsOptional, IsUUID, Max, Min } from 'class-validator';

class UpdateSeatStatusDto {
  @IsEnum(SeatStatus)
  status: SeatStatus;
}

class SetSeatCountDto {
  @IsOptional()
  @IsUUID()
  salonId?: string;
  @IsInt()
  @Min(1)
  @Max(100)
  seatCount: number;
}

@ApiTags("Seats")
@Controller()
export class SeatsController {
  constructor(private readonly seatsService: SeatsService) {}

  @Get("partner/seats")
  @UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
  @Roles("SALON_OWNER", "SALON_STAFF", "ADMIN")
  @ApiOperation({ summary: "Get partner live seat management status" })
  async getPartnerSeats(@Req() req: any, @Query("salonId") salonId?: string) {
    return this.seatsService.getSalonSeats(req.tenantSalonId || salonId || "");
  }

  @Put("partner/seats")
  @UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
  @Roles("SALON_OWNER", "ADMIN")
  @ApiOperation({ summary: "Set partner seat capacity" })
  async setSeatCount(@Req() req: any, @Body() dto: SetSeatCountDto) {
    return this.seatsService.setSeatCount(req.tenantSalonId || dto.salonId, dto.seatCount);
  }

  @Patch("partner/seats/:id/status")
  @UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
  @Roles("SALON_OWNER", "SALON_STAFF", "ADMIN")
  @ApiOperation({ summary: "Update physical seat status" })
  async updateSeatStatus(
    @Param("id") seatId: string,
    @Body() dto: UpdateSeatStatusDto,
    @Req() req: any,
  ) {
    return this.seatsService.updateSeatStatus(seatId, dto.status, req.tenantSalonId);
  }
}

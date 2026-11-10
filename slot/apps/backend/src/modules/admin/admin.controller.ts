import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Request,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { AdminService } from "./admin.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { IsBoolean, IsIn, IsOptional, IsString, MaxLength } from 'class-validator';

class ReviewSalonDto {
  @IsIn(['APPROVE', 'REJECT', 'REQUEST_CHANGES'])
  action: "APPROVE" | "REJECT" | "REQUEST_CHANGES";
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

class UpdateUserStatusDto {
  @IsBoolean()
  isActive: boolean;
}

@ApiTags("Admin Panel")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN")
@Controller("admin")
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get("dashboard")
  @Roles(
    "ADMIN",
    "SUPER_ADMIN",
    "OPERATIONS_ADMIN",
    "SUPPORT_ADMIN",
    "MARKETING_ADMIN",
  )
  @ApiOperation({ summary: "Get platform-wide admin overview metrics" })
  async getDashboard() {
    return this.adminService.getDashboard();
  }

  @Get("salons/pending")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN")
  @ApiOperation({ summary: "Get salons pending approval" })
  async getPendingSalons() {
    return this.adminService.getPendingSalons();
  }

  @Post("salons/:id/review")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN")
  @ApiOperation({
    summary:
      "Approve, reject, or request changes for a salon onboarding application",
  })
  async reviewSalon(
    @Param("id") id: string,
    @Body() dto: ReviewSalonDto,
    @Request() req: any,
  ) {
    return this.adminService.reviewSalon(
      id,
      dto.action,
      req.user?.id,
      dto.reason,
    );
  }

  @Get("users")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  @ApiOperation({ summary: "Get all platform users" })
  async getUsers() {
    return this.adminService.getUsers();
  }

  @Patch("users/:id/status")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN")
  @ApiOperation({ summary: "Block, unblock, or change status for a user" })
  async updateUserStatus(
    @Param("id") id: string,
    @Body() dto: UpdateUserStatusDto,
    @Request() req: any,
  ) {
    return this.adminService.updateUserStatus(id, dto.isActive, req.user?.id);
  }

  @Get("bookings")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  @ApiOperation({ summary: "Get recent platform bookings" })
  async getBookings() {
    return this.adminService.getBookings();
  }

  @Get("audit-logs")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  @ApiOperation({ summary: "Get system audit trail logs" })
  async getAuditLogs() {
    return this.adminService.getAuditLogs();
  }
}

import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Request,
  Query,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { AdminService } from "./admin.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import {
  IsBoolean,
  IsDateString,
  IsIn,
  IsInt,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  MinLength,
} from "class-validator";
import { BookingStatus, ReviewModerationStatus } from "../../entities";

class ReviewSalonDto {
  @IsIn(["APPROVE", "REJECT", "REQUEST_CHANGES", "SUSPEND", "RESTORE"])
  action: "APPROVE" | "REJECT" | "REQUEST_CHANGES" | "SUSPEND" | "RESTORE";
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

class UpdateUserStatusDto {
  @IsBoolean()
  isActive: boolean;
  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;
}

class UpdateUserRoleDto {
  @IsIn(["ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN", "MARKETING_ADMIN"])
  role: "ADMIN" | "OPERATIONS_ADMIN" | "SUPPORT_ADMIN" | "MARKETING_ADMIN";
}

class CreateOfferDto {
  @IsString() @MaxLength(40) code: string;
  @IsString() @MaxLength(120) name: string;
  @IsIn(["PERCENTAGE", "FIXED"]) discountType: "PERCENTAGE" | "FIXED";
  @IsNumber() @Min(0) discountValue: number;
  @IsIn(["PLATFORM", "SALON"]) scope: "PLATFORM" | "SALON";
  @IsOptional() @IsString() salonId?: string;
  @IsOptional() @IsNumber() @Min(0) minBookingAmount?: number;
  @IsOptional() @IsNumber() @Min(0) maxDiscountAmount?: number;
  @IsDateString() validFrom: string;
  @IsDateString() validUntil: string;
  @IsOptional() @IsInt() @Min(1) globalUsageLimit?: number;
  @IsOptional() @IsInt() @Min(1) perUserLimit?: number;
}

class UpdateOfferStatusDto {
  @IsBoolean()
  isActive: boolean;
}

class UpdateBookingStatusDto {
  @IsIn(Object.values(BookingStatus))
  status: BookingStatus;

  @IsString()
  @MaxLength(500)
  reason: string;
}

class ModerateReviewDto {
  @IsIn(Object.values(ReviewModerationStatus))
  status: ReviewModerationStatus;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

class SendNotificationCampaignDto {
  @IsIn(["ALL", "CUSTOMERS", "PARTNERS", "USER"])
  audience: "ALL" | "CUSTOMERS" | "PARTNERS" | "USER";

  @IsString()
  @MinLength(2)
  @MaxLength(120)
  title: string;

  @IsString()
  @MinLength(2)
  @MaxLength(500)
  body: string;

  @IsOptional()
  @IsString()
  userId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  deepLink?: string;
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

  @Get("salons")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  @ApiOperation({ summary: "Search all salons and their approval state" })
  async getSalons(
    @Query("search") search?: string,
    @Query("status") status?: string,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
  ) {
    return this.adminService.getSalons({
      search,
      status,
      page: page ? Number(page) : 1,
      limit: limit ? Number(limit) : 25,
    });
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
  @ApiOperation({ summary: "Search and paginate platform users" })
  async getUsers(
    @Query("search") search?: string,
    @Query("role") role?: string,
    @Query("status") status?: string,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
  ) {
    return this.adminService.getUsers({
      search,
      role,
      status,
      page: page ? Number(page) : 1,
      limit: limit ? Number(limit) : 25,
    });
  }

  @Patch("users/:id/status")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN")
  @ApiOperation({ summary: "Block, unblock, or change status for a user" })
  async updateUserStatus(
    @Param("id") id: string,
    @Body() dto: UpdateUserStatusDto,
    @Request() req: any,
  ) {
    return this.adminService.updateUserStatus(
      id,
      dto.isActive,
      req.user?.id,
      req.user?.role,
      dto.reason,
    );
  }

  @Patch("users/:id/role")
  @Roles("SUPER_ADMIN")
  @ApiOperation({ summary: "Assign a scoped administrator role" })
  async updateUserRole(
    @Param("id") id: string,
    @Body() dto: UpdateUserRoleDto,
    @Request() req: any,
  ) {
    return this.adminService.updateUserRole(id, dto.role, req.user?.id);
  }

  @Get("bookings")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  @ApiOperation({ summary: "Get recent platform bookings" })
  async getBookings(
    @Query("search") search?: string,
    @Query("status") status?: string,
    @Query("salonId") salonId?: string,
    @Query("dateFrom") dateFrom?: string,
    @Query("dateTo") dateTo?: string,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
  ) {
    return this.adminService.getBookings({
      search,
      status,
      salonId,
      dateFrom,
      dateTo,
      page: page ? Number(page) : 1,
      limit: limit ? Number(limit) : 25,
    });
  }

  @Patch("bookings/:id/status")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN")
  @ApiOperation({
    summary: "Intervene in a booking using the shared status workflow",
  })
  async updateBookingStatus(
    @Param("id") id: string,
    @Body() dto: UpdateBookingStatusDto,
    @Request() req: any,
  ) {
    return this.adminService.updateBookingStatus(
      id,
      dto.status,
      dto.reason,
      req.user?.id,
      req.user?.role,
    );
  }

  @Get("reviews")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  @ApiOperation({ summary: "Search customer reviews and moderation state" })
  async getReviews(
    @Query("search") search?: string,
    @Query("status") status?: string,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
  ) {
    return this.adminService.getReviews({
      search,
      status,
      page: page ? Number(page) : 1,
      limit: limit ? Number(limit) : 25,
    });
  }

  @Patch("reviews/:id/moderation")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN")
  @ApiOperation({ summary: "Publish, flag, or hide a customer review" })
  async moderateReview(
    @Param("id") id: string,
    @Body() dto: ModerateReviewDto,
    @Request() req: any,
  ) {
    return this.adminService.moderateReview(
      id,
      dto.status,
      dto.reason || "",
      req.user?.id,
      req.user?.role,
    );
  }

  @Get("notification-campaigns")
  @Roles("ADMIN", "SUPER_ADMIN", "MARKETING_ADMIN", "OPERATIONS_ADMIN")
  @ApiOperation({
    summary: "List recent customer and partner notification campaigns",
  })
  async getNotificationCampaigns() {
    return this.adminService.getNotificationCampaigns();
  }

  @Post("notification-campaigns")
  @Roles("ADMIN", "SUPER_ADMIN", "MARKETING_ADMIN", "OPERATIONS_ADMIN")
  @ApiOperation({
    summary: "Send a persisted in-app and push notification campaign",
  })
  async sendNotificationCampaign(
    @Body() dto: SendNotificationCampaignDto,
    @Request() req: any,
  ) {
    return this.adminService.sendNotificationCampaign(
      dto,
      req.user?.id,
      req.user?.role,
    );
  }

  @Get("ai-style/operations")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  @ApiOperation({ summary: "Monitor customer AI Style Studio health and jobs" })
  async getAiStyleOperations() {
    return this.adminService.getAiStyleOperations();
  }

  @Get("analytics")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN")
  @ApiOperation({
    summary: "Get completed-revenue and platform performance analytics",
  })
  async getPlatformAnalytics(@Query("days") days?: string) {
    return this.adminService.getPlatformAnalytics(days ? Number(days) : 30);
  }

  @Get("system-health")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  @ApiOperation({
    summary: "Inspect release, database, migration, and operational health",
  })
  async getSystemHealth() {
    return this.adminService.getSystemHealth();
  }

  @Get("audit-logs")
  @Roles("ADMIN", "SUPER_ADMIN", "OPERATIONS_ADMIN", "SUPPORT_ADMIN")
  @ApiOperation({ summary: "Get system audit trail logs" })
  async getAuditLogs(
    @Query("search") search?: string,
    @Query("action") action?: string,
    @Query("entityType") entityType?: string,
    @Query("page") page?: string,
    @Query("limit") limit?: string,
  ) {
    return this.adminService.getAuditLogs({
      search,
      action,
      entityType,
      page: page ? Number(page) : 1,
      limit: limit ? Number(limit) : 25,
    });
  }

  @Get("offers")
  @Roles("ADMIN", "SUPER_ADMIN", "MARKETING_ADMIN")
  @ApiOperation({ summary: "List customer-facing offers" })
  async getOffers() {
    return this.adminService.getOffers();
  }

  @Post("offers")
  @Roles("ADMIN", "SUPER_ADMIN", "MARKETING_ADMIN")
  @ApiOperation({ summary: "Create a customer-facing offer" })
  async createOffer(@Body() dto: CreateOfferDto, @Request() req: any) {
    return this.adminService.createOffer(dto, req.user?.id, req.user?.role);
  }

  @Patch("offers/:id/status")
  @Roles("ADMIN", "SUPER_ADMIN", "MARKETING_ADMIN")
  @ApiOperation({ summary: "Publish or pause a customer-facing offer" })
  async updateOfferStatus(
    @Param("id") id: string,
    @Body() dto: UpdateOfferStatusDto,
    @Request() req: any,
  ) {
    return this.adminService.updateOfferStatus(
      id,
      dto.isActive,
      req.user?.id,
      req.user?.role,
    );
  }
}

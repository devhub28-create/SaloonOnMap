import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import { ReviewsService, CreateReviewDto } from "./reviews.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { RolesGuard } from "../auth/guards/roles.guard";
import { Roles } from "../auth/decorators/roles.decorator";
import { TenantGuard } from "../auth/guards/tenant.guard";
import { IsUUID, IsInt, Min, Max, IsOptional, IsString, IsArray } from "class-validator";

class CreateReviewPayloadDto {
  @IsUUID()
  bookingId: string;

  @IsInt()
  @Min(1)
  @Max(5)
  rating: number;

  @IsOptional()
  @IsString()
  comment?: string;

  @IsOptional()
  @IsArray()
  tags?: string[];
}

@ApiTags("Reviews")
@Controller()
export class ReviewsController {
  constructor(private readonly reviewsService: ReviewsService) {}

  @Post("reviews")
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Customer leaves a review and rating for a completed visit" })
  async createReview(@Body() dto: CreateReviewPayloadDto, @Request() req: any) {
    return this.reviewsService.createReview(dto, req.user.id);
  }

  @Get("salons/:salonId/reviews")
  @ApiOperation({ summary: "Get public customer reviews for a salon" })
  async getSalonReviews(
    @Param("salonId") salonId: string,
    @Query("limit") limit?: string,
    @Query("offset") offset?: string,
  ) {
    const lim = limit ? parseInt(limit, 10) : 20;
    const off = offset ? parseInt(offset, 10) : 0;
    return this.reviewsService.getSalonReviews(salonId, lim, off);
  }

  @Get("reviews/booking/:bookingId")
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Check if booking has an existing review" })
  async getBookingReview(@Param("bookingId") bookingId: string) {
    return this.reviewsService.getBookingReview(bookingId);
  }

  @Get("partner/reviews")
  @UseGuards(JwtAuthGuard, RolesGuard, TenantGuard)
  @Roles("SALON_OWNER", "SALON_STAFF", "ADMIN")
  @ApiBearerAuth()
  @ApiOperation({ summary: "Get salon customer reviews for partner" })
  async getPartnerReviews(@Request() req: any, @Query("salonId") salonId?: string) {
    const effectiveSalonId = req.tenantSalonId || salonId;
    return this.reviewsService.getPartnerReviews(effectiveSalonId);
  }
}

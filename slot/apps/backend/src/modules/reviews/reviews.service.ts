import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import {
  Review,
  Booking,
  Salon,
  BookingStatus,
  ReviewModerationStatus,
} from "../../entities";

export class CreateReviewDto {
  bookingId: string;
  rating: number; // 1 to 5
  comment?: string;
  tags?: string[];
}

@Injectable()
export class ReviewsService {
  constructor(
    @InjectRepository(Review)
    private readonly reviewRepository: Repository<Review>,
    @InjectRepository(Booking)
    private readonly bookingRepository: Repository<Booking>,
    @InjectRepository(Salon)
    private readonly salonRepository: Repository<Salon>,
  ) {}

  async createReview(
    dto: CreateReviewDto,
    customerId: string,
  ): Promise<Review> {
    const booking = await this.bookingRepository.findOne({
      where: { id: dto.bookingId },
      relations: ["customer", "salon"],
    });

    if (!booking) {
      throw new NotFoundException(`Booking with ID ${dto.bookingId} not found`);
    }

    if (booking.customer_id !== customerId) {
      throw new ForbiddenException("You can only review your own bookings");
    }

    if (booking.status !== BookingStatus.DONE) {
      throw new BadRequestException("You can only review completed bookings");
    }

    const existingReview = await this.reviewRepository.findOne({
      where: { booking_id: dto.bookingId },
    });

    if (existingReview) {
      throw new BadRequestException("This booking has already been reviewed");
    }

    const clampedRating = Math.max(1, Math.min(5, Math.round(dto.rating || 5)));
    const customerName = booking.customer?.name || "Customer";

    const review = this.reviewRepository.create({
      booking_id: booking.id,
      customer_id: customerId,
      salon_id: booking.salon_id,
      rating: clampedRating,
      comment: dto.comment || "",
      tags: dto.tags || [],
      customer_name: customerName,
    });

    const savedReview = await this.reviewRepository.save(review);

    // Recalculate average rating & count for salon
    try {
      await this.recalculateSalonRating(booking.salon_id);
    } catch (_) {}

    return savedReview;
  }

  async getSalonReviews(salonId: string, limit = 20, offset = 0) {
    const [reviews, total] = await this.reviewRepository.findAndCount({
      where: {
        salon_id: salonId,
        moderation_status: ReviewModerationStatus.PUBLISHED,
      },
      order: { created_at: "DESC" },
      take: limit,
      skip: offset,
    });

    const salon = await this.salonRepository.findOne({
      where: { id: salonId },
    });

    return {
      salonId,
      rating: salon?.rating ?? 5.0,
      reviewCount: salon?.review_count ?? total,
      total,
      reviews,
    };
  }

  async getBookingReview(bookingId: string) {
    const review = await this.reviewRepository.findOne({
      where: { booking_id: bookingId },
    });
    return review || null;
  }

  async getPartnerReviews(salonId: string) {
    return this.reviewRepository.find({
      where: {
        salon_id: salonId,
        moderation_status: ReviewModerationStatus.PUBLISHED,
      },
      order: { created_at: "DESC" },
    });
  }

  async recalculateSalonRating(salonId: string) {
    const stats = await this.reviewRepository
      .createQueryBuilder("review")
      .select("AVG(review.rating)", "avgRating")
      .addSelect("COUNT(review.id)", "totalCount")
      .where("review.salon_id = :salonId", { salonId })
      .andWhere("review.moderation_status = :status", {
        status: ReviewModerationStatus.PUBLISHED,
      })
      .getRawOne();
    const count = Number(stats?.totalCount || 0);
    const average = count > 0 ? Number(stats?.avgRating || 0) : 0;
    await this.salonRepository.update(salonId, {
      rating: Math.round(average * 10) / 10,
      review_count: count,
    });
  }
}

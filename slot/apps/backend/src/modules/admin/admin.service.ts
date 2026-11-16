import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { DataSource } from "typeorm";
import {
  Salon,
  User,
  Booking,
  AuditLog,
  SalonApprovalHistory,
  SalonStatus,
  UserRole,
  Offer,
  OfferScope,
  OfferType,
  BookingStatus,
  Review,
  ReviewModerationStatus,
  Notification,
  AiStyleJob,
  AiJobStatus,
  SupportTicket,
  SupportTicketStatus,
  DeviceRegistration,
  SalonUser,
} from "../../entities";
import { BookingsService } from "../bookings/bookings.service";
import { ReviewsService } from "../reviews/reviews.service";
import { NotificationsService } from "../notifications/notifications.service";
import { AiStyleService } from "../ai-style/ai-style.service";

@Injectable()
export class AdminService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly bookingsService: BookingsService,
    private readonly reviewsService: ReviewsService,
    private readonly notificationsService: NotificationsService,
    private readonly aiStyleService: AiStyleService,
  ) {}

  async getDashboard() {
    const totalSalons = await this.dataSource.getRepository(Salon).count();
    const activeSalons = await this.dataSource
      .getRepository(Salon)
      .count({ where: { is_active: true } });
    const pendingApprovals = await this.dataSource
      .getRepository(Salon)
      .count({ where: { approval_status: SalonStatus.PENDING_APPROVAL } });
    const suspendedSalons = await this.dataSource
      .getRepository(Salon)
      .count({ where: { approval_status: SalonStatus.SUSPENDED } });
    const totalUsers = await this.dataSource.getRepository(User).count();
    const totalBookings = await this.dataSource.getRepository(Booking).count();
    const openSupportTickets = await this.dataSource
      .getRepository(SupportTicket)
      .createQueryBuilder("ticket")
      .where("ticket.status IN (:...statuses)", {
        statuses: [
          SupportTicketStatus.OPEN,
          SupportTicketStatus.IN_PROGRESS,
          SupportTicketStatus.WAITING_FOR_USER,
        ],
      })
      .getCount();

    const bookingSummary = await this.dataSource
      .getRepository(Booking)
      .createQueryBuilder("booking")
      .select(
        `COALESCE(SUM(CASE WHEN booking.status = 'DONE' THEN booking.total_amount ELSE 0 END), 0)`,
        "totalRevenue",
      )
      .addSelect(
        `COUNT(*) FILTER (WHERE booking.status = 'CANCELLED')`,
        "cancelledBookings",
      )
      .getRawOne();
    const totalRevenue = Number(bookingSummary?.totalRevenue || 0);
    const cancelledBookings = Number(bookingSummary?.cancelledBookings || 0);
    const monthStart = new Date();
    monthStart.setDate(1);
    monthStart.setHours(0, 0, 0, 0);
    const newUsers = await this.dataSource
      .getRepository(User)
      .createQueryBuilder("user")
      .where("user.created_at >= :monthStart", { monthStart })
      .getCount();

    return {
      overview: {
        totalSalons,
        activeSalons,
        pendingApprovals,
        suspendedSalons,
        totalUsers,
        totalBookings,
        totalRevenue,
        newUsers,
        cancelledBookings,
        openSupportTickets,
      },
      charts: {
        bookingTrend: [totalBookings],
        revenueTrend: [totalRevenue],
      },
    };
  }

  async getPendingSalons() {
    return this.dataSource.getRepository(Salon).find({
      where: { approval_status: SalonStatus.PENDING_APPROVAL },
      order: { created_at: "ASC" },
    });
  }

  async getSalons(options: {
    search?: string;
    status?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Number.isFinite(options.page)
      ? Math.max(1, Math.floor(options.page || 1))
      : 1;
    const limit = Number.isFinite(options.limit)
      ? Math.min(100, Math.max(1, Math.floor(options.limit || 25)))
      : 25;
    const query = this.dataSource
      .getRepository(Salon)
      .createQueryBuilder("salon")
      .orderBy("salon.updated_at", "DESC")
      .skip((page - 1) * limit)
      .take(limit);

    const search = options.search?.trim();
    if (search) {
      query.andWhere(
        `(salon.name ILIKE :search OR salon.city ILIKE :search OR salon.area ILIKE :search OR salon.address ILIKE :search)`,
        { search: `%${search}%` },
      );
    }

    const status = options.status?.trim().toUpperCase();
    if (status && status !== "ALL") {
      if (!Object.values(SalonStatus).includes(status as SalonStatus)) {
        throw new BadRequestException(`Unsupported salon status: ${status}`);
      }
      query.andWhere("salon.approval_status = :status", { status });
    }

    const [items, total] = await query.getManyAndCount();
    return { items, total, page, limit };
  }

  async reviewSalon(
    salonId: string,
    action: "APPROVE" | "REJECT" | "REQUEST_CHANGES" | "SUSPEND" | "RESTORE",
    adminId?: string,
    reason?: string,
  ) {
    const salon = await this.dataSource
      .getRepository(Salon)
      .findOne({ where: { id: salonId } });
    if (!salon) {
      throw new NotFoundException(`Salon with ID ${salonId} not found`);
    }

    const previousStatus =
      salon.approval_status ||
      (salon.is_active ? SalonStatus.ACTIVE : SalonStatus.PENDING_APPROVAL);
    let newStatus = previousStatus;
    if (action === "APPROVE") {
      newStatus = SalonStatus.ACTIVE;
      salon.is_active = true;
    } else if (action === "REJECT") {
      newStatus = SalonStatus.REJECTED;
      salon.is_active = false;
    } else if (action === "REQUEST_CHANGES") {
      newStatus = SalonStatus.CHANGES_REQUESTED;
      salon.is_active = false;
    } else if (action === "SUSPEND") {
      if (!salon.is_active) {
        throw new BadRequestException("Only an active salon can be suspended.");
      }
      newStatus = SalonStatus.SUSPENDED;
      salon.is_active = false;
    } else if (action === "RESTORE") {
      if (previousStatus !== SalonStatus.SUSPENDED) {
        throw new BadRequestException(
          "Only a suspended salon can be restored.",
        );
      }
      newStatus = SalonStatus.ACTIVE;
      salon.is_active = true;
    }
    salon.approval_status = newStatus;

    await this.dataSource.transaction(async (manager) => {
      await manager.getRepository(Salon).save(salon);
      await manager.getRepository(SalonApprovalHistory).save({
        salon_id: salon.id,
        admin_id: adminId,
        action,
        previous_status: previousStatus,
        new_status: newStatus,
        reason: reason || `Admin action: ${action}`,
      });
      await manager.getRepository(AuditLog).save({
        actor_id: adminId,
        actor_role: "ADMIN",
        action: `SALON_${action}`,
        entity_type: "SALON",
        entity_id: salon.id,
        before_value: {
          is_active: previousStatus === SalonStatus.ACTIVE,
          status: previousStatus,
        },
        after_value: { is_active: salon.is_active, status: newStatus },
      });
    });

    const partnerMemberships = await this.dataSource
      .getRepository(SalonUser)
      .find({ where: { salon_id: salon.id } });
    await Promise.all(
      partnerMemberships.map((membership) =>
        this.notificationsService.sendEventNotification(
          membership.user_id,
          "SALON_APPROVAL",
          `Salon application ${newStatus.replaceAll("_", " ").toLowerCase()}`,
          reason?.trim() ||
            `${salon.name} is now ${newStatus.replaceAll("_", " ").toLowerCase()}.`,
          { salonId: salon.id, status: newStatus, action },
        ),
      ),
    );

    return { salon, status: newStatus };
  }

  async getUsers(options: {
    search?: string;
    role?: string;
    status?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Number.isFinite(options.page)
      ? Math.max(1, Math.floor(options.page || 1))
      : 1;
    const limit = Number.isFinite(options.limit)
      ? Math.min(100, Math.max(1, Math.floor(options.limit || 25)))
      : 25;
    const query = this.dataSource
      .getRepository(User)
      .createQueryBuilder("user")
      .orderBy("user.created_at", "DESC")
      .skip((page - 1) * limit)
      .take(limit);
    if (options.search?.trim()) {
      query.andWhere(
        "(user.name ILIKE :search OR user.email ILIKE :search OR user.phone ILIKE :search)",
        { search: `%${options.search.trim()}%` },
      );
    }
    const role = options.role?.trim().toUpperCase();
    if (role && role !== "ALL") {
      if (!Object.values(UserRole).includes(role as UserRole))
        throw new BadRequestException(`Unsupported user role: ${role}`);
      query.andWhere("user.role = :role", { role });
    }
    const status = options.status?.trim().toUpperCase();
    if (status && status !== "ALL") {
      if (!["ACTIVE", "BLOCKED"].includes(status))
        throw new BadRequestException(`Unsupported user status: ${status}`);
      query.andWhere("user.is_active = :active", {
        active: status === "ACTIVE",
      });
    }
    const [users, total] = await query.getManyAndCount();
    const items = users.map(
      ({ id, name, email, phone, role, is_active, created_at }) => ({
        id,
        name,
        email,
        phone,
        role,
        is_active,
        created_at,
      }),
    );
    return { items, total, page, limit };
  }

  async getBookings(options: {
    search?: string;
    status?: string;
    salonId?: string;
    dateFrom?: string;
    dateTo?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Number.isFinite(options.page)
      ? Math.max(1, Math.floor(options.page || 1))
      : 1;
    const limit = Number.isFinite(options.limit)
      ? Math.min(100, Math.max(1, Math.floor(options.limit || 25)))
      : 25;
    const query = this.dataSource
      .getRepository(Booking)
      .createQueryBuilder("booking")
      .leftJoinAndSelect("booking.customer", "customer")
      .leftJoinAndSelect("booking.salon", "salon")
      .leftJoinAndSelect("booking.seat", "seat")
      .leftJoinAndSelect("booking.staff", "staff")
      .leftJoinAndSelect("booking.services", "services")
      .orderBy("booking.start_at", "DESC")
      .skip((page - 1) * limit)
      .take(limit);

    const search = options.search?.trim();
    if (search) {
      query.andWhere(
        `(booking.reference_code ILIKE :search OR customer.name ILIKE :search OR customer.phone ILIKE :search OR salon.name ILIKE :search)`,
        { search: `%${search}%` },
      );
    }
    const status = options.status?.trim().toUpperCase();
    if (status && status !== "ALL") {
      if (!Object.values(BookingStatus).includes(status as BookingStatus)) {
        throw new BadRequestException(`Unsupported booking status: ${status}`);
      }
      query.andWhere("booking.status = :status", { status });
    }
    if (options.salonId?.trim()) {
      query.andWhere("booking.salon_id = :salonId", {
        salonId: options.salonId.trim(),
      });
    }
    if (options.dateFrom) {
      const dateFrom = new Date(options.dateFrom);
      if (Number.isNaN(dateFrom.getTime())) {
        throw new BadRequestException("Invalid booking start date.");
      }
      query.andWhere("booking.start_at >= :dateFrom", { dateFrom });
    }
    if (options.dateTo) {
      const dateTo = new Date(options.dateTo);
      if (Number.isNaN(dateTo.getTime())) {
        throw new BadRequestException("Invalid booking end date.");
      }
      query.andWhere("booking.start_at <= :dateTo", { dateTo });
    }

    const [bookings, total] = await query.getManyAndCount();
    const items = bookings.map((booking) => ({
      id: booking.id,
      referenceCode: booking.reference_code,
      customerName:
        booking.customer?.name || booking.customer?.phone || "Customer",
      salonName: booking.salon?.name || "",
      seatLabel: booking.seat?.label || "",
      stylistName: booking.staff?.name || "",
      serviceName:
        booking.services
          ?.map((service) => service.service_name)
          .filter(Boolean)
          .join(", ") || "",
      startAt: booking.start_at,
      status: booking.status,
      totalAmount: booking.total_amount,
      paymentStatus: booking.payment_status,
      notes: booking.notes,
    }));
    return { items, total, page, limit };
  }

  async updateBookingStatus(
    bookingId: string,
    status: BookingStatus,
    reason: string,
    adminId?: string,
    actorRole?: string,
  ) {
    const normalizedReason = reason?.trim();
    if (!normalizedReason) {
      throw new BadRequestException(
        "A reason is required for admin booking interventions.",
      );
    }
    const current = await this.dataSource.getRepository(Booking).findOne({
      where: { id: bookingId },
    });
    if (!current) throw new NotFoundException("Booking not found.");
    const previousStatus = current.status;
    const updated = await this.bookingsService.updateBookingStatus(
      bookingId,
      status,
      adminId,
      normalizedReason,
    );
    await this.dataSource.getRepository(AuditLog).save({
      actor_id: adminId,
      actor_role: actorRole || "ADMIN",
      action: "BOOKING_STATUS_UPDATE",
      entity_type: "BOOKING",
      entity_id: current.id,
      before_value: { status: previousStatus },
      after_value: { status: updated.status, reason: normalizedReason },
    });
    return updated;
  }

  async updateUserStatus(
    userId: string,
    isActive: boolean,
    adminId?: string,
    actorRole?: string,
    reason?: string,
  ) {
    if (userId === adminId && !isActive) {
      throw new BadRequestException(
        "You cannot block your own administrator account.",
      );
    }
    const user = await this.dataSource
      .getRepository(User)
      .findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }
    if (
      user.role === UserRole.SUPER_ADMIN &&
      actorRole !== UserRole.SUPER_ADMIN
    ) {
      throw new ForbiddenException(
        "Only a super administrator can change another super administrator.",
      );
    }
    const previousActive = user.is_active;
    user.is_active = isActive;
    if (!isActive && previousActive) {
      user.token_version += 1;
    }
    await this.dataSource.getRepository(User).save(user);

    await this.dataSource.getRepository(AuditLog).save({
      actor_id: adminId,
      actor_role: "ADMIN",
      action: isActive ? "USER_ACTIVATE" : "USER_BLOCK",
      entity_type: "USER",
      entity_id: user.id,
      before_value: { is_active: previousActive },
      after_value: {
        is_active: user.is_active,
        reason: reason?.trim() || undefined,
      },
    });

    return { user, is_active: user.is_active };
  }

  async updateUserRole(
    userId: string,
    role: "ADMIN" | "OPERATIONS_ADMIN" | "SUPPORT_ADMIN" | "MARKETING_ADMIN",
    adminId?: string,
  ) {
    if (userId === adminId) {
      throw new BadRequestException(
        "You cannot change your own administrator role.",
      );
    }
    const user = await this.dataSource.getRepository(User).findOne({
      where: { id: userId },
    });
    if (!user) throw new NotFoundException("User not found.");
    if (user.role === UserRole.SUPER_ADMIN) {
      throw new ForbiddenException(
        "Super administrator roles cannot be changed through this endpoint.",
      );
    }
    if (
      ![
        UserRole.ADMIN,
        UserRole.OPERATIONS_ADMIN,
        UserRole.SUPPORT_ADMIN,
        UserRole.MARKETING_ADMIN,
      ].includes(user.role)
    ) {
      throw new BadRequestException(
        "Only existing administrator accounts can receive another administrator role.",
      );
    }
    const previousRole = user.role;
    user.role = role as UserRole;
    user.token_version += 1;
    user.is_active = true;
    const saved = await this.dataSource.getRepository(User).save(user);
    await this.dataSource.getRepository(AuditLog).save({
      actor_id: adminId,
      actor_role: UserRole.SUPER_ADMIN,
      action: "ADMIN_ROLE_ASSIGN",
      entity_type: "USER",
      entity_id: user.id,
      before_value: { role: previousRole },
      after_value: { role: saved.role },
    });
    await this.notificationsService.sendEventNotification(
      user.id,
      "ADMIN_ROLE",
      "Administrator access updated",
      `Your platform role is now ${role.replaceAll("_", " ").toLowerCase()}. Sign in again to continue.`,
      { role },
    );
    return { id: saved.id, role: saved.role, is_active: saved.is_active };
  }

  async getReviews(options: {
    search?: string;
    status?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Number.isFinite(options.page)
      ? Math.max(1, Math.floor(options.page || 1))
      : 1;
    const limit = Number.isFinite(options.limit)
      ? Math.min(100, Math.max(1, Math.floor(options.limit || 25)))
      : 25;
    const query = this.dataSource
      .getRepository(Review)
      .createQueryBuilder("review")
      .leftJoinAndSelect("review.salon", "salon")
      .leftJoinAndSelect("review.customer", "customer")
      .leftJoinAndSelect("review.booking", "booking")
      .orderBy("review.created_at", "DESC")
      .skip((page - 1) * limit)
      .take(limit);
    const search = options.search?.trim();
    if (search) {
      query.andWhere(
        `(review.comment ILIKE :search OR review.customer_name ILIKE :search OR salon.name ILIKE :search OR booking.reference_code ILIKE :search)`,
        { search: `%${search}%` },
      );
    }
    const status = options.status?.trim().toUpperCase();
    if (status && status !== "ALL") {
      if (
        !Object.values(ReviewModerationStatus).includes(
          status as ReviewModerationStatus,
        )
      ) {
        throw new BadRequestException(`Unsupported review status: ${status}`);
      }
      query.andWhere("review.moderation_status = :status", { status });
    }
    const [items, total] = await query.getManyAndCount();
    return { items, total, page, limit };
  }

  async moderateReview(
    reviewId: string,
    status: ReviewModerationStatus,
    reason: string,
    adminId?: string,
    actorRole?: string,
  ) {
    const repository = this.dataSource.getRepository(Review);
    const review = await repository.findOne({ where: { id: reviewId } });
    if (!review) throw new NotFoundException("Review not found.");
    const normalizedReason = reason?.trim();
    if (status !== ReviewModerationStatus.PUBLISHED && !normalizedReason) {
      throw new BadRequestException("A moderation reason is required.");
    }
    const previousStatus = review.moderation_status;
    review.moderation_status = status;
    review.moderation_reason = normalizedReason || null;
    review.moderated_at = new Date();
    review.moderated_by = adminId || null;
    const saved = await repository.save(review);
    await this.reviewsService.recalculateSalonRating(review.salon_id);
    await this.dataSource.getRepository(AuditLog).save({
      actor_id: adminId,
      actor_role: actorRole || "ADMIN",
      action: `REVIEW_${status}`,
      entity_type: "REVIEW",
      entity_id: review.id,
      before_value: { moderation_status: previousStatus },
      after_value: {
        moderation_status: status,
        reason: normalizedReason || undefined,
      },
    });
    return saved;
  }

  async sendNotificationCampaign(
    dto: {
      audience: "ALL" | "CUSTOMERS" | "PARTNERS" | "USER";
      title: string;
      body: string;
      userId?: string;
      deepLink?: string;
    },
    adminId?: string,
    actorRole?: string,
  ) {
    if (dto.audience === "USER" && !dto.userId) {
      throw new BadRequestException(
        "A user is required for direct notifications.",
      );
    }
    const query = this.dataSource
      .getRepository(User)
      .createQueryBuilder("user")
      .select("user.id", "id")
      .where("user.is_active = true");
    if (dto.audience === "CUSTOMERS") {
      query.andWhere("user.role = :customerRole", {
        customerRole: UserRole.CUSTOMER,
      });
    } else if (dto.audience === "PARTNERS") {
      query.andWhere("user.role IN (:...partnerRoles)", {
        partnerRoles: [UserRole.SALON_OWNER, UserRole.SALON_STAFF],
      });
    } else if (dto.audience === "USER") {
      query.andWhere("user.id = :userId", { userId: dto.userId });
    } else {
      query.andWhere("user.role IN (:...appRoles)", {
        appRoles: [
          UserRole.CUSTOMER,
          UserRole.SALON_OWNER,
          UserRole.SALON_STAFF,
        ],
      });
    }
    const recipients = await query.getRawMany<{ id: string }>();
    if (dto.audience === "USER" && recipients.length === 0) {
      throw new NotFoundException("Active notification recipient not found.");
    }
    const result = await this.notificationsService.sendCampaign(
      recipients.map((recipient) => recipient.id),
      dto.title.trim(),
      dto.body.trim(),
      {
        audience: dto.audience,
        deepLink: dto.deepLink?.trim() || undefined,
        sentBy: adminId,
      },
    );
    await this.dataSource.getRepository(AuditLog).save({
      actor_id: adminId,
      actor_role: actorRole || "ADMIN",
      action: "NOTIFICATION_CAMPAIGN_SEND",
      entity_type: "NOTIFICATION_CAMPAIGN",
      entity_id: result.campaignId,
      after_value: {
        audience: dto.audience,
        title: dto.title.trim(),
        recipientCount: result.recipientCount,
        deliveredCount: result.deliveredCount,
      },
    });
    return result;
  }

  async getNotificationCampaigns() {
    return this.dataSource
      .getRepository(Notification)
      .createQueryBuilder("notification")
      .select("notification.payload ->> 'campaignId'", "campaignId")
      .addSelect("MAX(notification.title)", "title")
      .addSelect("MAX(notification.body)", "body")
      .addSelect("MAX(notification.payload ->> 'audience')", "audience")
      .addSelect("COUNT(notification.id)", "recipientCount")
      .addSelect("MAX(notification.created_at)", "sentAt")
      .where("notification.type = :type", { type: "ADMIN_CAMPAIGN" })
      .andWhere("notification.payload ->> 'campaignId' IS NOT NULL")
      .groupBy("notification.payload ->> 'campaignId'")
      .orderBy("MAX(notification.created_at)", "DESC")
      .limit(50)
      .getRawMany();
  }

  async getAiStyleOperations() {
    const repository = this.dataSource.getRepository(AiStyleJob);
    const counts = await repository
      .createQueryBuilder("job")
      .select("job.status", "status")
      .addSelect("COUNT(job.id)", "count")
      .groupBy("job.status")
      .getRawMany<{ status: AiJobStatus; count: string }>();
    const recent = await repository.find({
      relations: ["customer"],
      order: { created_at: "DESC" },
      take: 50,
    });
    let inferenceHealth: Record<string, any>;
    try {
      inferenceHealth = {
        available: true,
        details: await this.aiStyleService.checkHealth(),
      };
    } catch (error) {
      inferenceHealth = {
        available: false,
        error:
          error instanceof Error
            ? error.message
            : "Inference service unavailable",
      };
    }
    return {
      inferenceHealth,
      counts: Object.fromEntries(
        Object.values(AiJobStatus).map((status) => [
          status,
          Number(counts.find((item) => item.status === status)?.count || 0),
        ]),
      ),
      recentJobs: recent.map((job) => ({
        id: job.id,
        customerName: job.customer?.name || job.customer?.phone || "Customer",
        status: job.status,
        progressStage: job.progress_stage,
        completedVariations: job.completed_variations,
        variationsCount: job.variations_count,
        errorMessage: job.error_message,
        createdAt: job.created_at,
        updatedAt: job.updated_at,
      })),
    };
  }

  async getPlatformAnalytics(days = 30) {
    const safeDays = [7, 30, 90].includes(days) ? days : 30;
    const start = new Date();
    start.setUTCDate(start.getUTCDate() - safeDays + 1);
    start.setUTCHours(0, 0, 0, 0);
    const bookings = this.dataSource.getRepository(Booking);
    const summary = await bookings
      .createQueryBuilder("booking")
      .select("COUNT(booking.id)", "totalBookings")
      .addSelect(
        `COUNT(booking.id) FILTER (WHERE booking.status = 'DONE')`,
        "completedBookings",
      )
      .addSelect(
        `COUNT(booking.id) FILTER (WHERE booking.status = 'CANCELLED')`,
        "cancelledBookings",
      )
      .addSelect(
        `COALESCE(SUM(booking.total_amount) FILTER (WHERE booking.status = 'DONE'), 0)`,
        "completedRevenue",
      )
      .addSelect(
        `COALESCE(AVG(booking.total_amount) FILTER (WHERE booking.status = 'DONE'), 0)`,
        "averageTicket",
      )
      .where("booking.start_at >= :start", { start })
      .getRawOne();
    const daily = await bookings
      .createQueryBuilder("booking")
      .select(
        "TO_CHAR(booking.start_at AT TIME ZONE 'UTC', 'YYYY-MM-DD')",
        "date",
      )
      .addSelect("COUNT(booking.id)", "bookings")
      .addSelect(
        `COALESCE(SUM(booking.total_amount) FILTER (WHERE booking.status = 'DONE'), 0)`,
        "revenue",
      )
      .where("booking.start_at >= :start", { start })
      .groupBy("TO_CHAR(booking.start_at AT TIME ZONE 'UTC', 'YYYY-MM-DD')")
      .orderBy(
        "TO_CHAR(booking.start_at AT TIME ZONE 'UTC', 'YYYY-MM-DD')",
        "ASC",
      )
      .getRawMany();
    const topSalons = await bookings
      .createQueryBuilder("booking")
      .innerJoin("booking.salon", "salon")
      .select("salon.id", "salonId")
      .addSelect("salon.name", "salonName")
      .addSelect("COUNT(booking.id)", "bookings")
      .addSelect(
        `COALESCE(SUM(booking.total_amount) FILTER (WHERE booking.status = 'DONE'), 0)`,
        "revenue",
      )
      .addSelect(
        `COUNT(booking.id) FILTER (WHERE booking.status = 'CANCELLED')`,
        "cancelledBookings",
      )
      .where("booking.start_at >= :start", { start })
      .groupBy("salon.id")
      .addGroupBy("salon.name")
      .orderBy(
        `COALESCE(SUM(booking.total_amount) FILTER (WHERE booking.status = 'DONE'), 0)`,
        "DESC",
      )
      .limit(20)
      .getRawMany();
    const paymentStatuses = await bookings
      .createQueryBuilder("booking")
      .select("booking.payment_status", "status")
      .addSelect("COUNT(booking.id)", "count")
      .where("booking.start_at >= :start", { start })
      .groupBy("booking.payment_status")
      .orderBy("COUNT(booking.id)", "DESC")
      .getRawMany();
    const total = Number(summary?.totalBookings || 0);
    const cancelled = Number(summary?.cancelledBookings || 0);
    return {
      periodDays: safeDays,
      summary: {
        totalBookings: total,
        completedBookings: Number(summary?.completedBookings || 0),
        cancelledBookings: cancelled,
        cancellationRate:
          total > 0 ? Math.round((cancelled / total) * 1000) / 10 : 0,
        completedRevenue: Number(summary?.completedRevenue || 0),
        averageTicket: Math.round(Number(summary?.averageTicket || 0)),
      },
      daily: daily.map((item) => ({
        date: item.date,
        bookings: Number(item.bookings),
        revenue: Number(item.revenue),
      })),
      topSalons: topSalons.map((item) => ({
        ...item,
        bookings: Number(item.bookings),
        revenue: Number(item.revenue),
        cancelledBookings: Number(item.cancelledBookings),
      })),
      paymentStatuses: paymentStatuses.map((item) => ({
        status: item.status,
        count: Number(item.count),
      })),
    };
  }

  async getSystemHealth() {
    const checkedAt = new Date();
    const startedAt = Date.now();
    let database = { healthy: false, latencyMs: 0, pendingMigrations: false };
    try {
      await this.dataSource.query("SELECT 1");
      let pendingMigrations = false;
      try {
        pendingMigrations = await this.dataSource.showMigrations();
      } catch {
        pendingMigrations = true;
      }
      database = {
        healthy: true,
        latencyMs: Date.now() - startedAt,
        pendingMigrations,
      };
    } catch {
      database.latencyMs = Date.now() - startedAt;
    }
    const oneDayAgo = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const staleThreshold = new Date(Date.now() - 30 * 60 * 1000);
    const [
      activeDevices,
      notifications24h,
      failedAiJobs24h,
      staleAiJobs,
      openTickets,
    ] = await Promise.all([
      this.dataSource.getRepository(DeviceRegistration).count(),
      this.dataSource
        .getRepository(Notification)
        .createQueryBuilder("notification")
        .where("notification.created_at >= :oneDayAgo", { oneDayAgo })
        .getCount(),
      this.dataSource
        .getRepository(AiStyleJob)
        .createQueryBuilder("job")
        .where("job.status = :failed", { failed: AiJobStatus.FAILED })
        .andWhere("job.updated_at >= :oneDayAgo", { oneDayAgo })
        .getCount(),
      this.dataSource
        .getRepository(AiStyleJob)
        .createQueryBuilder("job")
        .where("job.status IN (:...processing)", {
          processing: [
            AiJobStatus.PENDING,
            AiJobStatus.ANALYZING,
            AiJobStatus.PROCESSING,
          ],
        })
        .andWhere("job.updated_at < :staleThreshold", { staleThreshold })
        .getCount(),
      this.dataSource
        .getRepository(SupportTicket)
        .createQueryBuilder("ticket")
        .where("ticket.status IN (:...open)", {
          open: [SupportTicketStatus.OPEN, SupportTicketStatus.IN_PROGRESS],
        })
        .getCount(),
    ]);
    const degraded =
      !database.healthy || database.pendingMigrations || staleAiJobs > 0;
    return {
      status: degraded ? "DEGRADED" : "HEALTHY",
      checkedAt,
      uptimeSeconds: Math.floor(process.uptime()),
      release: {
        version: process.env.RELEASE_VERSION || "1.0.0",
        commit: process.env.GIT_COMMIT_SHA || "dev-build",
        environment: process.env.NODE_ENV || "development",
      },
      dependencies: {
        database,
        redisConfigured: Boolean(process.env.REDIS_URL),
        aiInferenceConfigured: Boolean(process.env.AI_STYLE_SERVICE_URL),
      },
      signals: {
        activeDeviceRegistrations: activeDevices,
        notificationsLast24Hours: notifications24h,
        failedAiJobsLast24Hours: failedAiJobs24h,
        staleAiJobs,
        openSupportTickets: openTickets,
      },
    };
  }

  async getAuditLogs(options: {
    search?: string;
    action?: string;
    entityType?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Number.isFinite(options.page)
      ? Math.max(1, Math.floor(options.page || 1))
      : 1;
    const limit = Number.isFinite(options.limit)
      ? Math.min(100, Math.max(1, Math.floor(options.limit || 25)))
      : 25;
    const query = this.dataSource
      .getRepository(AuditLog)
      .createQueryBuilder("log")
      .orderBy("log.created_at", "DESC")
      .skip((page - 1) * limit)
      .take(limit);
    if (options.search?.trim()) {
      query.andWhere(
        "(log.action ILIKE :search OR log.entity_id ILIKE :search OR log.actor_id ILIKE :search OR log.request_id ILIKE :search)",
        { search: `%${options.search.trim()}%` },
      );
    }
    if (options.action?.trim() && options.action !== "ALL")
      query.andWhere("log.action = :action", { action: options.action.trim() });
    if (options.entityType?.trim() && options.entityType !== "ALL")
      query.andWhere("log.entity_type = :entityType", {
        entityType: options.entityType.trim(),
      });
    const [items, total] = await query.getManyAndCount();
    const facets = await this.dataSource
      .getRepository(AuditLog)
      .createQueryBuilder("log")
      .distinct(true)
      .select("log.action", "action")
      .addSelect("log.entity_type", "entityType")
      .orderBy("log.action", "ASC")
      .addOrderBy("log.entity_type", "ASC")
      .getRawMany();
    return {
      items,
      total,
      page,
      limit,
      actions: [...new Set(facets.map((item) => item.action).filter(Boolean))],
      entityTypes: [
        ...new Set(facets.map((item) => item.entityType).filter(Boolean)),
      ],
    };
  }

  async getOffers() {
    return this.dataSource.getRepository(Offer).find({
      relations: ["salon"],
      order: { created_at: "DESC" },
    });
  }

  async createOffer(
    dto: {
      code: string;
      name: string;
      discountType: "PERCENTAGE" | "FIXED";
      discountValue: number;
      scope: "PLATFORM" | "SALON";
      salonId?: string;
      minBookingAmount?: number;
      maxDiscountAmount?: number;
      validFrom: string;
      validUntil: string;
      globalUsageLimit?: number;
      perUserLimit?: number;
    },
    adminId?: string,
    actorRole?: string,
  ) {
    const validFrom = new Date(dto.validFrom);
    const validUntil = new Date(dto.validUntil);
    if (validUntil <= validFrom) {
      throw new BadRequestException(
        "Offer end date must be after its start date.",
      );
    }
    if (dto.discountType === "PERCENTAGE" && dto.discountValue > 100) {
      throw new BadRequestException("Percentage discounts cannot exceed 100%.");
    }
    if (dto.scope === "SALON" && !dto.salonId) {
      throw new BadRequestException(
        "A salon is required for a salon-scoped offer.",
      );
    }
    if (dto.salonId) {
      const salonExists = await this.dataSource
        .getRepository(Salon)
        .exist({ where: { id: dto.salonId } });
      if (!salonExists) throw new NotFoundException("Offer salon not found.");
    }

    const repository = this.dataSource.getRepository(Offer);
    const offer = repository.create({
      code: dto.code.trim().toUpperCase(),
      name: dto.name.trim(),
      discount_type: dto.discountType as OfferType,
      discount_value: dto.discountValue,
      scope: dto.scope as OfferScope,
      salon_id: dto.scope === "SALON" ? dto.salonId : null,
      min_booking_amount: dto.minBookingAmount ?? 0,
      max_discount_amount: dto.maxDiscountAmount,
      valid_from: validFrom,
      valid_until: validUntil,
      global_usage_limit: dto.globalUsageLimit ?? 1000,
      per_user_limit: dto.perUserLimit ?? 1,
      is_active: true,
    });
    const saved = await repository.save(offer);
    await this.dataSource.getRepository(AuditLog).save({
      actor_id: adminId,
      actor_role: actorRole || "ADMIN",
      action: "OFFER_CREATE",
      entity_type: "OFFER",
      entity_id: saved.id,
      after_value: {
        code: saved.code,
        name: saved.name,
        is_active: saved.is_active,
      },
    });
    return saved;
  }

  async updateOfferStatus(
    offerId: string,
    isActive: boolean,
    adminId?: string,
    actorRole?: string,
  ) {
    const repository = this.dataSource.getRepository(Offer);
    const offer = await repository.findOne({ where: { id: offerId } });
    if (!offer) throw new NotFoundException("Offer not found.");
    const previousActive = offer.is_active;
    offer.is_active = isActive;
    const saved = await repository.save(offer);
    await this.dataSource.getRepository(AuditLog).save({
      actor_id: adminId,
      actor_role: actorRole || "ADMIN",
      action: isActive ? "OFFER_PUBLISH" : "OFFER_PAUSE",
      entity_type: "OFFER",
      entity_id: offer.id,
      before_value: { is_active: previousActive },
      after_value: { is_active: saved.is_active },
    });
    return saved;
  }
}

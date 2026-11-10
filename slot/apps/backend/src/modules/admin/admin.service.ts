import { Injectable, NotFoundException } from "@nestjs/common";
import { DataSource } from "typeorm";
import {
  Salon,
  User,
  Booking,
  AuditLog,
  SalonApprovalHistory,
  SalonStatus,
} from "../../entities";

@Injectable()
export class AdminService {
  constructor(private readonly dataSource: DataSource) {}

  async getDashboard() {
    const totalSalons = await this.dataSource.getRepository(Salon).count();
    const activeSalons = await this.dataSource
      .getRepository(Salon)
      .count({ where: { is_active: true } });
    const pendingApprovals = await this.dataSource
      .getRepository(Salon)
      .count({ where: { is_active: false } });
    const totalUsers = await this.dataSource.getRepository(User).count();
    const totalBookings = await this.dataSource.getRepository(Booking).count();

    const bookings = await this.dataSource.getRepository(Booking).find();
    const totalRevenue = bookings.reduce(
      (sum, b) => sum + parseFloat(b.total_amount?.toString() || "0"),
      0,
    );
    const cancelledBookings = bookings.filter(
      (booking) => booking.status === "CANCELLED",
    ).length;
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
        suspendedSalons: 0,
        totalUsers,
        totalBookings,
        totalRevenue,
        newUsers,
        cancelledBookings,
      },
      charts: {
        bookingTrend: [totalBookings],
        revenueTrend: [totalRevenue],
      },
    };
  }

  async getPendingSalons() {
    return this.dataSource.getRepository(Salon).find({
      where: { is_active: false },
    });
  }

  async reviewSalon(
    salonId: string,
    action: "APPROVE" | "REJECT" | "REQUEST_CHANGES",
    adminId?: string,
    reason?: string,
  ) {
    const salon = await this.dataSource
      .getRepository(Salon)
      .findOne({ where: { id: salonId } });
    if (!salon) {
      throw new NotFoundException(`Salon with ID ${salonId} not found`);
    }

    let newStatus = SalonStatus.PENDING_APPROVAL;
    if (action === "APPROVE") {
      newStatus = SalonStatus.APPROVED;
      salon.is_active = true;
    } else if (action === "REJECT") {
      newStatus = SalonStatus.REJECTED;
      salon.is_active = false;
    } else if (action === "REQUEST_CHANGES") {
      newStatus = SalonStatus.CHANGES_REQUESTED;
    }

    await this.dataSource.getRepository(Salon).save(salon);

    // Record Approval History
    await this.dataSource.getRepository(SalonApprovalHistory).save({
      salon_id: salon.id,
      admin_id: adminId,
      action,
      new_status: newStatus,
      reason: reason || `Admin action: ${action}`,
    });

    // Record Audit Log
    await this.dataSource.getRepository(AuditLog).save({
      actor_id: adminId,
      actor_role: "ADMIN",
      action: `SALON_${action}`,
      entity_type: "SALON",
      entity_id: salon.id,
      after_value: { is_active: salon.is_active, status: newStatus },
    });

    return { salon, status: newStatus };
  }

  async getUsers() {
    const users = await this.dataSource
      .getRepository(User)
      .find({ order: { created_at: "DESC" } });
    return users.map(
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
  }

  async getBookings() {
    const bookings = await this.dataSource.getRepository(Booking).find({
      relations: ["customer", "salon", "seat", "staff", "services"],
      order: { created_at: "DESC" },
      take: 100,
    });
    return bookings.map((booking) => ({
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
    }));
  }

  async updateUserStatus(userId: string, isActive: boolean, adminId?: string) {
    const user = await this.dataSource
      .getRepository(User)
      .findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException(`User with ID ${userId} not found`);
    }
    user.is_active = isActive;
    await this.dataSource.getRepository(User).save(user);

    await this.dataSource.getRepository(AuditLog).save({
      actor_id: adminId,
      actor_role: "ADMIN",
      action: isActive ? "USER_ACTIVATE" : "USER_BLOCK",
      entity_type: "USER",
      entity_id: user.id,
      after_value: { is_active: user.is_active },
    });

    return { user, is_active: user.is_active };
  }

  async getAuditLogs() {
    return this.dataSource.getRepository(AuditLog).find({
      order: { created_at: "DESC" },
      take: 100,
    });
  }
}

import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import { DataSource } from "typeorm";
import {
  AuditLog,
  Booking,
  SupportTicket,
  SupportTicketMessage,
  SupportTicketPriority,
  SupportTicketStatus,
  UserRole,
} from "../../entities";
import { NotificationsService } from "../notifications/notifications.service";

@Injectable()
export class SupportService {
  constructor(
    private readonly dataSource: DataSource,
    private readonly notifications: NotificationsService,
  ) {}

  async createTicket(
    user: any,
    dto: {
      category: string;
      subject: string;
      message: string;
      bookingId?: string;
      priority?: SupportTicketPriority;
    },
  ) {
    if (dto.bookingId) {
      const booking = await this.dataSource
        .getRepository(Booking)
        .findOne({ where: { id: dto.bookingId } });
      if (!booking) throw new NotFoundException("Booking not found.");
      const ownsBooking =
        booking.customer_id === user.id ||
        (user.salonId && booking.salon_id === user.salonId);
      if (!ownsBooking)
        throw new ForbiddenException(
          "This booking is not available to your account.",
        );
    }
    return this.dataSource.transaction(async (manager) => {
      const ticket = await manager.getRepository(SupportTicket).save({
        requester_id: user.id,
        salon_id: user.salonId || null,
        booking_id: dto.bookingId || null,
        requester_role: user.role,
        category: dto.category.trim(),
        subject: dto.subject.trim(),
        priority: dto.priority || SupportTicketPriority.MEDIUM,
        status: SupportTicketStatus.OPEN,
      });
      await manager.getRepository(SupportTicketMessage).save({
        ticket_id: ticket.id,
        sender_id: user.id,
        sender_role: user.role,
        message: dto.message.trim(),
        internal_note: false,
      });
      return manager
        .getRepository(SupportTicket)
        .findOne({ where: { id: ticket.id }, relations: ["messages"] });
    });
  }

  async getMyTickets(userId: string) {
    return this.dataSource
      .getRepository(SupportTicket)
      .find({
        where: { requester_id: userId },
        relations: ["booking", "messages"],
        order: { updated_at: "DESC" },
      })
      .then((tickets) =>
        tickets.map((ticket) => ({
          ...ticket,
          messages: ticket.messages?.filter(
            (message) => !message.internal_note,
          ),
        })),
      );
  }

  async addRequesterMessage(ticketId: string, user: any, message: string) {
    const ticket = await this.dataSource
      .getRepository(SupportTicket)
      .findOne({ where: { id: ticketId, requester_id: user.id } });
    if (!ticket) throw new NotFoundException("Support ticket not found.");
    if (ticket.status === SupportTicketStatus.CLOSED)
      throw new BadRequestException(
        "Closed tickets cannot receive new messages.",
      );
    await this.dataSource
      .getRepository(SupportTicketMessage)
      .save({
        ticket_id: ticket.id,
        sender_id: user.id,
        sender_role: user.role,
        message: message.trim(),
        internal_note: false,
      });
    if (
      ticket.status === SupportTicketStatus.WAITING_FOR_USER ||
      ticket.status === SupportTicketStatus.RESOLVED
    ) {
      ticket.status = SupportTicketStatus.OPEN;
      await this.dataSource.getRepository(SupportTicket).save(ticket);
    } else {
      await this.dataSource
        .getRepository(SupportTicket)
        .update(ticket.id, { updated_at: new Date() });
    }
    return { status: ticket.status };
  }

  async getAdminTickets(options: {
    search?: string;
    status?: string;
    priority?: string;
    page?: number;
    limit?: number;
  }) {
    const page = Math.max(1, Math.floor(options.page || 1));
    const limit = Math.min(100, Math.max(1, Math.floor(options.limit || 25)));
    const query = this.dataSource
      .getRepository(SupportTicket)
      .createQueryBuilder("ticket")
      .leftJoinAndSelect("ticket.requester", "requester")
      .leftJoinAndSelect("ticket.salon", "salon")
      .leftJoinAndSelect("ticket.booking", "booking")
      .leftJoinAndSelect("ticket.messages", "messages")
      .leftJoinAndSelect("messages.sender", "sender")
      .orderBy("ticket.updated_at", "DESC")
      .skip((page - 1) * limit)
      .take(limit);
    if (options.search?.trim())
      query.andWhere(
        "(ticket.subject ILIKE :search OR requester.name ILIKE :search OR requester.phone ILIKE :search OR booking.reference_code ILIKE :search)",
        { search: `%${options.search.trim()}%` },
      );
    if (options.status && options.status !== "ALL") {
      if (
        !Object.values(SupportTicketStatus).includes(
          options.status as SupportTicketStatus,
        )
      )
        throw new BadRequestException("Unsupported ticket status.");
      query.andWhere("ticket.status = :status", { status: options.status });
    }
    if (options.priority && options.priority !== "ALL") {
      if (
        !Object.values(SupportTicketPriority).includes(
          options.priority as SupportTicketPriority,
        )
      )
        throw new BadRequestException("Unsupported ticket priority.");
      query.andWhere("ticket.priority = :priority", {
        priority: options.priority,
      });
    }
    const [items, total] = await query.getManyAndCount();
    return { items, total, page, limit };
  }

  async adminReply(
    ticketId: string,
    admin: any,
    message: string,
    internalNote = false,
  ) {
    const ticket = await this.dataSource
      .getRepository(SupportTicket)
      .findOne({ where: { id: ticketId } });
    if (!ticket) throw new NotFoundException("Support ticket not found.");
    await this.dataSource
      .getRepository(SupportTicketMessage)
      .save({
        ticket_id: ticket.id,
        sender_id: admin.id,
        sender_role: admin.role,
        message: message.trim(),
        internal_note: internalNote,
      });
    ticket.assigned_admin_id = ticket.assigned_admin_id || admin.id;
    if (
      !internalNote &&
      ![SupportTicketStatus.RESOLVED, SupportTicketStatus.CLOSED].includes(
        ticket.status,
      )
    )
      ticket.status = SupportTicketStatus.WAITING_FOR_USER;
    await this.dataSource.getRepository(SupportTicket).save(ticket);
    if (!internalNote)
      await this.notifications.sendEventNotification(
        ticket.requester_id,
        "SUPPORT_REPLY",
        "Support replied",
        ticket.subject,
        { ticketId: ticket.id },
      );
    return ticket;
  }

  async updateStatus(
    ticketId: string,
    status: SupportTicketStatus,
    admin: any,
  ) {
    const ticket = await this.dataSource
      .getRepository(SupportTicket)
      .findOne({ where: { id: ticketId } });
    if (!ticket) throw new NotFoundException("Support ticket not found.");
    const previous = ticket.status;
    ticket.status = status;
    ticket.assigned_admin_id = ticket.assigned_admin_id || admin.id;
    const saved = await this.dataSource
      .getRepository(SupportTicket)
      .save(ticket);
    await this.dataSource
      .getRepository(AuditLog)
      .save({
        actor_id: admin.id,
        actor_role: admin.role,
        action: "SUPPORT_STATUS_UPDATE",
        entity_type: "SUPPORT_TICKET",
        entity_id: ticket.id,
        before_value: { status: previous },
        after_value: { status },
      });
    await this.notifications.sendEventNotification(
      ticket.requester_id,
      "SUPPORT_STATUS",
      "Support ticket updated",
      `${ticket.subject}: ${status.replaceAll("_", " ").toLowerCase()}`,
      { ticketId: ticket.id, status },
    );
    return saved;
  }
}

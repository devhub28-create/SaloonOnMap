import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from "typeorm";
import { User } from "./user.entity";
import { Salon } from "./salon.entity";
import { Booking } from "./booking.entity";
import { SupportTicketMessage } from "./support-ticket-message.entity";

export enum SupportTicketStatus {
  OPEN = "OPEN",
  IN_PROGRESS = "IN_PROGRESS",
  WAITING_FOR_USER = "WAITING_FOR_USER",
  RESOLVED = "RESOLVED",
  CLOSED = "CLOSED",
}
export enum SupportTicketPriority {
  LOW = "LOW",
  MEDIUM = "MEDIUM",
  HIGH = "HIGH",
  URGENT = "URGENT",
}

@Entity("support_tickets")
@Index(["status", "priority", "updated_at"])
@Index(["requester_id", "created_at"])
export class SupportTicket {
  @PrimaryGeneratedColumn("uuid") id: string;
  @Column() requester_id: string;
  @ManyToOne(() => User, { onDelete: "CASCADE" })
  @JoinColumn({ name: "requester_id" })
  requester: User;
  @Column({ nullable: true }) salon_id: string;
  @ManyToOne(() => Salon, { nullable: true, onDelete: "SET NULL" })
  @JoinColumn({ name: "salon_id" })
  salon: Salon;
  @Column({ nullable: true }) booking_id: string;
  @ManyToOne(() => Booking, { nullable: true, onDelete: "SET NULL" })
  @JoinColumn({ name: "booking_id" })
  booking: Booking;
  @Column() requester_role: string;
  @Column() category: string;
  @Column() subject: string;
  @Column({
    type: "enum",
    enum: SupportTicketStatus,
    default: SupportTicketStatus.OPEN,
  })
  status: SupportTicketStatus;
  @Column({
    type: "enum",
    enum: SupportTicketPriority,
    default: SupportTicketPriority.MEDIUM,
  })
  priority: SupportTicketPriority;
  @Column({ nullable: true }) assigned_admin_id: string;
  @ManyToOne(() => User, { nullable: true, onDelete: "SET NULL" })
  @JoinColumn({ name: "assigned_admin_id" })
  assigned_admin: User;
  @OneToMany(() => SupportTicketMessage, (message) => message.ticket)
  messages: SupportTicketMessage[];
  @CreateDateColumn() created_at: Date;
  @UpdateDateColumn() updated_at: Date;
}

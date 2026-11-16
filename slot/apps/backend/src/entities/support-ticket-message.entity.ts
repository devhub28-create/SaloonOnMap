import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
} from "typeorm";
import { User } from "./user.entity";
import { SupportTicket } from "./support-ticket.entity";

@Entity("support_ticket_messages")
@Index(["ticket_id", "created_at"])
export class SupportTicketMessage {
  @PrimaryGeneratedColumn("uuid") id: string;
  @Column() ticket_id: string;
  @ManyToOne(() => SupportTicket, (ticket) => ticket.messages, {
    onDelete: "CASCADE",
  })
  @JoinColumn({ name: "ticket_id" })
  ticket: SupportTicket;
  @Column() sender_id: string;
  @ManyToOne(() => User, { onDelete: "CASCADE" })
  @JoinColumn({ name: "sender_id" })
  sender: User;
  @Column() sender_role: string;
  @Column({ type: "text" }) message: string;
  @Column({ type: "boolean", default: false }) internal_note: boolean;
  @CreateDateColumn() created_at: Date;
}

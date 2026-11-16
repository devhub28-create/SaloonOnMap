import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from "typeorm";
import { User } from "./user.entity";
import { Salon } from "./salon.entity";
import { Booking } from "./booking.entity";

export enum ReviewModerationStatus {
  PUBLISHED = "PUBLISHED",
  FLAGGED = "FLAGGED",
  HIDDEN = "HIDDEN",
}

@Entity("reviews")
@Index(["salon_id", "created_at"])
@Index(["customer_id"])
@Index(["booking_id"], { unique: true })
export class Review {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column()
  booking_id: string;

  @ManyToOne(() => Booking, { onDelete: "CASCADE" })
  @JoinColumn({ name: "booking_id" })
  booking: Booking;

  @Column()
  customer_id: string;

  @ManyToOne(() => User, { onDelete: "CASCADE" })
  @JoinColumn({ name: "customer_id" })
  customer: User;

  @Column()
  salon_id: string;

  @ManyToOne(() => Salon, { onDelete: "CASCADE" })
  @JoinColumn({ name: "salon_id" })
  salon: Salon;

  @Column({ type: "int" })
  rating: number;

  @Column({ nullable: true })
  comment: string;

  @Column("simple-array", { nullable: true })
  tags: string[];

  @Column({ nullable: true })
  customer_name: string;

  @Column({
    type: "enum",
    enum: ReviewModerationStatus,
    default: ReviewModerationStatus.PUBLISHED,
  })
  moderation_status: ReviewModerationStatus;

  @Column({ nullable: true })
  moderation_reason: string;

  @Column({ type: "timestamptz", nullable: true })
  moderated_at: Date;

  @Column({ nullable: true })
  moderated_by: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}

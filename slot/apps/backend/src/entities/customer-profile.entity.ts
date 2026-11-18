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

@Entity("customer_profiles")
@Index(["user_id"], { unique: true })
export class CustomerProfile {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column()
  user_id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: "user_id" })
  user: User;

  @Column({ default: "ALL" })
  preferred_gender: string;

  @Column({ nullable: true })
  referral_code: string;

  @Column({
    type: "jsonb",
    default: () =>
      '\'{"bookingReminders":true,"holdAlerts":true,"promotions":true}\'::jsonb',
  })
  notification_preferences: {
    bookingReminders: boolean;
    holdAlerts: boolean;
    promotions: boolean;
  };

  @Column({ type: "uuid", array: true, default: () => "'{}'::uuid[]" })
  favorite_salon_ids: string[];

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}

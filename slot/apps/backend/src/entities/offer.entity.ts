import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Salon } from './salon.entity';

export enum OfferType {
  PERCENTAGE = 'PERCENTAGE',
  FIXED = 'FIXED',
}

export enum OfferScope {
  PLATFORM = 'PLATFORM',
  SALON = 'SALON',
  SERVICE = 'SERVICE',
  COMBO = 'COMBO',
}

@Entity('offers')
export class Offer {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  code: string;

  @Column()
  name: string;

  @Column({ type: 'enum', enum: OfferType, default: OfferType.PERCENTAGE })
  discount_type: OfferType;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  discount_value: number;

  @Column({ type: 'enum', enum: OfferScope, default: OfferScope.PLATFORM })
  scope: OfferScope;

  @Column({ nullable: true })
  salon_id: string;

  @ManyToOne(() => Salon, { nullable: true })
  @JoinColumn({ name: 'salon_id' })
  salon: Salon;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  min_booking_amount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  max_discount_amount: number;

  @Column({ type: 'timestamp' })
  valid_from: Date;

  @Column({ type: 'timestamp' })
  valid_until: Date;

  @Column({ default: 1000 })
  global_usage_limit: number;

  @Column({ default: 0 })
  current_usage_count: number;

  @Column({ default: 1 })
  per_user_limit: number;

  @Column({ default: true })
  is_active: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}

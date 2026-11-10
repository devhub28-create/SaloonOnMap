import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, Index, OneToMany } from 'typeorm';
import { User } from './user.entity';
import { Salon } from './salon.entity';
import { Seat } from './seat.entity';
import { Staff } from './staff.entity';
import { BookingHold } from './booking-hold.entity';
import { BookingService } from './booking-service.entity';

export enum BookingStatus {
  CONFIRMED = 'CONFIRMED',
  WAITING = 'WAITING',
  IN_SERVICE = 'IN_SERVICE',
  DONE = 'DONE',
  CANCELLED = 'CANCELLED',
}

@Entity('bookings')
@Index(['seat_id', 'start_at', 'end_at'])
@Index(['customer_id'])
@Index(['salon_id'])
@Index(['salon_id', 'status', 'start_at'])
export class Booking {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  reference_code: string;

  @Column()
  customer_id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column()
  salon_id: string;

  @ManyToOne(() => Salon)
  @JoinColumn({ name: 'salon_id' })
  salon: Salon;

  @Column()
  seat_id: string;

  @ManyToOne(() => Seat)
  @JoinColumn({ name: 'seat_id' })
  seat: Seat;

  @Column({ nullable: true })
  staff_id: string;

  @ManyToOne(() => Staff, { nullable: true })
  @JoinColumn({ name: 'staff_id' })
  staff: Staff;

  @Column({ nullable: true })
  hold_id: string;

  @ManyToOne(() => BookingHold, { nullable: true })
  @JoinColumn({ name: 'hold_id' })
  hold: BookingHold;

  @Column({ nullable: true, unique: true })
  idempotency_key: string;

  @Column({ type: 'timestamptz' })
  start_at: Date;

  @Column({ type: 'timestamptz' })
  end_at: Date;

  @Column({ type: 'enum', enum: BookingStatus, default: BookingStatus.CONFIRMED })
  status: BookingStatus;

  @Column({ default: 'PAID_AT_SALON' })
  payment_status: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  total_amount: number;

  @Column({ nullable: true })
  notes: string;

  @OneToMany(() => BookingService, (bs) => bs.booking, { cascade: true })
  services: BookingService[];

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}

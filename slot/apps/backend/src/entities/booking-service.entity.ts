import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, Index } from 'typeorm';
import { Booking } from './booking.entity';
import { SalonService } from './salon-service.entity';

@Entity('booking_services')
@Index(['booking_id', 'salon_service_id'], { unique: true })
export class BookingService {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  booking_id: string;

  @ManyToOne(() => Booking, (b) => b.services, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'booking_id' })
  booking: Booking;

  @Column()
  salon_service_id: string;

  @ManyToOne(() => SalonService)
  @JoinColumn({ name: 'salon_service_id' })
  salon_service: SalonService;

  @Column()
  service_name: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  price: number;

  @Column()
  duration_minutes: number;
}

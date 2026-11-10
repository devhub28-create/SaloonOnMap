import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('salons')
export class Salon {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ unique: true })
  slug: string;

  @Column()
  address: string;

  @Column()
  city: string;

  @Column()
  area: string;

  @Column({ type: 'float', default: 12.9784 })
  latitude: number;

  @Column({ type: 'float', default: 77.6408 })
  longitude: number;

  @Column({ type: 'float', default: 4.9 })
  rating: number;

  @Column({ default: 2841 })
  review_count: number;

  @Column({ default: true })
  is_active: boolean;

  @Column({ default: 'UNISEX' })
  target_gender: string;

  @Column({ default: '09:00' })
  opening_time: string;

  @Column({ default: '21:00' })
  closing_time: string;

  @Column({ default: 'Asia/Kolkata' })
  timezone: string;

  @Column({ nullable: true })
  cover_image: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}

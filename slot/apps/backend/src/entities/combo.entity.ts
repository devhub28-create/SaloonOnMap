import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Salon } from './salon.entity';

@Entity('combos')
export class Combo {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  salon_id: string;

  @ManyToOne(() => Salon)
  @JoinColumn({ name: 'salon_id' })
  salon: Salon;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  price: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  original_price: number;

  @Column()
  duration_minutes: number;

  @Column({ default: false })
  is_bestseller: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}

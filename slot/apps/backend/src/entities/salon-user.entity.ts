import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, Index } from 'typeorm';
import { Salon } from './salon.entity';
import { User } from './user.entity';

@Entity('salon_users')
@Index(['user_id'], { unique: true })
@Index(['salon_id', 'user_id'], { unique: true })
export class SalonUser {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  salon_id: string;

  @ManyToOne(() => Salon)
  @JoinColumn({ name: 'salon_id' })
  salon: Salon;

  @Column()
  user_id: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ default: 'OWNER' })
  role: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}

import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, JoinColumn } from 'typeorm';
import { Salon, SalonStatus } from './salon.entity';
import { User } from './user.entity';

export { SalonStatus } from './salon.entity';

@Entity('salon_approval_history')
export class SalonApprovalHistory {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  salon_id: string;

  @ManyToOne(() => Salon)
  @JoinColumn({ name: 'salon_id' })
  salon: Salon;

  @Column({ nullable: true })
  admin_id: string;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'admin_id' })
  admin: User;

  @Column()
  action: string;

  @Column({ nullable: true })
  previous_status: string;

  @Column()
  new_status: string;

  @Column({ nullable: true })
  reason: string;

  @CreateDateColumn()
  created_at: Date;
}

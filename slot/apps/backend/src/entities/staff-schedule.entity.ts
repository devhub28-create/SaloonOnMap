import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, Index } from 'typeorm';
import { Staff } from './staff.entity';

@Entity('staff_schedules')
@Index(['staff_id', 'day_of_week'], { unique: true })
export class StaffSchedule {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  staff_id: string;

  @ManyToOne(() => Staff)
  @JoinColumn({ name: 'staff_id' })
  staff: Staff;

  @Column()
  day_of_week: number; // 0 = Sunday, 1 = Monday...

  @Column({ default: '09:00' })
  shift_start: string;

  @Column({ default: '18:00' })
  shift_end: string;

  @Column({ default: '13:00' })
  break_start: string;

  @Column({ default: '14:00' })
  break_end: string;

  @Column({ default: true })
  is_working_day: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}

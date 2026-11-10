import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from './user.entity';

@Entity('ai_saved_looks')
@Index(['customer_id', 'created_at'])
export class AiSavedLook {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  customer_id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ nullable: true })
  job_id: string;

  @Column({ nullable: true })
  archetype_id: string;

  @Column({ type: 'int', nullable: true })
  option_number: number;

  @Column({ type: 'text' })
  original_image_url: string;

  @Column({ type: 'text' })
  styled_image_url: string;

  @Column({ nullable: true })
  hair_style: string;

  @Column({ nullable: true })
  beard_style: string;

  @Column({ default: 'My AI Look' })
  title: string;

  @Column({ type: 'text', nullable: true })
  notes: string;

  @Column({ type: 'text', nullable: true })
  why_it_suits: string;

  @Column({ type: 'int', nullable: true })
  suitability_score: number;

  @Column({ nullable: true })
  maintenance_level: string;

  @Column({ nullable: true })
  hair_length_cm: string;

  @Column({ nullable: true })
  beard_length_mm: string;

  @Column({ type: 'text', nullable: true })
  styling_products: string;

  @Column({ type: 'jsonb', nullable: true })
  barber_instructions: string[];

  @Column({ type: 'boolean', default: false })
  is_shared: boolean;

  @Column({ nullable: true })
  share_token: string;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}

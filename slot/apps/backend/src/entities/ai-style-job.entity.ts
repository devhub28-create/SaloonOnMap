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

export enum AiJobStatus {
  PENDING = 'PENDING',
  ANALYZING = 'ANALYZING',
  PROCESSING = 'PROCESSING',
  PARTIALLY_COMPLETED = 'PARTIALLY_COMPLETED',
  COMPLETED = 'COMPLETED',
  FAILED = 'FAILED',
}

export interface AiVariationItem {
  id: string;
  archetype_id?: string;
  option_number?: number;
  image_url: string;
  side_image_url?: string;
  back_image_url?: string;
  side_view_available?: boolean;
  back_view_available?: boolean;
  style_label: string;
  hair_style?: string;
  beard_style?: string;
  header_hex?: string;
  hair_length_cm?: string;
  beard_length_mm?: string;
  hair_desc?: string;
  beard_desc?: string;
  look_desc?: string;
  why_it_suits?: string;
  suitability_score?: number;
  maintenance_level?: string;
  styling_products?: string;
  barber_instructions?: string[];
  is_recommended?: boolean;
  storyboard_image_url?: string;
  barber_notes?: string[];
  best_option?: any;
  seed?: number;
  elapsed_seconds?: number;
}

@Entity('ai_style_jobs')
@Index(['customer_id', 'created_at'])
export class AiStyleJob {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  customer_id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'customer_id' })
  customer: User;

  @Column({ type: 'text' })
  original_image_url: string;

  @Column({ nullable: true })
  hair_style: string;

  @Column({ nullable: true })
  beard_style: string;

  @Column({ nullable: true })
  hair_color: string;

  @Column({ nullable: true })
  beard_color: string;

  @Column({ type: 'int', default: 6 })
  variations_count: number;

  @Column({ type: 'int', default: 0 })
  completed_variations: number;

  @Column({ nullable: true, default: 'COMPLETED' })
  progress_stage: string;

  @Column({
    type: 'enum',
    enum: AiJobStatus,
    default: AiJobStatus.PENDING,
  })
  status: AiJobStatus;

  @Column({ type: 'text', nullable: true })
  error_message: string;

  @Column({ type: 'jsonb', nullable: true })
  analysis_result: Record<string, any>;

  @Column({ type: 'jsonb', nullable: true })
  preferences: Record<string, any>;

  @Column({ type: 'text', nullable: true })
  storyboard_image_url: string;

  @Column({ type: 'jsonb', nullable: true })
  barber_notes: string[];

  @Column({ type: 'jsonb', nullable: true })
  best_option: Record<string, any>;

  @Column({ type: 'jsonb', default: () => "'[]'" })
  variations: AiVariationItem[];

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}

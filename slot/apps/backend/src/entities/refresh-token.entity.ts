import { Column, CreateDateColumn, Entity, Index, JoinColumn, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';
import { User } from './user.entity';

@Entity('refresh_tokens')
@Index(['token_hash'], { unique: true })
@Index(['user_id', 'expires_at'])
export class RefreshToken {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column() user_id: string;
  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' }) user: User;
  @Column() token_hash: string;
  @Column({ type: 'timestamptz' }) expires_at: Date;
  @Column({ type: 'timestamptz', nullable: true }) revoked_at?: Date;
  @CreateDateColumn() created_at: Date;
}

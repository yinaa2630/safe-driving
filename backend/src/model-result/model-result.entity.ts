import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { DriveRecord } from '../drive-record/drive-record.entity';

@Entity('model_results')
export class ModelResult {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'double precision' })
  score: number;

  @CreateDateColumn({ type: 'timestamp' })
  predicted_at: Date;

  @Column()
  drive_id: number;
}
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
} from 'typeorm';
import { DriveEvent } from '../model-result/model-result.entity';

@Entity('drive_records')
export class DriveRecord {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'date', name: 'drive_date' })
  driveDate: Date;

  @Column({ type: 'timestamp', name: 'start_time' })
  startTime: Date;

  @Column({ type: 'timestamp', name: 'end_time' })
  endTime: Date;

  @Column({ type: 'int4' })
  duration: number;

  @Column({ type: 'float8', name: 'avg_drowsiness' })
  avgDrowsiness: number;

  @Column({ type: 'int4', name: 'warning_count' })
  warningCount: number;

  @Column({ type: 'int4', name: 'attention_count', default: 0 })
  attentionCount: number;

  @Column({ type: 'int4', name: 'user_id' })
  userId: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, name: 'start_lat' })
  startLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, name: 'start_lng' })
  startLng: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, name: 'end_lat' })
  endLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, name: 'end_lng' })
  endLng: number;

  @OneToMany(() => DriveEvent, (event) => event.driveRecord)
  events: DriveEvent[];
}
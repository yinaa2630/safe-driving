import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  OneToMany,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { DriveEvent } from '../model-result/model-result.entity';
import { User } from '../user/user.entity';

@Entity('drive_records')
export class DriveRecord {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'date', name: 'drive_date' })
  driveDate: Date;

  @Column({ type: 'timestamp', name: 'start_time' })
  startTime: Date;

  @Column({ type: 'timestamp', name: 'end_time', nullable: true })
  endTime: Date | null;

  @Column({ type: 'int4', nullable: true })
  duration: number | null;

  @Column({ type: 'float8', name: 'avg_drowsiness', nullable: true })
  avgDrowsiness: number | null;

  @Column({ type: 'int4', name: 'warning_count', nullable: true })
  warningCount: number | null;

  @Column({ type: 'int4', name: 'attention_count', default: 0 })
  attentionCount: number;

  @Column({ type: 'int4', name: 'user_id' })
  userId: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, name: 'start_lat' })
  startLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, name: 'start_lng' })
  startLng: number;

  @Column({ type: 'decimal', precision: 10, scale: 7, name: 'end_lat', nullable: true })
  endLat: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 7, name: 'end_lng', nullable: true })
  endLng: number | null;

  @ManyToOne(() => User, (user) => user.driveRecords, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @OneToMany(() => DriveEvent, (event) => event.driveRecord)
  events: DriveEvent[];
}
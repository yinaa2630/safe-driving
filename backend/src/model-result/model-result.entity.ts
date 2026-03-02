import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { DriveRecord } from '../drive-record/drive-record.entity';

@Entity('drive_events')
export class DriveEvent {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'int4', name: 'drive_record_id' })
  driveRecordId: number;

  @Column({ type: 'varchar', length: 30, name: 'event_type' })
  eventType: string;

  @Column({ type: 'timestamp', name: 'event_time' })
  eventTime: Date;

  @Column({ type: 'decimal', precision: 10, scale: 7 })
  lat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7 })
  lng: number;

  @Column({ type: 'float8' })
  score: number;

  @ManyToOne(() => DriveRecord, (record) => record.events, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'drive_record_id' })
  driveRecord: DriveRecord;
}
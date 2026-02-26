import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('drive_records')
export class DriveRecord {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ type: 'date' })
  drive_date: Date;

  @Column({ type: 'timestamp' })
  start_time: Date;

  @Column({ type: 'timestamp' })
  end_time: Date;

  @Column({ type: 'int' })
  duration: number;

  @Column({ type: 'double precision' })
  avg_drowsiness: number;

  @Column({ type: 'int' })
  warning_count: number;

  @CreateDateColumn({ type: 'timestamp' })
  created_at: Date;

  @Column()
  user_id: number;
}
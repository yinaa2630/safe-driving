import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../user/user.entity';
import { ModelResult } from '../model-result/model-result.entity';

@Entity('drive_records')
export class DriveRecord {
  @PrimaryGeneratedColumn()
  id: number;

  // 주행 날짜 (날짜만)
  @Column({ type: 'date' })
  drive_date: Date;

  // 시작 시간 (날짜 + 시간)
  @Column({ type: 'timestamp' })
  start_time: Date;

  // 종료 시간 (날짜 + 시간)
  @Column({ type: 'timestamp' })
  end_time: Date;

  @Column({ type: 'int' })
  duration: number; // 초 단위 추천

  @Column({ type: 'double precision' })
  avg_drowsiness: number;

  @Column({ type: 'int' })
  warning_count: number;

  @CreateDateColumn({ type: 'timestamp' })
  created_at: Date;

  @Column()
  user_id: number;

  @ManyToOne(() => User, user => user.driveRecords, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @OneToMany(() => ModelResult, result => result.driveRecord)
  modelResults: ModelResult[];
}
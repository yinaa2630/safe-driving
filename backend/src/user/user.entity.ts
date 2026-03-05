import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  OneToMany,
} from 'typeorm';
import { DriveRecord } from '../drive-record/drive-record.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  email: string;

  @Column()
  password: string;

  @Column()
  username: string;

  @CreateDateColumn({ type: 'timestamp' })
  created_at: Date;

  @Column({ name: 'emergency_call', nullable: false })
  emergencyCall: string;

  @OneToMany(() => DriveRecord, (record) => record.user)
  driveRecords: DriveRecord[];
}
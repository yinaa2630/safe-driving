import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DriveRecord } from './drive-record.entity';

@Injectable()
export class DriveRecordService {
  constructor(
    @InjectRepository(DriveRecord)
    private readonly driveRecordRepository: Repository<DriveRecord>,
  ) {}

  async create(data: any) {
  const record = this.driveRecordRepository.create({
    drive_date: data.drive_date,
    start_time: data.start_time,
    end_time: data.end_time,
    duration: data.duration,
    avg_drowsiness: data.avg_drowsiness,
    warning_count: data.warning_count,

    user: { id: data.user_id },
  });

  return this.driveRecordRepository.save(record);
}
}
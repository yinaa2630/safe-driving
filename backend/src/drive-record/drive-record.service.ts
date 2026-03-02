import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DriveRecord } from './drive-record.entity';

@Injectable()
export class DriveRecordService {
  constructor(
    @InjectRepository(DriveRecord)
    private readonly driveRecordRepository: Repository<DriveRecord>,
  ) {}

  // 주행 시작
  async create(data: any, userId: number) {
    const record = this.driveRecordRepository.create({
      driveDate: data.drive_date,
      startTime: data.start_time,
      endTime: null,
      duration: null,
      avgDrowsiness: null,
      warningCount: null,
      attentionCount: data.attention_count ?? 0,
      userId: userId,
      startLat: data.start_lat,
      startLng: data.start_lng,
      endLat: null,
      endLng: null,
    });

    return this.driveRecordRepository.save(record);
  }

  // 주행 종료
  async endDrive(id: number, data: any, userId: number) {
    const record = await this.driveRecordRepository.findOne({
      where: { id },
    });

    if (!record) {
      throw new NotFoundException('Drive record not found');
    }

    if (record.userId !== userId) {
      throw new ForbiddenException('Unauthorized access');
    }

    record.endTime = data.end_time;
    record.duration = data.duration;
    record.avgDrowsiness = data.avg_drowsiness;
    record.warningCount = data.warning_count;
    record.attentionCount = data.attention_count;
    record.endLat = data.end_lat;
    record.endLng = data.end_lng;

    return this.driveRecordRepository.save(record);
  }
}
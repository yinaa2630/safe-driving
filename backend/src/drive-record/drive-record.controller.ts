import { Controller, Post, Body } from '@nestjs/common';
import { DriveRecordService } from './drive-record.service';

@Controller('drive-record')
export class DriveRecordController {
  constructor(private readonly driveRecordService: DriveRecordService) {}

  @Post()
  async create(@Body() body: any) {
    return this.driveRecordService.create({
      drive_date: body.drive_date,
      start_time: body.start_time,
      end_time: body.end_time,
      duration: body.duration,
      avg_drowsiness: body.avg_drowsiness,
      warning_count: body.warning_count,
      user: { id: body.userId }, 
    });
  }
}
import { Controller, Post, Body } from '@nestjs/common';
import { DriveRecordService } from './drive-record.service';

@Controller('drive-record')
export class DriveRecordController {
  constructor(private readonly driveRecordService: DriveRecordService) {}

  @Post()
  async create(@Body() body: any) {
    return this.driveRecordService.create(body);
  }
}
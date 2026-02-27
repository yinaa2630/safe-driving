import { Controller, Post, Body, UseGuards, Req } from '@nestjs/common';
import { DriveRecordService } from './drive-record.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('drive-record')
export class DriveRecordController {
  constructor(private readonly driveRecordService: DriveRecordService) {}

  @UseGuards(JwtAuthGuard)
  @Post()
  async create(@Req() req: any, @Body() body: any) {
    const userId = req.user.id; 
    return this.driveRecordService.create(body, userId);
  }
}
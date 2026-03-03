import {
  Controller,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
  Req,
} from '@nestjs/common';
import { DriveRecordService } from './drive-record.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('drive-record')
export class DriveRecordController {
  constructor(
    private readonly driveRecordService: DriveRecordService,
  ) {}

  // 주행 시작
  @UseGuards(JwtAuthGuard)
  @Post()
  async create(@Req() req: any, @Body() body: any) {
    const userId = req.user.userId;
    return this.driveRecordService.create(body, userId);
  }

  // 주행 종료
  @UseGuards(JwtAuthGuard)
  @Patch(':id')
  async endDrive(
    @Param('id') id: string,
    @Req() req: any,
    @Body() body: any,
  ) {
    const userId = req.user.userId;
    return this.driveRecordService.endDrive(
      +id,
      body,
      userId,
    );
  }
}
import { Controller, Post, Body } from '@nestjs/common';
import { ModelResultService } from './model-result.service';

@Controller('drive-events')
export class ModelResultController {
  constructor(private readonly modelResultService: ModelResultService) {}

  @Post()
  async create(@Body() body: any) {
    return this.modelResultService.create({
      driveRecordId: body.drive_record_id,
      eventType: body.event_type,
      eventTime: body.event_time,
      lat: body.lat,
      lng: body.lng,
      score: body.score,
    });
  }
}
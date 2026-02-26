import { Controller, Post, Body } from '@nestjs/common';
import { ModelResultService } from './model-result.service';

@Controller('model-result')
export class ModelResultController {
  constructor(private readonly modelResultService: ModelResultService) {}

  @Post()
  async create(@Body() body: any) {
    return this.modelResultService.create({
      score: body.score,
      predicted_at: body.predicted_at,
      driveRecord: { id: body.driveId }, // FK 연결
    });
  }
}
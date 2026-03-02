import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
// import { ModelResult } from './model-result.entity';
import { ModelResultService } from './model-result.service';
import { ModelResultController } from './model-result.controller';
import { DriveEvent } from './model-result.entity';

@Module({
  imports: [TypeOrmModule.forFeature([DriveEvent])],
  providers: [ModelResultService],
  controllers: [ModelResultController],
})
export class ModelResultModule {}
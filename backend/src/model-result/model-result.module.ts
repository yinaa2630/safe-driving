import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ModelResult } from './model-result.entity';
import { ModelResultService } from './model-result.service';
import { ModelResultController } from './model-result.controller';

@Module({
  imports: [TypeOrmModule.forFeature([ModelResult])],
  providers: [ModelResultService],
  controllers: [ModelResultController],
})
export class ModelResultModule {}
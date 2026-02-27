import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ModelResult } from './model-result.entity';

@Injectable()
export class ModelResultService {
  constructor(
    @InjectRepository(ModelResult)
    private readonly modelResultRepository: Repository<ModelResult>,
  ) {}

  async create(data: any) {
    const result = this.modelResultRepository.create({
      score: data.score,
      drive_id: data.driveId,
    });

    return this.modelResultRepository.save(result);
  }
}
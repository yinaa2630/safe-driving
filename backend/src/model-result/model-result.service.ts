import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DriveEvent } from './model-result.entity';
@Injectable()
export class ModelResultService {
  constructor(
    @InjectRepository(DriveEvent)                    
    private readonly driveEventRepository: Repository<DriveEvent>,
  ) {}

  async create(data: any) {
    const result = this.driveEventRepository.create({
      driveRecordId: data.driveRecordId,   
      eventType: data.eventType,           
      eventTime: data.eventTime,           
      lat: data.lat,                      
      lng: data.lng,                     
      score: data.score,
    });

    return this.driveEventRepository.save(result);
  }
}
import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DriveRecord } from './drive-record.entity';

@Injectable()
export class DriveRecordService {
  constructor(
    @InjectRepository(DriveRecord)
    private readonly driveRecordRepository: Repository<DriveRecord>,
  ) {}

  async create(data: any, userId: number) {
    const record = this.driveRecordRepository.create({
      driveDate: data.driveDate,           
      startTime: data.startTime,           
      endTime: data.endTime,               
      duration: data.duration,
      avgDrowsiness: data.avgDrowsiness,   
      warningCount: data.warningCount,     
      attentionCount: data.attentionCount ?? 0,  
      userId: userId,                    
      startLat: data.startLat,           
      startLng: data.startLng,           
      endLat: data.endLat,                
      endLng: data.endLng,              
    });

    return this.driveRecordRepository.save(record);
  }
}
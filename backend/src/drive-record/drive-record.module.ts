import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DriveRecord } from './drive-record.entity';
import { DriveRecordService } from './drive-record.service';
import { DriveRecordController } from './drive-record.controller';

@Module({
  imports: [TypeOrmModule.forFeature([DriveRecord])],
  providers: [DriveRecordService],
  controllers: [DriveRecordController],
})
export class DriveRecordModule {}
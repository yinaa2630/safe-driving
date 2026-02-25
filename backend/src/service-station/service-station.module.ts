import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ServiceStationController } from './service-station.controller';
import { ServiceStationService } from './service-station.service';
import { ServiceStation } from './service-station.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ServiceStation])],
  controllers: [ServiceStationController],
  providers: [ServiceStationService],
})
export class ServiceStationModule {}
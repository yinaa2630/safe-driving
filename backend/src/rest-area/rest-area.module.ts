import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RestAreaController } from './rest-area.controller';
import { RestAreaService } from './rest-area.service';
import { RestArea } from './rest-area.entity';
import { ServiceStation } from '../service-station/service-station.entity';

@Module({
  imports: [TypeOrmModule.forFeature([RestArea, ServiceStation])],
  controllers: [RestAreaController],
  providers: [RestAreaService],
})
export class RestAreaModule {}
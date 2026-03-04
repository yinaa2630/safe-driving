import { Controller, Get, Query } from '@nestjs/common';
import { RestAreaService } from './rest-area.service';

@Controller('rest-area')
export class RestAreaController {
  constructor(private readonly restAreaService: RestAreaService) {}

  @Get('nearest')
  async findNearest(
    @Query('lat') lat: string,
    @Query('lng') lng: string,
    @Query('bearing') bearing: string,
    @Query('limit') limit: string,
  ) {
    console.log('📥 받은 bearing:', bearing, 'parsed:', parseFloat(bearing));

    return this.restAreaService.findNearest(
      parseFloat(lat),
      parseFloat(lng),
      parseFloat(bearing),
      limit ? parseInt(limit) : 3,
    );
  }
}
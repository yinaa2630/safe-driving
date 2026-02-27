import { Test, TestingModule } from '@nestjs/testing';
import { ServiceStationService } from './service-station.service';

describe('ServiceStationService', () => {
  let service: ServiceStationService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [ServiceStationService],
    }).compile();

    service = module.get<ServiceStationService>(ServiceStationService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});

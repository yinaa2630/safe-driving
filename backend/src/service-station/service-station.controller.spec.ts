import { Test, TestingModule } from '@nestjs/testing';
import { ServiceStationController } from './service-station.controller';

describe('ServiceStationController', () => {
  let controller: ServiceStationController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ServiceStationController],
    }).compile();

    controller = module.get<ServiceStationController>(ServiceStationController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});

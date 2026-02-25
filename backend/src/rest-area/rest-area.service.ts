import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RestArea } from './rest-area.entity';
import { ServiceStation } from '../service-station/service-station.entity';
import { getDistance, getRhumbLineBearing } from 'geolib';

@Injectable()
export class RestAreaService {
  constructor(
    @InjectRepository(RestArea)
    private restAreaRepository: Repository<RestArea>,

    @InjectRepository(ServiceStation)
    private serviceStationRepository: Repository<ServiceStation>,
  ) {}

  async findNearest(
    userLat: number,
    userLng: number,
    userBearing: number,
    limit: number = 3,
  ) {
    const restAreas = await this.restAreaRepository.find();
    const serviceStations = await this.serviceStationRepository.find();

    const userLocation = { latitude: userLat, longitude: userLng };

    const processPlaces = (places: any[], type: string) => {
      return places
        .filter((place) => {
          if (!place.latitude || !place.longitude) return false;

          return true;
        })
        .map((place) => ({
          type,
          name: place.name,
          latitude: place.latitude,
          longitude: place.longitude,
          direction: place.direction,
          direction_type: place.direction_type,
          road_name: place.road_name,
          parking_count: place.parking_count,
          has_toilet: type === 'DROWSY_AREA'    // 2. toilet 통일
            ? place.toilet_yn === 'Y'
            : place.toilet === 'Y',
          gas_station: place.gas_station === 'Y' ? true : false,
          ev_station: place.ev_station === 'Y' ? true : false,
          phone: place.phone ?? null,
          distance: Math.round(                  // 1. km 변환
            getDistance(userLocation, {
              latitude: place.latitude,
              longitude: place.longitude,
            }) / 100
          ) / 10,                                // 소수점 1자리 km
        }));
    };

    const allPlaces = [
      ...processPlaces(restAreas, 'DROWSY_AREA'),
      ...processPlaces(serviceStations, 'REST_AREA'),
    ];

    return allPlaces
      .sort((a, b) => a.distance - b.distance)
      .slice(0, limit);
  }
}
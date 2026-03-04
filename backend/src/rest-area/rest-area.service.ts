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

  /**
   * 사용자의 진행 방향 기준으로 전방에 있는 장소인지 판단
   * direction_type DB 값에 의존하지 않고 bearing으로 직접 계산
   * 순환도로 포함 모든 도로를 bearing 기반으로만 판단
   *
   * @param userBearing - Flutter에서 받은 이동 방향 (0~360도, 북쪽 기준 시계방향)
   * @param angleTolerance - 전방으로 인정할 각도 범위 (기본 90도 → 좌우 45도씩)
   */
  private isAhead(
    userLat: number,
    userLng: number,
    userBearing: number,
    placeLat: number,
    placeLng: number,
    angleTolerance: number = 90,
  ): boolean {
    const bearingToPlace = getRhumbLineBearing(
      { latitude: userLat, longitude: userLng },
      { latitude: placeLat, longitude: placeLng },
    );

    const diff = Math.abs(bearingToPlace - userBearing);
    const normalizedDiff = diff > 180 ? 360 - diff : diff;

    return normalizedDiff <= angleTolerance;
  }

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

          // bearing이 유효한 경우에만 방향 필터 적용
          // (bearing이 -1이거나 NaN이면 필터 스킵 → 정차 중 or GPS 불안정)
          // 순환도로 포함 모든 도로를 bearing 기반으로만 판단
          if (userBearing >= 0 && !isNaN(userBearing)) {
            return this.isAhead(
              userLat,
              userLng,
              userBearing,
              parseFloat(place.latitude),
              parseFloat(place.longitude),
            );
          }

          return true;
        })
        .map((place) => ({
          type,
          name: place.name,
          latitude: parseFloat(place.latitude),
          longitude: parseFloat(place.longitude),
          direction: place.direction,
          direction_type: place.direction_type,
          road_name: place.road_name,
          parking_count: place.parking_count,
          has_toilet:
            type === 'DROWSY_AREA'
              ? place.toilet_yn === 'Y'
              : place.toilet === 'Y',
          gas_station: place.gas_station === 'Y',
          ev_station: place.ev_station === 'Y',
          phone: place.phone ?? null,
          distance:
            Math.round(
              getDistance(userLocation, {
                latitude: place.latitude,
                longitude: place.longitude,
              }) / 100,
            ) / 10,
        }));
    };

    const allPlaces = [
      ...processPlaces(restAreas, 'DROWSY_AREA'),
      ...processPlaces(serviceStations, 'REST_AREA'),
    ];

    return allPlaces.sort((a, b) => a.distance - b.distance).slice(0, limit);
  }
}
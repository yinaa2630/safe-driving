import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { RestAreaService } from './rest-area.service';
import { RestArea } from './rest-area.entity';
import { ServiceStation } from '../service-station/service-station.entity';

// ════════════════════════════════════════════
// 가짜 DB 데이터
// ════════════════════════════════════════════

// ── 경부고속도로 (남북 방향) ──
const 경부_졸음쉼터: Partial<RestArea>[] = [
  {
    name: '안성졸음쉼터(상행)',
    latitude: 37.15,
    longitude: 127.2,
    direction: '상행',
    direction_type: 'UP',
    road_name: '경부고속도로',
    parking_count: 50,
    toilet_yn: 'Y',
  },
  {
    name: '천안졸음쉼터(하행)',
    latitude: 36.8,
    longitude: 127.1,
    direction: '하행',
    direction_type: 'DOWN',
    road_name: '경부고속도로',
    parking_count: 40,
    toilet_yn: 'Y',
  },
];

const 경부_휴게소: Partial<ServiceStation>[] = [
  {
    name: '죽전휴게소(상행)',
    latitude: 37.3,
    longitude: 127.1,
    direction: '상행',
    direction_type: 'UP',
    road_name: '경부고속도로',
    parking_count: 150,
    toilet: 'Y',
    gas_station: 'Y',
    ev_station: 'N',
    phone: '031-123-4567',
  },
  {
    name: '기흥휴게소(하행)',
    latitude: 37.27,
    longitude: 127.09,
    direction: '하행',
    direction_type: 'DOWN',
    road_name: '경부고속도로',
    parking_count: 120,
    toilet: 'Y',
    gas_station: 'Y',
    ev_station: 'Y',
    phone: '031-987-6543',
  },
];

// ── 서울외곽순환 (순환도로) ──
const 외곽순환_졸음쉼터: Partial<RestArea>[] = [
  {
    name: '성남졸음쉼터',
    latitude: 37.44,
    longitude: 127.13,
    direction: '퇴계원기점 + 구리종점',
    direction_type: 'UP',
    road_name: '서울외곽선',
    parking_count: 81,
    toilet_yn: 'Y',
  },
];

// ── 남해고속도로 (동서 방향) ──
const 남해_휴게소: Partial<ServiceStation>[] = [
  {
    name: '남해함안휴게소(상행)',
    latitude: 35.27,
    longitude: 128.4,
    direction: '상행',
    direction_type: 'UP',
    road_name: '남해고속도로',
    parking_count: 100,
    toilet: 'Y',
    gas_station: 'Y',
    ev_station: 'N',
    phone: null,
  },
  {
    name: '남해진영휴게소(하행)',
    latitude: 35.24,
    longitude: 128.72,
    direction: '하행',
    direction_type: 'DOWN',
    road_name: '남해고속도로',
    parking_count: 90,
    toilet: 'Y',
    gas_station: 'N',
    ev_station: 'N',
    phone: null,
  },
];

// ── 양방향 휴게소 ──
const 양방향_휴게소: Partial<ServiceStation>[] = [
  {
    name: '하남드림휴게소(양방향)',
    latitude: 37.53,
    longitude: 127.2,
    direction: '양방향',
    direction_type: 'BOTH',
    road_name: '중부고속도로',
    parking_count: 725,
    toilet: 'Y',
    gas_station: 'Y',
    ev_station: 'Y',
    phone: null,
  },
];

// ════════════════════════════════════════════
// 헬퍼: 원하는 mock 데이터로 service 생성
// ════════════════════════════════════════════
async function createService(
  restAreas: Partial<RestArea>[],
  serviceStations: Partial<ServiceStation>[],
): Promise<RestAreaService> {
  const module: TestingModule = await Test.createTestingModule({
    providers: [
      RestAreaService,
      {
        provide: getRepositoryToken(RestArea),
        useValue: { find: jest.fn().mockResolvedValue(restAreas) },
      },
      {
        provide: getRepositoryToken(ServiceStation),
        useValue: { find: jest.fn().mockResolvedValue(serviceStations) },
      },
    ],
  }).compile();

  return module.get<RestAreaService>(RestAreaService);
}

// ════════════════════════════════════════════
// 테스트
// ════════════════════════════════════════════
describe('RestAreaService', () => {

  // ──────────────────────────────────────────
  // 1. isAhead() - 방향 판단 단위 테스트
  // ──────────────────────────────────────────
  describe('isAhead()', () => {
    let service: RestAreaService;
    beforeEach(async () => { service = await createService([], []); });

    it('남쪽 이동(bearing=180) → 남쪽 장소 → true', () => {
      expect(service['isAhead'](37.5, 127.0, 180, 37.3, 127.0)).toBe(true);
    });

    it('남쪽 이동(bearing=180) → 북쪽 장소 → false', () => {
      expect(service['isAhead'](37.5, 127.0, 180, 37.7, 127.0)).toBe(false);
    });

    it('북쪽 이동(bearing=0) → 북쪽 장소 → true', () => {
      expect(service['isAhead'](37.0, 127.0, 0, 37.3, 127.0)).toBe(true);
    });

    it('북쪽 이동(bearing=0) → 남쪽 장소 → false', () => {
      expect(service['isAhead'](37.5, 127.0, 0, 37.2, 127.0)).toBe(false);
    });

    it('동쪽 이동(bearing=90) → 동쪽 장소 → true', () => {
      expect(service['isAhead'](37.0, 126.5, 90, 37.0, 127.0)).toBe(true);
    });

    it('동쪽 이동(bearing=90) → 서쪽 장소 → false', () => {
      expect(service['isAhead'](37.0, 127.0, 90, 37.0, 126.5)).toBe(false);
    });
  });

  // ──────────────────────────────────────────
  // 2. 경부고속도로 - 상행/하행 필터
  // ──────────────────────────────────────────
  describe('경부고속도로 상행/하행 필터', () => {
    let service: RestAreaService;
    beforeEach(async () => { service = await createService(경부_졸음쉼터, 경부_휴게소); });

    it('하행(bearing=180) → 사용자 남쪽 장소만 반환', async () => {
      const result = await service.findNearest(37.5, 127.1, 180, 5);
      expect(result.length).toBeGreaterThan(0);
      result.forEach((p) => expect(p.latitude).toBeLessThan(37.5));
    });

    it('상행(bearing=0) → 사용자 북쪽 장소만 반환', async () => {
      const result = await service.findNearest(36.5, 127.1, 0, 5);
      expect(result.length).toBeGreaterThan(0);
      result.forEach((p) => expect(p.latitude).toBeGreaterThan(36.5));
    });


  });

  // ──────────────────────────────────────────
  // 3. 서울외곽순환 - 순환도로 예외처리
  // ──────────────────────────────────────────
  describe('서울외곽순환 - 순환도로 예외처리', () => {
    let service: RestAreaService;
    beforeEach(async () => { service = await createService(외곽순환_졸음쉼터, []); });

    it('하행(bearing=180)이어도 순환도로 장소 포함', async () => {
      const result = await service.findNearest(37.5, 127.1, 180, 5);
      expect(result.find((p) => p.name === '성남졸음쉼터')).toBeDefined();
    });

    it('상행(bearing=0)이어도 순환도로 장소 포함', async () => {
      const result = await service.findNearest(37.5, 127.1, 0, 5);
      expect(result.find((p) => p.name === '성남졸음쉼터')).toBeDefined();
    });
  });

  // ──────────────────────────────────────────
  // 4. 남해고속도로 - 동서 방향 도로
  // ──────────────────────────────────────────
  describe('남해고속도로 - 동서 방향', () => {
    let service: RestAreaService;
    beforeEach(async () => { service = await createService([], 남해_휴게소); });

    it('동쪽 이동(bearing=90) → 동쪽 장소만 반환', async () => {
      const result = await service.findNearest(35.25, 128.5, 90, 5);
      result.forEach((p) => expect(p.longitude).toBeGreaterThan(128.5));
    });

    it('서쪽 이동(bearing=270) → 서쪽 장소만 반환', async () => {
      const result = await service.findNearest(35.25, 128.6, 270, 5);
      result.forEach((p) => expect(p.longitude).toBeLessThan(128.6));
    });
  });

  // ──────────────────────────────────────────
  // 5. 양방향 휴게소
  // ──────────────────────────────────────────
  describe('양방향 휴게소', () => {
    let service: RestAreaService;
    beforeEach(async () => { service = await createService([], 양방향_휴게소); });

    it('상행(bearing=0)이어도 양방향 휴게소 포함', async () => {
      const result = await service.findNearest(37.4, 127.2, 0, 5);
      expect(result.find((p) => p.name.includes('하남드림'))).toBeDefined();
    });

    it('하행(bearing=180)이어도 양방향 휴게소 포함', async () => {
      const result = await service.findNearest(37.6, 127.2, 180, 5);
      expect(result.find((p) => p.name.includes('하남드림'))).toBeDefined();
    });
  });

  // ──────────────────────────────────────────
  // 6. 정차 중 (bearing=-1)
  // ──────────────────────────────────────────
  describe('정차 중 (bearing=-1)', () => {
    let service: RestAreaService;
    beforeEach(async () => { service = await createService(경부_졸음쉼터, 경부_휴게소); });

    it('bearing=-1 → 방향 무관 전체 4개 반환', async () => {
      const result = await service.findNearest(37.5, 127.1, -1, 10);
      expect(result.length).toBe(4);
    });
  });

  // ──────────────────────────────────────────
  // 7. 공통 - 정렬 / limit / 필드 / 타입
  // ──────────────────────────────────────────
  describe('공통 동작', () => {
    let service: RestAreaService;
    beforeEach(async () => { service = await createService(경부_졸음쉼터, 경부_휴게소); });

    it('결과는 거리순 정렬', async () => {
      const result = await service.findNearest(37.5, 127.1, 180, 5);
      for (let i = 0; i < result.length - 1; i++) {
        expect(result[i].distance).toBeLessThanOrEqual(result[i + 1].distance);
      }
    });

    it('limit=1 → 최대 1개만 반환', async () => {
      const result = await service.findNearest(37.5, 127.1, 180, 1);
      expect(result.length).toBeLessThanOrEqual(1);
    });

    it('반환 데이터에 필수 필드 존재', async () => {
      const result = await service.findNearest(37.5, 127.1, -1, 5);
      result.forEach((p) => {
        expect(p).toHaveProperty('type');
        expect(p).toHaveProperty('name');
        expect(p).toHaveProperty('latitude');
        expect(p).toHaveProperty('longitude');
        expect(p).toHaveProperty('distance');
        expect(p).toHaveProperty('has_toilet');
        expect(p).toHaveProperty('gas_station');
        expect(p).toHaveProperty('ev_station');
        expect(p).toHaveProperty('direction_type');
        expect(p).toHaveProperty('road_name');
      });
    });

    it('latitude/longitude는 number 타입 (string 아님)', async () => {
      const result = await service.findNearest(37.5, 127.1, -1, 5);
      result.forEach((p) => {
        expect(typeof p.latitude).toBe('number');
        expect(typeof p.longitude).toBe('number');
      });
    });
  });
});
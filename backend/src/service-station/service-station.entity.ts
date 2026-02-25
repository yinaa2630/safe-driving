import { Entity, Column, PrimaryColumn } from 'typeorm';

@Entity('service_station')
export class ServiceStation {
  @PrimaryColumn()       // PrimaryGeneratedColumn → PrimaryColumn
  name: string;

  @Column({ nullable: true })
  road_type: string;

  @Column({ nullable: true })
  road_number: number;

  @Column({ nullable: true })
  road_name: string;

  @Column({ type: 'float4', nullable: true })
  latitude: number;

  @Column({ type: 'float4', nullable: true })
  longitude: number;

  @Column({ nullable: true })
  parking_count: number;

  @Column({ nullable: true })
  repair: string;

  @Column({ nullable: true })
  gas_station: string;

  @Column({ nullable: true })
  lpg_station: string;

  @Column({ nullable: true })
  ev_station: string;

  @Column({ nullable: true })
  bus_transfer: string;

  @Column({ nullable: true })
  rest_area: string;

  @Column({ nullable: true })
  toilet: string;

  @Column({ nullable: true })
  pharmacy: string;

  @Column({ nullable: true })
  nursing_room: string;

  @Column({ nullable: true })
  store: string;

  @Column({ nullable: true })
  restaurant: string;

  @Column({ nullable: true })
  facilities: string;

  @Column({ name: '휴게소대표음식명', nullable: true })
  representative_food: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ nullable: true })
  direction: string;

  @Column({ nullable: true })
  direction_type: string;
}
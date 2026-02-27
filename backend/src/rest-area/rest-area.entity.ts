import { Entity, Column, PrimaryGeneratedColumn } from 'typeorm';

@Entity('rest_area')
export class RestArea {
  @PrimaryGeneratedColumn()
  rest_area_id: number;

  @Column({ nullable: true })
  name: string;

  @Column({ nullable: true })
  sido: string;

  @Column({ nullable: true })
  sigungu: string;

  @Column({ nullable: true })
  road_type: string;

  @Column({ nullable: true })
  road_name: string;

  @Column({ nullable: true })
  road_number: number;

  @Column({ nullable: true })
  address: string;

  @Column({ type: 'float4', nullable: true })
  latitude: number;

  @Column({ type: 'float4', nullable: true })
  longitude: number;

  @Column({ nullable: true })
  parking_count: number;

  @Column({ nullable: true })
  toilet_yn: string;

  @Column({ nullable: true })
  direction: string;

  @Column({ nullable: true })
  direction_type: string;
}

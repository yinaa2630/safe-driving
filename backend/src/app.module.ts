import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';

import { AppController } from './app.controller';
import { AppService } from './app.service';

import { AuthModule } from './auth/auth.module';
import { DriveRecordModule } from './drive-record/drive-record.module';
import { ModelResultModule } from './model-result/model-result.module';
import { ServiceStationModule } from './service-station/service-station.module';
import { RestAreaModule } from './rest-area/rest-area.module';

import { User } from './user/user.entity';
import { DriveRecord } from './drive-record/drive-record.entity';
import { ModelResult } from './model-result/model-result.entity';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
    }),

    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT),
      username: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,

      entities: [User, DriveRecord, ModelResult], 

      synchronize: false, 
    }),

    AuthModule,
    DriveRecordModule,
    ModelResultModule,
    ServiceStationModule,
    RestAreaModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
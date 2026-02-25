import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';

import { AppController } from './app.controller';
import { AppService } from './app.service';
import { User } from './user/user.entity';
import { RestArea } from './rest-area/rest-area.entity';
import { ServiceStation } from './service-station/service-station.entity';
import { AuthModule } from './auth/auth.module';
import { RestAreaModule } from './rest-area/rest-area.module';
import { ServiceStationModule } from './service-station/service-station.module';

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
      entities: [User, RestArea, ServiceStation],
      synchronize: false,
    }),

    AuthModule,
    RestAreaModule,
    ServiceStationModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
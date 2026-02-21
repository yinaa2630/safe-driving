import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  console.log('🔥 MAIN.TS EXECUTING 🔥');

  const app = await NestFactory.create(AppModule);

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // validation 안될때 디버깅용!
  // console.log('🔥 VALIDATION PIPE REGISTERED 🔥');

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
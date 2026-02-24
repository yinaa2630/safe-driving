import {
  Controller,
  UseGuards,
  Get,
  Request,
  Body,
  Post,
} from '@nestjs/common';
import { JwtAuthGuard } from './jwt-auth.guard';
import { AuthService } from './auth.service';
import { CreateUserDto } from './dto/create-user.dto';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  // 로그인
  @Post('login')
  async login(
    @Body() body: { email: string; password: string },
  ) {
    return this.authService.login(body.email, body.password);
  }

  // 회원가입
  @Post('register')
  async register(@Body() createUserDto: CreateUserDto) {
    return this.authService.register(createUserDto);
  }

  // 내 정보 조회
  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getMe(@Request() req) {
    return this.authService.getProfile(req.user.userId);
  }
}
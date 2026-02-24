import {
  Injectable,
  BadRequestException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';

import { CreateUserDto } from './dto/create-user.dto';
import { User } from '../user/user.entity';

@Injectable()
export class AuthService {
  constructor(
    private jwtService: JwtService,

    @InjectRepository(User)
    private userRepository: Repository<User>,
  ) {}


  // 비밀번호 해시

  async hashPassword(password: string): Promise<string> {
    return bcrypt.hash(password, 10);
  }


  // 비밀번호 비교

  async comparePassword(password: string, hash: string): Promise<boolean> {
    return bcrypt.compare(password, hash);
  }


  // JWT 생성

  generateToken(payload: any): string {
    return this.jwtService.sign(payload);
  }


  // 회원가입

  async register(createUserDto: CreateUserDto) {
    const { email, password, username } = createUserDto;

    const existingUser = await this.userRepository.findOne({
      where: { email },
    });

    if (existingUser) {
      throw new BadRequestException('이미 존재하는 이메일입니다.');
    }

    const hashedPassword = await this.hashPassword(password);

    const user = this.userRepository.create({
      email,
      password: hashedPassword,
      username,
    });

    await this.userRepository.save(user);

    return { message: '회원가입 성공' };
  }


  // 로그인

  async login(email: string, password: string) {
    const user = await this.userRepository.findOne({
      where: { email },
    });

    if (!user) {
      throw new UnauthorizedException('존재하지 않는 이메일입니다.');
    }

    const isMatch = await this.comparePassword(password, user.password);

    if (!isMatch) {
      throw new UnauthorizedException('비밀번호가 틀렸습니다.');
    }

    const payload = { userId: user.id };

    return {
      accessToken: this.generateToken(payload),
    };
  }

  // 내 정보 조회 (추가된 부분)
  async getProfile(userId: number) {
    const user = await this.userRepository.findOne({
      where: { id: userId },
      select: ['id', 'email', 'username'], // password 제외
    });

    if (!user) {
      throw new UnauthorizedException('사용자를 찾을 수 없습니다.');
    }

    return user;
  }
}
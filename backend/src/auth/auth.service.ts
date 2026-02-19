import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AuthService {
    constructor(private jwtService: JwtService) {}

    // 비밀번호 해시 (for 회원가입)
    async hashPassword(password: string): Promise<string> {
        return bcrypt.hash(password, 10);
    }

    // 비밀번호 비교 (for 로그인)
    async comparePassword(password: string, hash: string): Promise<boolean> {
        return bcrypt.compare(password, hash);
    }

    // 토큰
    generateToken(payload: any): string {
        return this.jwtService.sign(payload);
    }
}

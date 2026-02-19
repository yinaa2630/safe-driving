import { Controller, UseGuards, Get, Request, Body, Post } from "@nestjs/common";
import { JwtAuthGuard } from "./jwt-auth.guard";
import { AuthService } from "./auth.service";

@Controller('auth')
export class AuthController {
    constructor(private authService: AuthService) {}

    @Post('login')
    login(@Body() body: {userId:number}) {
        const token = this.authService.generateToken({
            userId: body.userId,
        });
        return { accessToken: token };
    }

    @UseGuards(JwtAuthGuard)
    @Get('me')
    getProtected(@Request() req) {
        return {
            message: 'Protected route accessed',
            user: req.user,
        };
    }
}


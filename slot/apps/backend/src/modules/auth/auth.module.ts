import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { User, CustomerProfile, Salon, SalonUser, Seat, RefreshToken } from '../../entities';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './jwt.strategy';

@Module({
  imports: [
    TypeOrmModule.forFeature([User, CustomerProfile, Salon, SalonUser, Seat, RefreshToken]),
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (configService?: ConfigService) => {
        const secret =
          configService?.get<string>('JWT_SECRET') ||
          process.env.JWT_SECRET ||
          'super_secret_slot_jwt_key_2026_production_safe_default_long_key';
        return {
          secret,
          signOptions: {
            expiresIn: (configService?.get<string>('JWT_EXPIRATION') || process.env.JWT_EXPIRATION || '15m') as any,
          },
        };
      },
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy],
  exports: [AuthService, JwtModule, PassportModule],
})
export class AuthModule {}

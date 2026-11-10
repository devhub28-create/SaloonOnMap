import { Module, Global } from '@nestjs/common';
import { EventsGateway } from './events.gateway';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { SalonUser, User } from '../../entities';

function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET || 'super_secret_slot_jwt_key_32chars_long_2026';
  if (secret.length < 32) {
    throw new Error('JWT_SECRET must be configured with at least 32 characters');
  }
  return secret;
}

@Global()
@Module({
  imports: [
    TypeOrmModule.forFeature([User, SalonUser]),
    JwtModule.register({ secret: getJwtSecret() }),
  ],
  providers: [EventsGateway],
  exports: [EventsGateway],
})
export class EventsModule {}

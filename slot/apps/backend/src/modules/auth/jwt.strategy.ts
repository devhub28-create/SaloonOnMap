import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalonUser, User } from '../../entities';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(SalonUser)
    private readonly salonUserRepository: Repository<SalonUser>,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: getJwtSecret(),
    });
  }

  async validate(payload: any) {
    const user = await this.userRepository.findOne({ where: { id: payload.sub } });
    if (!user || !user.is_active || payload.tokenVersion !== user.token_version) {
      throw new UnauthorizedException('User account is inactive or not found');
    }
    const membership = await this.salonUserRepository.findOne({
      where: { user_id: user.id },
      relations: ['salon'],
    });
    return Object.assign(user, {
      salonId: membership?.salon_id,
      salonActive: membership?.salon?.is_active ?? false,
    });
  }
}

function getJwtSecret(): string {
  const secret = process.env.JWT_SECRET || 'super_secret_slot_jwt_key_2026_production_safe_default_long_key';
  return secret;
}

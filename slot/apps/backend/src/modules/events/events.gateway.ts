import { WebSocketGateway, WebSocketServer, OnGatewayConnection, OnGatewayDisconnect } from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SalonUser, User } from '../../entities';

const socketOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

@WebSocketGateway({ cors: { origin: socketOrigins.length ? socketOrigins : false } })
export class EventsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(EventsGateway.name);

  constructor(
    private readonly jwtService: JwtService,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(SalonUser)
    private readonly salonUserRepository: Repository<SalonUser>,
  ) {}

  async handleConnection(client: Socket) {
    try {
      const authorization = client.handshake.headers.authorization;
      const token =
        client.handshake.auth?.token ||
        (authorization?.startsWith('Bearer ') ? authorization.slice(7) : null);
      if (!token) throw new Error('Missing token');

      const payload = await this.jwtService.verifyAsync(token);
      const user = await this.userRepository.findOne({ where: { id: payload.sub } });
      if (!user || !user.is_active || user.token_version !== payload.tokenVersion) {
        throw new Error('Invalid session');
      }

      const membership = await this.salonUserRepository.findOne({
        where: { user_id: user.id },
        relations: ['salon'],
      });
      if (!membership?.salon?.is_active) throw new Error('Inactive salon');

      client.data.userId = user.id;
      client.data.salonId = membership.salon_id;
      await client.join(`salon:${membership.salon_id}`);
      this.logger.log('Authenticated salon socket connected');
    } catch {
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket) {
    this.logger.log('Salon socket disconnected');
  }

  notifyBookingCreated(salonId: string, booking: any) {
    this.server.to(`salon:${salonId}`).emit('booking.created', {
      salonId,
      booking: {
        id: booking.id,
        referenceCode: booking.reference_code,
        seatId: booking.seat_id,
        staffId: booking.staff_id,
        startAt: booking.start_at,
        endAt: booking.end_at,
        status: booking.status,
        totalAmount: booking.total_amount,
      },
    });
  }

  notifySeatUpdated(salonId: string, seat: any) {
    this.server?.to(`salon:${salonId}`).emit('seat.updated', { salonId, seat });
  }

  notifyBookingUpdated(salonId: string, booking: any) {
    this.server?.to(`salon:${salonId}`).emit('booking.updated', {
      salonId,
      booking: {
        id: booking.id,
        referenceCode: booking.reference_code,
        seatId: booking.seat_id,
        staffId: booking.staff_id,
        startAt: booking.start_at,
        endAt: booking.end_at,
        status: booking.status,
        totalAmount: booking.total_amount,
      },
    });
  }
}

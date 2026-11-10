import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { getDatabaseConfig } from './config/database.config';
import { HealthModule } from './modules/health/health.module';
import { EventsModule } from './modules/events/events.module';
import { AuthModule } from './modules/auth/auth.module';
import { SalonsModule } from './modules/salons/salons.module';
import { SeatsModule } from './modules/seats/seats.module';
import { StaffModule } from './modules/staff/staff.module';
import { BookingHoldsModule } from './modules/booking-holds/booking-holds.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { PartnerModule } from './modules/partner/partner.module';
import { AdminModule } from './modules/admin/admin.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { AiStyleModule } from './modules/ai-style/ai-style.module';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([{ ttl: 60000, limit: 120 }]),
    TypeOrmModule.forRootAsync({
      useFactory: getDatabaseConfig,
    }),
    HealthModule,
    EventsModule,
    AuthModule,
    SalonsModule,
    SeatsModule,
    StaffModule,
    BookingHoldsModule,
    BookingsModule,
    PartnerModule,
    AdminModule,
    NotificationsModule,
    ReviewsModule,
    AiStyleModule,
  ],
  providers: [{ provide: APP_GUARD, useClass: ThrottlerGuard }],
})
export class AppModule {}

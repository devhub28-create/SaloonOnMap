import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BookingHold, Seat } from '../../entities';
import { BookingHoldsService } from './booking-holds.service';
import { BookingHoldsController } from './booking-holds.controller';

@Module({
  imports: [TypeOrmModule.forFeature([BookingHold, Seat])],
  controllers: [BookingHoldsController],
  providers: [BookingHoldsService],
  exports: [BookingHoldsService],
})
export class BookingHoldsModule {}

import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import {
  Booking,
  BookingHold,
  Seat,
  BookingService as BookingServiceEntity,
  BookingStatusHistory,
} from "../../entities";
import { BookingsService } from "./bookings.service";
import { BookingsController } from "./bookings.controller";
import { BookingHoldsModule } from "../booking-holds/booking-holds.module";
import { NotificationsModule } from "../notifications/notifications.module";

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Booking,
      BookingHold,
      Seat,
      BookingServiceEntity,
      BookingStatusHistory,
    ]),
    BookingHoldsModule,
    NotificationsModule,
  ],
  controllers: [BookingsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}

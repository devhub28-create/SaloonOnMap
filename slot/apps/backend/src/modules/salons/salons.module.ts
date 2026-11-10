import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import {
  Salon,
  SalonService,
  Combo,
  Booking,
  Seat,
  Staff,
  Offer,
  BookingHold,
} from "../../entities";
import { SalonsService } from "./salons.service";
import { SalonsController } from "./salons.controller";

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Salon,
      SalonService,
      Combo,
      Booking,
      Seat,
      Staff,
      Offer,
      BookingHold,
    ]),
  ],
  controllers: [SalonsController],
  providers: [SalonsService],
  exports: [SalonsService],
})
export class SalonsModule {}

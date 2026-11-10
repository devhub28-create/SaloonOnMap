import { Controller, Post, Body, UseGuards, Request } from "@nestjs/common";
import { ApiTags, ApiOperation } from "@nestjs/swagger";
import { BookingHoldsService, CreateHoldDto } from "./booking-holds.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";

@ApiTags("Booking Holds")
@Controller("bookings/holds")
export class BookingHoldsController {
  constructor(private readonly bookingHoldsService: BookingHoldsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: "Create temporary 5-minute seat hold" })
  async createHold(@Body() dto: CreateHoldDto, @Request() req: any) {
    return this.bookingHoldsService.createHold({
      ...dto,
      customerId: req.user.id,
    });
  }
}

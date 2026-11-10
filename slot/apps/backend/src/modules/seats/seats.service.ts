import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Seat, SeatStatus, Booking } from "../../entities";
import { EventsGateway } from "../events/events.gateway";

@Injectable()
export class SeatsService {
  constructor(
    @InjectRepository(Seat)
    private readonly seatRepository: Repository<Seat>,
    @InjectRepository(Booking)
    private readonly bookingRepository: Repository<Booking>,
    private readonly eventsGateway: EventsGateway,
  ) {}

  async getSalonSeats(salonId: string) {
    if (!salonId) {
      return [];
    }
    return this.seatRepository.find({
      where: { salon_id: salonId, is_active: true },
      order: { seat_number: "ASC" },
    });
  }

  async updateSeatStatus(seatId: string, status: SeatStatus, salonId?: string) {
    const seat = await this.seatRepository.findOne({
      where: salonId ? { id: seatId, salon_id: salonId } : { id: seatId },
    });
    if (!seat) {
      throw new NotFoundException(`Seat with ID ${seatId} not found`);
    }
    seat.status = status;
    const updated = await this.seatRepository.save(seat);

    // Broadcast seat update
    this.eventsGateway.notifySeatUpdated(seat.salon_id, updated);
    return updated;
  }

  async setSeatCount(salonId: string, seatCount: number) {
    if (!salonId || seatCount < 1) {
      return this.getSalonSeats(salonId);
    }

    const seats = await this.seatRepository.find({
      where: { salon_id: salonId },
      order: { seat_number: "ASC" },
    });
    const activeSeats = seats.filter((seat) => seat.is_active);

    if (seatCount > activeSeats.length) {
      const maxSeatNumber = seats.reduce(
        (max, seat) => Math.max(max, seat.seat_number),
        0,
      );
      const newSeats: Seat[] = [];
      for (let i = activeSeats.length + 1; i <= seatCount; i++) {
        const seatNumber = maxSeatNumber + (i - activeSeats.length);
        newSeats.push(
          this.seatRepository.create({
            salon_id: salonId,
            seat_number: seatNumber,
            label: `Chair ${seatNumber}`,
            status: SeatStatus.AVAILABLE,
            is_active: true,
          }),
        );
      }
      await this.seatRepository.save(newSeats);
    } else if (seatCount < activeSeats.length) {
      const seatsToDeactivate = activeSeats.slice(seatCount);
      for (const seat of seatsToDeactivate) {
        seat.is_active = false;
      }
      await this.seatRepository.save(seatsToDeactivate);
    }

    const updatedSeats = await this.getSalonSeats(salonId);
    this.eventsGateway.notifySeatUpdated(salonId, updatedSeats);
    return updatedSeats;
  }

}

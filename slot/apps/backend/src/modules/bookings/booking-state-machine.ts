import { BadRequestException } from '@nestjs/common';
import { BookingStatus } from '../../entities';

export class BookingStateMachine {
  private static allowedTransitions: Record<BookingStatus, BookingStatus[]> = {
    [BookingStatus.CONFIRMED]: [BookingStatus.WAITING, BookingStatus.IN_SERVICE, BookingStatus.DONE, BookingStatus.CANCELLED],
    [BookingStatus.WAITING]: [BookingStatus.IN_SERVICE, BookingStatus.DONE, BookingStatus.CANCELLED],
    [BookingStatus.IN_SERVICE]: [BookingStatus.DONE, BookingStatus.CANCELLED],
    [BookingStatus.DONE]: [],
    [BookingStatus.CANCELLED]: [],
  };

  static validateTransition(fromStatus: BookingStatus, toStatus: BookingStatus): void {
    if (fromStatus === toStatus) return;
    const allowed = this.allowedTransitions[fromStatus] || [];
    if (!allowed.includes(toStatus)) {
      throw new BadRequestException({
        code: 'INVALID_STATUS_TRANSITION',
        message: `Cannot transition booking status from ${fromStatus} to ${toStatus}.`,
      });
    }
  }
}

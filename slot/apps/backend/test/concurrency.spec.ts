import { Test, TestingModule } from "@nestjs/testing";
import { BookingHoldsService } from "../src/modules/booking-holds/booking-holds.service";
import { DataSource } from "typeorm";
import { ConflictException } from "@nestjs/common";

describe("Concurrency & Double Booking Protection Test", () => {
  let holdsService: BookingHoldsService;
  let activeHoldsCount = 0;

  beforeEach(async () => {
    activeHoldsCount = 0;

    const mockQueryRunner = {
      connect: jest.fn().mockResolvedValue(true),
      startTransaction: jest.fn().mockResolvedValue(true),
      commitTransaction: jest.fn().mockResolvedValue(true),
      rollbackTransaction: jest.fn().mockResolvedValue(true),
      release: jest.fn().mockResolvedValue(true),
      manager: {
        createQueryBuilder: jest.fn().mockReturnValue({
          setLock: jest.fn().mockReturnThis(),
          where: jest.fn().mockReturnThis(),
          andWhere: jest.fn().mockReturnThis(),
          getOne: jest.fn().mockResolvedValue({
            id: "00000000-0000-4000-8000-000000000004",
            salon_id: "00000000-0000-4000-8000-000000000001",
            seat_number: 4,
          }),
          getCount: jest.fn().mockImplementation(() => {
            // Atomic check: if activeHoldsCount > 0, conflict!
            return Promise.resolve(activeHoldsCount);
          }),
        }),
        create: jest.fn().mockImplementation((entity, dto) => dto),
        save: jest.fn().mockImplementation((entity, obj) => {
          activeHoldsCount++;
          return Promise.resolve({
            id: "hold-uuid-123",
            expires_at: new Date(Date.now() + 300000),
            status: "ACTIVE",
            ...obj,
          });
        }),
      },
    };

    const mockDataSource = {
      createQueryRunner: jest.fn().mockReturnValue(mockQueryRunner),
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      providers: [
        BookingHoldsService,
        {
          provide: DataSource,
          useValue: mockDataSource,
        },
      ],
    }).compile();

    holdsService = moduleFixture.get<BookingHoldsService>(BookingHoldsService);
  });

  it("should prevent double booking when Customer A and B attempt concurrent holds on Seat 04", async () => {
    const holdDtoA = {
      customerId: "00000000-0000-4000-8000-00000000000a",
      salonId: "00000000-0000-4000-8000-000000000001",
      seatId: "00000000-0000-4000-8000-000000000004",
      startAt: "2026-09-28T16:15:00.000Z",
      endAt: "2026-09-28T17:00:00.000Z",
      serviceIds: ["00000000-0000-4000-8000-000000000010"],
      totalPrice: 648,
      totalDuration: 45,
    };

    const holdDtoB = {
      customerId: "00000000-0000-4000-8000-00000000000b",
      salonId: "00000000-0000-4000-8000-000000000001",
      seatId: "00000000-0000-4000-8000-000000000004",
      startAt: "2026-09-28T16:15:00.000Z",
      endAt: "2026-09-28T17:00:00.000Z",
      serviceIds: ["00000000-0000-4000-8000-000000000010"],
      totalPrice: 648,
      totalDuration: 45,
    };

    const resultA = await holdsService.createHold(holdDtoA);
    expect(resultA.holdId).toBeDefined();

    // Second overlapping request must throw ConflictException (409 BOOKING_SLOT_UNAVAILABLE)
    await expect(holdsService.createHold(holdDtoB)).rejects.toThrow(
      ConflictException,
    );
  });
});

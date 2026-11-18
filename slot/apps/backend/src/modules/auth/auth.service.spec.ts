import {
  ServiceUnavailableException,
  UnauthorizedException,
} from "@nestjs/common";
import { AuthService } from "./auth.service";

describe("AuthService OTP security", () => {
  const queryBuilder = {
    where: jest.fn().mockReturnThis(),
    getOne: jest.fn(),
  };
  const userRepository = {
    findOne: jest.fn(),
    createQueryBuilder: jest.fn(() => queryBuilder),
    save: jest.fn(async (user) => user),
  };
  const profileRepository = {};
  const salonRepository = {};
  const salonUserRepository = { findOne: jest.fn() };
  const seatRepository = {};
  const refreshTokenRepository = { update: jest.fn() };
  const jwtService = {};

  let service: AuthService;
  const originalNodeEnv = process.env.NODE_ENV;
  const originalOtpProvider = process.env.OTP_PROVIDER;
  const originalVercel = process.env.VERCEL;

  beforeEach(() => {
    jest.clearAllMocks();
    process.env.NODE_ENV = "test";
    process.env.OTP_PROVIDER = "development";
    delete process.env.VERCEL;
    queryBuilder.where.mockReturnThis();
    queryBuilder.getOne.mockResolvedValue(null);
    service = new AuthService(
      userRepository as any,
      profileRepository as any,
      salonRepository as any,
      salonUserRepository as any,
      seatRepository as any,
      refreshTokenRepository as any,
      jwtService as any,
    );
  });

  afterAll(() => {
    if (originalNodeEnv === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = originalNodeEnv;
    if (originalOtpProvider === undefined) delete process.env.OTP_PROVIDER;
    else process.env.OTP_PROVIDER = originalOtpProvider;
    if (originalVercel === undefined) delete process.env.VERCEL;
    else process.env.VERCEL = originalVercel;
  });

  it("rejects an incorrect OTP before looking up or creating a user", async () => {
    await service.requestOtp("9876543210");

    await expect(
      service.verifyOtp("9876543210", "123456"),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect(userRepository.findOne).not.toHaveBeenCalled();
  });

  it("rejects an expired OTP", async () => {
    await service.requestOtp("9876543210");
    const record = (service as any).otpStore.get("+919876543210");
    record.expiresAt = Date.now() - 1;

    await expect(service.verifyOtp("9876543210", "000000")).rejects.toThrow(
      "OTP has expired",
    );
    expect(userRepository.findOne).not.toHaveBeenCalled();
  });

  it("enforces the OTP resend cooldown", async () => {
    await service.requestOtp("9876543210");

    await expect(service.requestOtp("9876543210")).rejects.toMatchObject({
      status: 429,
    });
  });

  it("refuses the development OTP provider in production", async () => {
    process.env.NODE_ENV = "production";

    await expect(service.requestOtp("9876543210")).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );
  });

  it("resets a partner password only after a valid OTP and revokes sessions", async () => {
    const partner = {
      id: "partner-1",
      phone: "+919876543210",
      password_hash: "old-hash",
      token_version: 2,
    };
    queryBuilder.getOne.mockResolvedValue(partner);
    salonUserRepository.findOne.mockResolvedValue({
      user_id: partner.id,
      salon_id: "salon-1",
    });
    refreshTokenRepository.update.mockResolvedValue({ affected: 1 });

    await service.requestPartnerPasswordReset("partner@example.com");
    await service.resetPartnerPassword(
      "partner@example.com",
      "000000",
      "NewSecurePassword123",
    );

    expect(userRepository.save).toHaveBeenCalledWith(
      expect.objectContaining({ token_version: 3 }),
    );
    expect(refreshTokenRepository.update).toHaveBeenCalled();
    expect(partner.password_hash).not.toBe("old-hash");
  });

  it("does not reveal whether a partner reset account exists", async () => {
    queryBuilder.getOne.mockResolvedValue(null);

    await expect(
      service.requestPartnerPasswordReset("unknown@example.com"),
    ).resolves.toEqual(
      expect.objectContaining({
        message: expect.stringContaining("If a partner"),
      }),
    );
  });
});

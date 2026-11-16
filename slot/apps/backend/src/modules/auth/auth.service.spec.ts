import {
  ServiceUnavailableException,
  UnauthorizedException,
} from "@nestjs/common";
import { AuthService } from "./auth.service";

describe("AuthService OTP security", () => {
  const userRepository = { findOne: jest.fn() };
  const profileRepository = {};
  const salonRepository = {};
  const salonUserRepository = {};
  const seatRepository = {};
  const refreshTokenRepository = {};
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
});

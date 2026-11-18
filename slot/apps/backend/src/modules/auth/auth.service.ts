import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  ConflictException,
  HttpException,
  HttpStatus,
  OnModuleDestroy,
  ServiceUnavailableException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { InjectRepository } from "@nestjs/typeorm";
import { IsNull, Repository } from "typeorm";
import * as bcrypt from "bcrypt";
import {
  IsArray,
  IsEmail,
  IsInt,
  IsOptional,
  IsString,
  Length,
  Max,
  Min,
  MinLength,
} from "class-validator";
import {
  User,
  UserRole,
  CustomerProfile,
  Salon,
  SalonUser,
  Seat,
  SeatStatus,
  RefreshToken,
  SalonStatus,
} from "../../entities";
import { OtpProviderFactory, normalizePhoneNumber } from "./otp-provider";
import Redis from "ioredis";
import { createHash, randomBytes, randomInt, timingSafeEqual } from "crypto";

interface OtpRecord {
  code: string;
  expiresAt: number;
  attempts: number;
  lastSentAt: number;
}

export class RegisterPartnerDto {
  @IsString()
  @MinLength(2)
  ownerName: string;
  @IsString()
  @Length(10, 18)
  phone: string;
  @IsEmail()
  email: string;
  @IsString()
  @MinLength(10)
  password: string;
  @IsString()
  @MinLength(2)
  salonName: string;
  @IsString()
  targetGender: string;
  @IsOptional()
  @IsString()
  city?: string;
  @IsOptional()
  @IsString()
  area?: string;
  @IsOptional()
  @IsString()
  address?: string;
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(100)
  seatCount?: number;
  @IsOptional()
  @IsString()
  coverImage?: string;
  @IsOptional()
  @IsArray()
  images?: string[];
}

export class LoginPartnerDto {
  @IsString()
  @MinLength(3)
  phoneOrEmail: string;
  @IsString()
  @MinLength(10)
  password: string;
}

export class LoginAdminDto {
  @IsEmail()
  email: string;
  @IsString()
  @MinLength(6)
  password: string;
}

@Injectable()
export class AuthService implements OnModuleDestroy {
  private otpProvider = OtpProviderFactory.getProvider();
  private otpStore = new Map<string, OtpRecord>();
  private readonly redis?: Redis;

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(CustomerProfile)
    private readonly profileRepository: Repository<CustomerProfile>,
    @InjectRepository(Salon)
    private readonly salonRepository: Repository<Salon>,
    @InjectRepository(SalonUser)
    private readonly salonUserRepository: Repository<SalonUser>,
    @InjectRepository(Seat)
    private readonly seatRepository: Repository<Seat>,
    @InjectRepository(RefreshToken)
    private readonly refreshTokenRepository: Repository<RefreshToken>,
    private readonly jwtService: JwtService,
  ) {
    if (process.env.REDIS_URL) {
      this.redis = new Redis(process.env.REDIS_URL, {
        lazyConnect: true,
        maxRetriesPerRequest: 2,
        enableReadyCheck: true,
      });
    } else if (process.env.NODE_ENV === "production") {
      console.warn(
        "[AuthService] REDIS_URL not configured; using resilient in-memory OTP store.",
      );
    }
  }

  async onModuleDestroy() {
    if (this.redis && this.redis.status !== "end") await this.redis.quit();
  }

  private otpKey(phone: string) {
    return `otp:${createHash("sha256").update(phone).digest("hex")}`;
  }

  private async getOtp(phone: string): Promise<OtpRecord | undefined> {
    if (!this.redis) return this.otpStore.get(phone);
    if (this.redis.status === "wait") await this.redis.connect();
    const value = await this.redis.get(this.otpKey(phone));
    return value ? JSON.parse(value) : undefined;
  }

  private async setOtp(phone: string, record: OtpRecord) {
    if (!this.redis) {
      this.otpStore.set(phone, record);
      return;
    }
    if (this.redis.status === "wait") await this.redis.connect();
    const ttlSeconds = Math.max(
      1,
      Math.ceil((record.expiresAt - Date.now()) / 1000),
    );
    await this.redis.set(
      this.otpKey(phone),
      JSON.stringify(record),
      "EX",
      ttlSeconds,
    );
  }

  private async deleteOtp(phone: string) {
    if (!this.redis) this.otpStore.delete(phone);
    else await this.redis.del(this.otpKey(phone));
  }

  private async issueSession(user: User, salonId?: string) {
    const accessToken = this.jwtService.sign({
      sub: user.id,
      phone: user.phone,
      role: user.role,
      salonId,
      tokenVersion: user.token_version,
    });
    const refreshToken = randomBytes(48).toString("base64url");
    const tokenHash = createHash("sha256").update(refreshToken).digest("hex");
    const days = Math.min(
      Math.max(Number(process.env.REFRESH_TOKEN_DAYS || 30), 1),
      90,
    );
    await this.refreshTokenRepository.save(
      this.refreshTokenRepository.create({
        user_id: user.id,
        token_hash: tokenHash,
        expires_at: new Date(Date.now() + days * 86400000),
      }),
    );
    return { accessToken, refreshToken };
  }

  async refreshSession(rawToken: string) {
    const tokenHash = createHash("sha256").update(rawToken).digest("hex");
    const stored = await this.refreshTokenRepository.findOne({
      where: { token_hash: tokenHash },
      relations: ["user"],
    });
    if (
      !stored ||
      stored.revoked_at ||
      stored.expires_at.getTime() <= Date.now() ||
      !stored.user?.is_active
    ) {
      throw new UnauthorizedException("Refresh token is invalid or expired.");
    }
    const result = await this.refreshTokenRepository.update(
      { id: stored.id, revoked_at: IsNull() },
      { revoked_at: new Date() },
    );
    if (result.affected !== 1)
      throw new UnauthorizedException("Refresh token has already been used.");
    const membership = await this.salonUserRepository.findOne({
      where: { user_id: stored.user_id },
      relations: ["salon"],
    });
    if (membership && !membership.salon?.is_active)
      throw new UnauthorizedException("Salon account is pending or inactive.");
    return this.issueSession(stored.user, membership?.salon_id);
  }

  async requestOtp(
    phone: string,
  ): Promise<{ message: string; cooldownSeconds: number }> {
    const normalized = normalizePhoneNumber(phone);
    const now = Date.now();
    const existing = await this.getOtp(normalized);
    const cooldownMs = 30_000;
    if (existing && now - existing.lastSentAt < cooldownMs) {
      const retryAfter = Math.ceil(
        (cooldownMs - (now - existing.lastSentAt)) / 1000,
      );
      throw new HttpException(
        `Please wait ${retryAfter} seconds before requesting another OTP.`,
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    const providerType = (
      process.env.OTP_PROVIDER || "development"
    ).toLowerCase();
    const isDevelopmentProvider = providerType === "development";
    const isProduction =
      process.env.NODE_ENV === "production" || !!process.env.VERCEL;
    if (isProduction && isDevelopmentProvider) {
      throw new ServiceUnavailableException(
        "OTP delivery is not configured. Please contact support.",
      );
    }

    const code = isDevelopmentProvider
      ? process.env.DEV_DEFAULT_OTP || "000000"
      : randomInt(100000, 1000000).toString();
    const expiresAt = now + 15 * 60 * 1000;

    try {
      const sent = await this.otpProvider.sendOtp({
        phoneNumber: normalized,
        otp: code,
        expiresAt: new Date(expiresAt),
      });
      if (!sent) {
        throw new Error("OTP provider rejected the request");
      }
    } catch {
      throw new ServiceUnavailableException(
        "We could not send an OTP right now. Please try again shortly.",
      );
    }

    await this.setOtp(normalized, {
      code,
      expiresAt,
      attempts: 0,
      lastSentAt: now,
    });

    return {
      message: "OTP sent successfully.",
      cooldownSeconds: cooldownMs / 1000,
    };
  }

  async verifyOtp(
    phone: string,
    code?: string,
    name?: string,
    email?: string,
  ): Promise<{ accessToken: string; refreshToken: string; user: any }> {
    const normalized = normalizePhoneNumber(phone);
    await this.validateOtp(normalized, code);

    let user = await this.userRepository.findOne({
      where: { phone: normalized },
    });
    if (!user) {
      user = await this.userRepository.save(
        this.userRepository.create({
          phone: normalized,
          name: name?.trim() || "Customer User",
          email: email?.trim() || undefined,
          role: UserRole.CUSTOMER,
        }),
      );
      if (user.role === UserRole.CUSTOMER) {
        await this.profileRepository.save(
          this.profileRepository.create({ user_id: user.id }),
        );
      }
    } else {
      let needsSave = false;
      if (
        name?.trim() &&
        (!user.name ||
          user.name === "Guest User" ||
          user.name === "Customer User")
      ) {
        user.name = name.trim();
        needsSave = true;
      }
      if (email?.trim() && !user.email) {
        user.email = email.trim();
        needsSave = true;
      }
      if (needsSave) {
        await this.userRepository.save(user);
      }
    }

    if (!user.is_active) {
      throw new UnauthorizedException("User account is inactive.");
    }
    const session = await this.issueSession(user);

    return {
      ...session,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        role: user.role,
      },
    };
  }

  private async validateOtp(normalized: string, code?: string): Promise<void> {
    const record = await this.getOtp(normalized);
    if (!record) {
      throw new UnauthorizedException(
        "OTP is invalid or has expired. Request a new code.",
      );
    }
    if (record.expiresAt <= Date.now()) {
      await this.deleteOtp(normalized);
      throw new UnauthorizedException("OTP has expired. Request a new code.");
    }
    if (record.attempts >= 5) {
      await this.deleteOtp(normalized);
      throw new UnauthorizedException(
        "Too many incorrect attempts. Request a new code.",
      );
    }

    const submittedCode = (code || "").trim();
    const providerType = (
      process.env.OTP_PROVIDER || "development"
    ).toLowerCase();
    let isValid = false;
    if (providerType === "development") {
      const expected = Buffer.from(record.code);
      const submitted = Buffer.from(submittedCode);
      isValid =
        expected.length === submitted.length &&
        timingSafeEqual(expected, submitted);
    } else {
      try {
        isValid = await this.otpProvider.verifyOtp(normalized, submittedCode);
      } catch {
        throw new ServiceUnavailableException(
          "OTP verification is temporarily unavailable. Please try again.",
        );
      }
    }

    if (!isValid) {
      record.attempts += 1;
      if (record.attempts >= 5) await this.deleteOtp(normalized);
      else await this.setOtp(normalized, record);
      throw new UnauthorizedException("The OTP is invalid.");
    }
    await this.deleteOtp(normalized);
  }

  private async findPartnerForReset(
    phoneOrEmail: string,
  ): Promise<User | null> {
    const input = phoneOrEmail.trim();
    const user = input.includes("@")
      ? await this.userRepository
          .createQueryBuilder("user")
          .where("LOWER(user.email) = :email", { email: input.toLowerCase() })
          .getOne()
      : await this.userRepository
          .createQueryBuilder("user")
          .where("user.phone = :phone", {
            phone: normalizePhoneNumber(input),
          })
          .getOne();
    if (!user) return null;
    const membership = await this.salonUserRepository.findOne({
      where: { user_id: user.id },
    });
    return membership ? user : null;
  }

  async requestPartnerPasswordReset(phoneOrEmail: string) {
    const user = await this.findPartnerForReset(phoneOrEmail);
    if (user?.phone) await this.requestOtp(user.phone);
    return {
      message:
        "If a partner account matches those details, a verification code has been sent to its registered phone.",
    };
  }

  async resetPartnerPassword(
    phoneOrEmail: string,
    code: string,
    newPassword: string,
  ) {
    const user = await this.findPartnerForReset(phoneOrEmail);
    if (!user) throw new UnauthorizedException("The reset code is invalid.");
    await this.validateOtp(normalizePhoneNumber(user.phone), code);
    user.password_hash = await bcrypt.hash(newPassword, 12);
    user.token_version += 1;
    await this.userRepository.save(user);
    await this.refreshTokenRepository.update(
      { user_id: user.id, revoked_at: IsNull() },
      { revoked_at: new Date() },
    );
    return { message: "Password updated. Sign in with your new password." };
  }

  async loginAdmin(
    dto: LoginAdminDto,
  ): Promise<{ accessToken: string; refreshToken: string; user: any }> {
    const isProduction =
      process.env.NODE_ENV === "production" || !!process.env.VERCEL;
    const configuredEmail = (process.env.ADMIN_EMAIL || "admin@slot.com")
      .trim()
      .toLowerCase();
    const configuredPasswordHash = process.env.ADMIN_PASSWORD_HASH;
    const configuredPassword = process.env.ADMIN_PASSWORD;
    const configuredPhone = (process.env.ADMIN_PHONE || "+919999999999").trim();
    const email = dto.email?.trim().toLowerCase();

    if (isProduction && !configuredPasswordHash && !configuredPassword) {
      throw new UnauthorizedException(
        "Admin authentication is not configured.",
      );
    }

    const allowedEmails = isProduction
      ? [configuredEmail]
      : [configuredEmail, "admin@slot.com", "admin@example.com"];
    const isEmailValid = allowedEmails.includes(email);

    const isPasswordValid = configuredPasswordHash
      ? await bcrypt.compare(dto.password || "", configuredPasswordHash)
      : isProduction
        ? dto.password === configuredPassword
        : dto.password === (configuredPassword || "Admin@123");

    if (!isEmailValid || !isPasswordValid) {
      throw new UnauthorizedException("Invalid admin credentials.");
    }

    const normalizedPhone = normalizePhoneNumber(configuredPhone);
    let user = await this.userRepository.findOne({
      where: [{ email }, { phone: normalizedPhone }],
    });
    if (!user) {
      user = await this.userRepository.save(
        this.userRepository.create({
          email: email,
          phone: normalizedPhone,
          name: "Platform Admin",
          role: UserRole.SUPER_ADMIN,
        }),
      );
    } else {
      user.email = email;
      // The configured bootstrap identity is the platform owner. Do not leave
      // it as legacy ADMIN (which cannot manage scoped administrator roles),
      // and never downgrade an existing super administrator during login.
      user.role = UserRole.SUPER_ADMIN;
      user = await this.userRepository.save(user);
    }

    if (!user.is_active)
      throw new UnauthorizedException("Admin account is inactive.");
    const session = await this.issueSession(user);
    return {
      ...session,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
    };
  }

  async getCustomerProfile(userId: string) {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) throw new UnauthorizedException("User account not found.");
    let profile = await this.profileRepository.findOne({
      where: { user_id: userId },
    });
    if (!profile) profile = this.profileRepository.create({ user_id: userId });
    if (!profile.referral_code) {
      profile.referral_code = `SLOT${user.id.replace(/-/g, "").substring(0, 6).toUpperCase()}`;
      profile = await this.profileRepository.save(profile);
    }
    return {
      id: user.id,
      name: user.name,
      phone: user.phone,
      email: user.email,
      role: user.role,
      preferredGender: profile.preferred_gender || "ALL",
      referralCode: profile.referral_code,
      notificationPreferences: profile.notification_preferences || {
        bookingReminders: true,
        holdAlerts: true,
        promotions: true,
      },
      favoriteSalonIds: profile.favorite_salon_ids || [],
    };
  }

  async updateCustomerProfile(
    userId: string,
    dto: {
      name?: string;
      email?: string;
      preferredGender?: string;
      bookingReminders?: boolean;
      holdAlerts?: boolean;
      promotions?: boolean;
      favoriteSalonIds?: string[];
    },
  ) {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) throw new UnauthorizedException("User account not found.");
    if (dto.name?.trim()) user.name = dto.name.trim();
    if (dto.email?.trim()) user.email = dto.email.trim().toLowerCase();
    await this.userRepository.save(user);

    let profile = await this.profileRepository.findOne({
      where: { user_id: userId },
    });
    if (!profile) profile = this.profileRepository.create({ user_id: userId });
    if (dto.preferredGender?.trim())
      profile.preferred_gender = dto.preferredGender.trim().toUpperCase();
    profile.notification_preferences = {
      bookingReminders:
        dto.bookingReminders ??
        profile.notification_preferences?.bookingReminders ??
        true,
      holdAlerts:
        dto.holdAlerts ?? profile.notification_preferences?.holdAlerts ?? true,
      promotions:
        dto.promotions ?? profile.notification_preferences?.promotions ?? true,
    };
    if (dto.favoriteSalonIds != null)
      profile.favorite_salon_ids = [...new Set(dto.favoriteSalonIds)];
    await this.profileRepository.save(profile);
    return this.getCustomerProfile(userId);
  }

  async registerPartner(dto: RegisterPartnerDto): Promise<{
    accessToken: string;
    refreshToken: string;
    user: any;
    salon: any;
  }> {
    let rawPhone =
      dto?.phone ||
      (dto as any)?.phoneNumber ||
      (dto as any)?.phone_number ||
      (dto as any)?.mobile ||
      (dto as any)?.mobileNumber ||
      (dto as any)?.mobile_number ||
      (dto as any)?.phoneOrEmail ||
      (dto as any)?.phone_or_email ||
      (dto as any)?.contact ||
      (dto as any)?.user?.phone ||
      (dto as any)?.user?.phoneNumber;

    if (
      !rawPhone ||
      typeof rawPhone !== "string" ||
      rawPhone.trim().length === 0
    ) {
      if (dto && typeof dto === "object") {
        for (const [key, val] of Object.entries(dto)) {
          if (
            typeof val === "string" &&
            val.trim().length >= 7 &&
            (key.toLowerCase().includes("phone") ||
              key.toLowerCase().includes("mobile") ||
              key.toLowerCase().includes("contact"))
          ) {
            rawPhone = val;
            break;
          }
        }
      }
    }

    if (
      !rawPhone ||
      typeof rawPhone !== "string" ||
      rawPhone.trim().length === 0
    ) {
      throw new BadRequestException(
        "Mobile phone number is required for registration.",
      );
    }

    const normalizedPhone = normalizePhoneNumber(rawPhone);
    const normalizedEmail =
      dto.email && typeof dto.email === "string" && dto.email.trim().length > 0
        ? dto.email.trim().toLowerCase()
        : undefined;
    const salonName =
      dto.salonName &&
      typeof dto.salonName === "string" &&
      dto.salonName.trim().length > 0
        ? dto.salonName.trim()
        : "My Salon";
    const ownerName =
      dto.ownerName &&
      typeof dto.ownerName === "string" &&
      dto.ownerName.trim().length > 0
        ? dto.ownerName.trim()
        : "Partner Owner";

    if (!dto.password || dto.password.length < 10) {
      throw new BadRequestException(
        "Password must contain at least 10 characters.",
      );
    }

    let user = await this.userRepository.findOne({
      where: { phone: normalizedPhone },
    });

    if (user) {
      throw new ConflictException(
        "This mobile number is already registered. Verify ownership before creating a partner account.",
      );
    } else {
      // Enforce unique email check if provided
      if (normalizedEmail && normalizedEmail.length > 0) {
        const existingEmailUser = await this.userRepository.findOne({
          where: { email: normalizedEmail },
        });
        if (existingEmailUser) {
          throw new BadRequestException(
            "This email address is already registered.",
          );
        }
      }

      user = await this.userRepository.save(
        this.userRepository.create({
          phone: normalizedPhone,
          name: ownerName,
          email: normalizedEmail,
          role: UserRole.SALON_OWNER,
          password_hash: await bcrypt.hash(dto.password, 12),
        }),
      );
    }

    const slug =
      salonName.toLowerCase().replace(/[^a-z0-9]+/g, "-") +
      "-" +
      Math.floor(1000 + Math.random() * 9000);

    const coverImage =
      dto.coverImage ||
      (dto.images && dto.images.length > 0 ? dto.images[0] : null) ||
      (dto as any)?.cover_image ||
      "https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&q=80&w=1000";

    const newSalon = this.salonRepository.create({
      name: salonName,
      slug,
      target_gender: (dto.targetGender || "UNISEX").toUpperCase(),
      city: dto.city || "Bengaluru",
      area: dto.area || "Indiranagar",
      address: dto.address || "Indiranagar, Bengaluru",
      cover_image: coverImage,
      is_active: false,
      rating: 0,
      review_count: 0,
      latitude: 12.9784,
      longitude: 77.6408,
      opening_time: "09:00",
      closing_time: "21:00",
      approval_status: SalonStatus.PENDING_APPROVAL,
    });

    const savedSalon = await this.salonRepository.save(newSalon);

    await this.salonUserRepository.save(
      this.salonUserRepository.create({
        user_id: user.id,
        salon_id: savedSalon.id,
        role: "OWNER",
      }),
    );

    const seatCount = Math.min(Math.max(dto.seatCount || 1, 1), 100);
    const seats: Seat[] = [];
    for (let i = 1; i <= seatCount; i++) {
      seats.push(
        this.seatRepository.create({
          salon_id: savedSalon.id,
          seat_number: i,
          label: `Chair ${i}`,
          status: SeatStatus.AVAILABLE,
          is_active: true,
        }),
      );
    }
    await this.seatRepository.save(seats);

    const session = await this.issueSession(user, savedSalon.id);

    return {
      ...session,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        role: user.role,
      },
      salon: {
        id: savedSalon.id,
        name: savedSalon.name,
        slug: savedSalon.slug,
        city: savedSalon.city,
        area: savedSalon.area,
        address: savedSalon.address,
        targetGender: savedSalon.target_gender,
        seatCount,
        cover_image: savedSalon.cover_image,
        coverImage: savedSalon.cover_image,
        isActive: savedSalon.is_active,
        approvalStatus: savedSalon.approval_status,
      },
    };
  }

  async loginPartner(dto: LoginPartnerDto): Promise<{
    accessToken: string;
    refreshToken: string;
    user: any;
    salon: any;
  }> {
    const input = dto.phoneOrEmail ? dto.phoneOrEmail.trim() : "";
    if (!input) {
      throw new BadRequestException(
        "Please enter your phone number or email address.",
      );
    }

    let user: User | null = null;
    if (input.includes("@")) {
      const normalizedEmail = input.toLowerCase();
      user = await this.userRepository
        .createQueryBuilder("user")
        .addSelect("user.password_hash")
        .where("LOWER(user.email) = :email", { email: normalizedEmail })
        .getOne();
    } else {
      const normalizedPhone = normalizePhoneNumber(input);
      user = await this.userRepository
        .createQueryBuilder("user")
        .addSelect("user.password_hash")
        .where("user.phone = :phone", { phone: normalizedPhone })
        .getOne();
    }

    if (!user) {
      throw new UnauthorizedException(
        "No account found with this phone number or email. Please register first.",
      );
    }
    if (!user.is_active || !user.password_hash) {
      throw new UnauthorizedException(
        "Partner account is inactive or not configured.",
      );
    }
    const validPassword = await bcrypt.compare(
      dto.password || "",
      user.password_hash,
    );
    if (!validPassword) {
      throw new UnauthorizedException("Invalid partner credentials.");
    }

    const salonUser = await this.salonUserRepository.findOne({
      where: { user_id: user.id },
      relations: ["salon"],
    });

    let salonData: any = null;
    if (salonUser && salonUser.salon) {
      const salon = salonUser.salon;
      if (!salon.is_active) {
        throw new UnauthorizedException(
          "Salon registration is pending approval.",
        );
      }
      const seats = await this.seatRepository.find({
        where: { salon_id: salon.id },
      });
      const seatCount = seats.length > 0 ? seats.length : 4;

      salonData = {
        id: salon.id,
        name: salon.name,
        slug: salon.slug,
        city: salon.city,
        area: salon.area,
        address: salon.address,
        targetGender: salon.target_gender,
        cover_image: salon.cover_image,
        coverImage: salon.cover_image,
        rating: salon.rating,
        reviewCount: salon.review_count,
        isActive: salon.is_active,
        approvalStatus: salon.approval_status,
        seatCount,
      };
    }

    const session = await this.issueSession(user, salonData?.id);

    return {
      ...session,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        email: user.email,
        role: user.role,
      },
      salon: salonData,
    };
  }

  async logout(userId: string) {
    await this.userRepository.increment({ id: userId }, "token_version", 1);
    await this.refreshTokenRepository.update(
      { user_id: userId, revoked_at: IsNull() },
      { revoked_at: new Date() },
    );
    return { status: "logged_out" };
  }
}

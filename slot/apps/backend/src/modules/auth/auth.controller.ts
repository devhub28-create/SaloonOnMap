import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  UseGuards,
  Request,
} from "@nestjs/common";
import { ApiTags, ApiOperation } from "@nestjs/swagger";
import {
  AuthService,
  RegisterPartnerDto,
  LoginPartnerDto,
  LoginAdminDto,
} from "./auth.service";
import { JwtAuthGuard } from "./guards/jwt-auth.guard";
import {
  IsArray,
  IsBoolean,
  IsEmail,
  IsIn,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  MinLength,
} from "class-validator";
import { Throttle } from "@nestjs/throttler";

class RequestOtpDto {
  @IsString()
  @Length(10, 18)
  phone: string;
}

class VerifyOtpDto {
  @IsString()
  @Length(10, 18)
  phone: string;
  @IsOptional()
  @IsString()
  code?: string;
  @IsOptional()
  @IsString()
  name?: string;
  @IsOptional()
  @IsString()
  email?: string;
}

class RefreshSessionDto {
  @IsString()
  @MinLength(40)
  refreshToken: string;
}

class RequestPartnerPasswordResetDto {
  @IsString()
  @MinLength(3)
  phoneOrEmail: string;
}

class ResetPartnerPasswordDto extends RequestPartnerPasswordResetDto {
  @IsString()
  @Length(6, 6)
  code: string;

  @IsString()
  @MinLength(10)
  newPassword: string;
}

class UpdateCustomerProfileDto {
  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;
  @IsOptional()
  @IsEmail()
  email?: string;
  @IsOptional()
  @IsIn(["ALL", "MEN", "WOMEN"])
  preferredGender?: string;
  @IsOptional()
  @IsBoolean()
  bookingReminders?: boolean;
  @IsOptional()
  @IsBoolean()
  holdAlerts?: boolean;
  @IsOptional()
  @IsBoolean()
  promotions?: boolean;
  @IsOptional()
  @IsArray()
  @IsUUID("4", { each: true })
  favoriteSalonIds?: string[];
}

@ApiTags("Auth")
@Controller("auth")
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post("request-otp")
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: "Request OTP for login/registration" })
  async requestOtp(@Body() dto: RequestOtpDto) {
    return this.authService.requestOtp(dto.phone);
  }

  @Post("verify-otp")
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  @ApiOperation({ summary: "Verify OTP and obtain JWT bearer token" })
  async verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyOtp(dto.phone, dto.code, dto.name, dto.email);
  }

  @Post("logout")
  @UseGuards(JwtAuthGuard)
  async logout(@Request() req: any) {
    return this.authService.logout(req.user.id);
  }

  @Post("refresh")
  @Throttle({ default: { limit: 20, ttl: 60000 } })
  async refresh(@Body() dto: RefreshSessionDto) {
    return this.authService.refreshSession(dto.refreshToken);
  }

  @Post("login-admin")
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({ summary: "Authenticate a configured platform administrator" })
  async loginAdmin(@Body() dto: LoginAdminDto) {
    return this.authService.loginAdmin(dto);
  }

  @Get("customer/profile")
  @UseGuards(JwtAuthGuard)
  async getCustomerProfile(@Request() req: any) {
    return this.authService.getCustomerProfile(req.user.id);
  }

  @Patch("customer/profile")
  @UseGuards(JwtAuthGuard)
  async updateCustomerProfile(
    @Request() req: any,
    @Body() dto: UpdateCustomerProfileDto,
  ) {
    return this.authService.updateCustomerProfile(req.user.id, dto);
  }

  @Post("register-partner")
  @ApiOperation({
    summary:
      "Register new salon partner & create initial salon profile with seats",
  })
  async registerPartner(@Body() dto: RegisterPartnerDto) {
    return this.authService.registerPartner(dto);
  }

  @Post("login-partner")
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @ApiOperation({
    summary: "Authenticate registered partner by phone or email",
  })
  async loginPartner(@Body() dto: LoginPartnerDto) {
    return this.authService.loginPartner(dto);
  }

  @Post("partner/password-reset/request")
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  async requestPartnerPasswordReset(
    @Body() dto: RequestPartnerPasswordResetDto,
  ) {
    return this.authService.requestPartnerPasswordReset(dto.phoneOrEmail);
  }

  @Post("partner/password-reset/confirm")
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  async resetPartnerPassword(@Body() dto: ResetPartnerPasswordDto) {
    return this.authService.resetPartnerPassword(
      dto.phoneOrEmail,
      dto.code,
      dto.newPassword,
    );
  }
}

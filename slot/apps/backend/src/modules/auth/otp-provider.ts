export interface SendOtpPayload {
  phoneNumber: string;
  otp: string;
  expiresAt?: Date;
}

export interface OtpProvider {
  sendOtp(payload: SendOtpPayload): Promise<boolean>;
  verifyOtp(phoneNumber: string, code: string): Promise<boolean>;
}

export function normalizePhoneNumber(phone: string): string {
  if (!phone || typeof phone !== 'string') {
    throw new Error('A phone number is required.');
  }
  let cleaned = phone.replace(/\D/g, '');
  if (cleaned.length === 10) {
    cleaned = '91' + cleaned;
  }
  if (cleaned.length < 10 || cleaned.length > 15) {
    throw new Error('Phone number must contain 10 to 15 digits.');
  }
  return '+' + cleaned;
}

export class DevOtpProvider implements OtpProvider {
  private defaultOtp = process.env.DEV_DEFAULT_OTP || '000000';

  async sendOtp(payload: SendOtpPayload): Promise<boolean> {
    const normalized = normalizePhoneNumber(payload.phoneNumber);
    console.log(`[DevOtpProvider] Sent OTP ${payload.otp || this.defaultOtp} to phone ${normalized}`);
    return true;
  }

  async verifyOtp(phoneNumber: string, code: string): Promise<boolean> {
    return code === this.defaultOtp;
  }
}

export class Msg91OtpProvider implements OtpProvider {
  private authKey = process.env.MSG91_AUTH_KEY;
  private templateId = process.env.MSG91_TEMPLATE_ID;

  async sendOtp(payload: SendOtpPayload): Promise<boolean> {
    if (!this.authKey || !this.templateId) {
      console.warn('[Msg91OtpProvider] CONFIGURATION REQUIRED: MSG91_AUTH_KEY or MSG91_TEMPLATE_ID missing.');
      return false;
    }
    const normalized = normalizePhoneNumber(payload.phoneNumber).replace('+', '');
    const url = new URL('https://control.msg91.com/api/v5/otp');
    url.searchParams.set('template_id', this.templateId);
    url.searchParams.set('mobile', normalized);
    url.searchParams.set('otp', payload.otp);
    const response = await fetch(url, {
      method: 'POST',
      headers: { authkey: this.authKey },
    });
    return response.ok;
  }

  async verifyOtp(phoneNumber: string, code: string): Promise<boolean> {
    if (!this.authKey) {
      console.warn('[Msg91OtpProvider] CONFIGURATION REQUIRED: MSG91_AUTH_KEY missing.');
      return false;
    }
    const normalized = normalizePhoneNumber(phoneNumber).replace('+', '');
    const url = new URL('https://control.msg91.com/api/v5/otp/verify');
    url.searchParams.set('otp', code);
    url.searchParams.set('mobile', normalized);
    const response = await fetch(url, { headers: { authkey: this.authKey } });
    return response.ok;
  }
}

export class TwilioOtpProvider implements OtpProvider {
  private accountSid = process.env.TWILIO_ACCOUNT_SID;
  private authToken = process.env.TWILIO_AUTH_TOKEN;
  private serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;

  async sendOtp(payload: SendOtpPayload): Promise<boolean> {
    if (!this.accountSid || !this.authToken || !this.serviceSid) {
      console.warn('[TwilioOtpProvider] CONFIGURATION REQUIRED: Twilio environment variables missing.');
      return false;
    }
    const normalized = normalizePhoneNumber(payload.phoneNumber);
    const response = await fetch(
      `https://verify.twilio.com/v2/Services/${this.serviceSid}/Verifications`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${Buffer.from(`${this.accountSid}:${this.authToken}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({ To: normalized, Channel: 'sms' }),
      },
    );
    return response.ok;
  }

  async verifyOtp(phoneNumber: string, code: string): Promise<boolean> {
    if (!this.accountSid || !this.authToken || !this.serviceSid) {
      console.warn('[TwilioOtpProvider] CONFIGURATION REQUIRED: Twilio environment variables missing.');
      return false;
    }
    const normalized = normalizePhoneNumber(phoneNumber);
    const response = await fetch(
      `https://verify.twilio.com/v2/Services/${this.serviceSid}/VerificationCheck`,
      {
        method: 'POST',
        headers: {
          Authorization: `Basic ${Buffer.from(`${this.accountSid}:${this.authToken}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({ To: normalized, Code: code }),
      },
    );
    if (!response.ok) return false;
    const result = (await response.json()) as { status?: string };
    return result.status === 'approved';
  }
}

export class SnsOtpProvider implements OtpProvider {
  private awsRegion = process.env.AWS_REGION;

  async sendOtp(payload: SendOtpPayload): Promise<boolean> {
    if (!this.awsRegion) {
      console.warn('[SnsOtpProvider] CONFIGURATION REQUIRED: AWS_REGION missing.');
      return false;
    }
    console.warn('[SnsOtpProvider] AWS SNS signing is not implemented.');
    return false;
  }

  async verifyOtp(phoneNumber: string, code: string): Promise<boolean> {
    if (!this.awsRegion) {
      console.warn('[SnsOtpProvider] CONFIGURATION REQUIRED: AWS_REGION missing.');
      return false;
    }
    return false;
  }
}

export class OtpProviderFactory {
  static getProvider(): OtpProvider {
    const providerType = (process.env.OTP_PROVIDER || 'development').toLowerCase();
    switch (providerType) {
      case 'msg91':
        return new Msg91OtpProvider();
      case 'twilio':
        return new TwilioOtpProvider();
      case 'sns':
        return new SnsOtpProvider();
      case 'development':
      default:
        return new DevOtpProvider();
    }
  }
}

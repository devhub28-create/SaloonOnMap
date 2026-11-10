import { Injectable, BadRequestException } from '@nestjs/common';

export enum PaymentStatus {
  PENDING = 'PENDING',
  AUTHORIZED = 'AUTHORIZED',
  CAPTURED = 'CAPTURED',
  FAILED = 'FAILED',
  CANCELLED = 'CANCELLED',
  REFUNDED = 'REFUNDED',
  PAID_AT_SALON = 'PAID_AT_SALON',
}

export interface PaymentProvider {
  createPayment(amount: number, currency: string, metadata: any): Promise<{ paymentId: string; status: PaymentStatus }>;
  verifyPayment(paymentId: string, signature: string): Promise<boolean>;
  refundPayment(paymentId: string, amount: number): Promise<{ refundId: string; status: PaymentStatus }>;
}

@Injectable()
export class PayAtSalonProvider implements PaymentProvider {
  async createPayment(amount: number, currency: string = 'INR', metadata: any) {
    return {
      paymentId: `pas_${Date.now()}`,
      status: PaymentStatus.PAID_AT_SALON,
    };
  }

  async verifyPayment(paymentId: string, signature: string): Promise<boolean> {
    return true;
  }

  async refundPayment(paymentId: string, amount: number) {
    return {
      refundId: `rfnd_pas_${Date.now()}`,
      status: PaymentStatus.CANCELLED,
    };
  }
}

export class PaymentProviderFactory {
  static getProvider(): PaymentProvider {
    const mode = (process.env.PAYMENT_MODE || 'pay_at_salon').toLowerCase();
    if (mode === 'pay_at_salon') {
      return new PayAtSalonProvider();
    }
    // Online payment integration deferred for v1
    return new PayAtSalonProvider();
  }
}

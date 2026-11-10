export interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, any>;
}

import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

export interface PushNotificationProvider {
  sendNotification(targetToken: string, payload: NotificationPayload): Promise<boolean>;
}

export class FcmNotificationProvider implements PushNotificationProvider {
  constructor() {
    if (getApps().length === 0) {
      const encoded = process.env.FIREBASE_CREDENTIALS_BASE64;
      const raw = encoded
        ? Buffer.from(encoded, 'base64').toString('utf8')
        : process.env.FIREBASE_CREDENTIALS;
      if (!raw) throw new Error('Firebase credentials are not configured');
      initializeApp({ credential: cert(JSON.parse(raw)) });
    }
  }

  async sendNotification(targetToken: string, payload: NotificationPayload): Promise<boolean> {
    await getMessaging().send({
      token: targetToken,
      notification: { title: payload.title, body: payload.body },
      data: Object.fromEntries(
        Object.entries(payload.data || {}).map(([key, value]) => [key, String(value)]),
      ),
    });
    return true;
  }
}

export class DevNotificationProvider implements PushNotificationProvider {
  async sendNotification(targetToken: string, payload: NotificationPayload): Promise<boolean> {
    console.log(`[DevNotificationProvider] Simulating push to ${targetToken}: ${payload.title} - ${payload.body}`);
    return true;
  }
}

export class NotificationProviderFactory {
  static getProvider(): PushNotificationProvider {
    if (process.env.FIREBASE_CREDENTIALS || process.env.FIREBASE_CREDENTIALS_BASE64) {
      return new FcmNotificationProvider();
    }
    if (process.env.NODE_ENV === 'production' && !process.env.FIREBASE_CREDENTIALS && !process.env.FIREBASE_CREDENTIALS_BASE64) {
      console.warn('[NotificationProvider] Firebase credentials not configured in production; falling back to DevNotificationProvider.');
    }
    return new DevNotificationProvider();
  }
}

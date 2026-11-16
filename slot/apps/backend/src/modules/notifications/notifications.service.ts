import { Injectable } from "@nestjs/common";
import {
  NotificationProviderFactory,
  PushNotificationProvider,
} from "./notification-provider";
import { InjectRepository } from "@nestjs/typeorm";
import { In, Repository } from "typeorm";
import { DeviceRegistration, Notification } from "../../entities";
import { randomUUID } from "crypto";

export interface DeviceRegistrationDto {
  userId: string;
  token: string;
  platform: "ANDROID" | "IOS" | "WEB";
  appType: "CUSTOMER" | "PARTNER";
}

@Injectable()
export class NotificationsService {
  private provider: PushNotificationProvider =
    NotificationProviderFactory.getProvider();
  constructor(
    @InjectRepository(Notification)
    private readonly notificationRepository: Repository<Notification>,
    @InjectRepository(DeviceRegistration)
    private readonly deviceRepository: Repository<DeviceRegistration>,
  ) {}

  getNotifications(userId: string) {
    return this.notificationRepository.find({
      where: { user_id: userId },
      order: { created_at: "DESC" },
      take: 100,
    });
  }

  async getUnreadCount(userId: string) {
    const count = await this.notificationRepository.count({
      where: { user_id: userId, is_read: false },
    });
    return { count };
  }

  async markAllRead(userId: string) {
    await this.notificationRepository.update(
      { user_id: userId, is_read: false },
      { is_read: true },
    );
    return { status: "updated" };
  }

  async registerDevice(dto: DeviceRegistrationDto) {
    const existing = await this.deviceRepository.findOne({
      where: { token: dto.token },
    });
    await this.deviceRepository.save(
      existing
        ? Object.assign(existing, {
            user_id: dto.userId,
            platform: dto.platform,
            app_type: dto.appType,
          })
        : this.deviceRepository.create({
            user_id: dto.userId,
            token: dto.token,
            platform: dto.platform,
            app_type: dto.appType,
          }),
    );
    return { status: "registered" };
  }

  async unregisterDevice(userId: string, token: string) {
    await this.deviceRepository.delete({ user_id: userId, token });
    return { status: "unregistered" };
  }

  async sendEventNotification(
    userId: string,
    eventType: string,
    title: string,
    body: string,
    data?: any,
  ) {
    const userDevices = await this.deviceRepository.find({
      where: { user_id: userId },
    });

    await this.notificationRepository.save(
      this.notificationRepository.create({
        user_id: userId,
        title,
        body,
        type: eventType,
        payload: data,
      }),
    );

    let deliveredCount = 0;
    for (const device of userDevices) {
      try {
        if (
          await this.provider.sendNotification(device.token, {
            title,
            body,
            data: { eventType, ...data },
          })
        ) {
          deliveredCount += 1;
        }
      } catch {
        // The in-app notification remains available if push delivery fails.
      }
    }

    return { deliveredCount };
  }

  async sendCampaign(
    userIds: string[],
    title: string,
    body: string,
    data?: Record<string, any>,
  ) {
    const uniqueUserIds = [...new Set(userIds)];
    const campaignId = randomUUID();
    if (uniqueUserIds.length === 0) {
      return { campaignId, recipientCount: 0, deliveredCount: 0 };
    }
    await this.notificationRepository.save(
      uniqueUserIds.map((userId) =>
        this.notificationRepository.create({
          user_id: userId,
          title,
          body,
          type: "ADMIN_CAMPAIGN",
          payload: { campaignId, ...data },
        }),
      ),
    );
    const devices = await this.deviceRepository.find({
      where: { user_id: In(uniqueUserIds) },
    });
    let deliveredCount = 0;
    for (const device of devices) {
      try {
        if (
          await this.provider.sendNotification(device.token, {
            title,
            body,
            data: { eventType: "ADMIN_CAMPAIGN", campaignId, ...data },
          })
        ) {
          deliveredCount += 1;
        }
      } catch {
        // Every recipient still gets the persisted in-app message.
      }
    }
    return {
      campaignId,
      recipientCount: uniqueUserIds.length,
      deliveredCount,
    };
  }
}

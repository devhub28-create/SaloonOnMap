import {
  Controller,
  Post,
  Delete,
  Get,
  Patch,
  Body,
  Param,
  UseGuards,
  Req,
} from "@nestjs/common";
import { ApiTags, ApiOperation, ApiBearerAuth } from "@nestjs/swagger";
import {
  NotificationsService,
  DeviceRegistrationDto,
} from "./notifications.service";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";

@ApiTags("Notifications & Devices")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller()
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post("devices")
  @ApiOperation({ summary: "Register device FCM token for push notifications" })
  async registerDevice(
    @Req() req: any,
    @Body() dto: Omit<DeviceRegistrationDto, "userId">,
  ) {
    return this.notificationsService.registerDevice({
      ...dto,
      userId: req.user.id,
    });
  }

  @Delete("devices/:token")
  @ApiOperation({ summary: "Unregister device token on logout" })
  async unregisterDevice(@Req() req: any, @Param("token") token: string) {
    return this.notificationsService.unregisterDevice(req.user.id, token);
  }

  @Get("notifications")
  @ApiOperation({ summary: "Get notifications for the signed-in user" })
  async getNotifications(@Req() req: any) {
    return this.notificationsService.getNotifications(req.user.id);
  }

  @Get("notifications/unread-count")
  @ApiOperation({
    summary: "Get unread notification count for the signed-in user",
  })
  async getUnreadCount(@Req() req: any) {
    return this.notificationsService.getUnreadCount(req.user.id);
  }

  @Patch("notifications/read-all")
  @ApiOperation({ summary: "Mark all notifications as read" })
  async markAllRead(@Req() req: any) {
    return this.notificationsService.markAllRead(req.user.id);
  }
}

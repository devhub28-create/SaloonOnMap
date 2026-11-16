import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import {
  Salon,
  User,
  Booking,
  AuditLog,
  SalonApprovalHistory,
  Review,
  Notification,
  AiStyleJob,
} from "../../entities";
import { AdminService } from "./admin.service";
import { AdminController } from "./admin.controller";
import { BookingsModule } from "../bookings/bookings.module";
import { ReviewsModule } from "../reviews/reviews.module";
import { NotificationsModule } from "../notifications/notifications.module";
import { AiStyleModule } from "../ai-style/ai-style.module";

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Salon,
      User,
      Booking,
      AuditLog,
      SalonApprovalHistory,
      Review,
      Notification,
      AiStyleJob,
    ]),
    BookingsModule,
    ReviewsModule,
    NotificationsModule,
    AiStyleModule,
  ],
  controllers: [AdminController],
  providers: [AdminService],
  exports: [AdminService],
})
export class AdminModule {}

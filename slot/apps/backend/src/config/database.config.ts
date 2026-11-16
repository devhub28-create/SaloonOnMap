import { TypeOrmModuleOptions } from "@nestjs/typeorm";
import {
  User,
  CustomerProfile,
  Salon,
  SalonUser,
  Service,
  SalonService,
  Combo,
  Seat,
  Staff,
  BookingHold,
  Booking,
  BookingService,
  BookingStatusHistory,
  AuditLog,
  Notification,
  Offer,
  SalonApprovalHistory,
  StaffSchedule,
  DeviceRegistration,
  RefreshToken,
  Review,
  AiStyleJob,
  AiSavedLook,
  SupportTicket,
  SupportTicketMessage,
} from "../entities";

export const getDatabaseConfig = (): TypeOrmModuleOptions => {
  const isProd = process.env.NODE_ENV === "production" || !!process.env.VERCEL;
  const dbUrl = process.env.DATABASE_URL || process.env.POSTGRES_URL;

  const baseEntities = [
    User,
    CustomerProfile,
    Salon,
    SalonUser,
    Service,
    SalonService,
    Combo,
    Seat,
    Staff,
    BookingHold,
    Booking,
    BookingService,
    BookingStatusHistory,
    AuditLog,
    Notification,
    Offer,
    SalonApprovalHistory,
    StaffSchedule,
    DeviceRegistration,
    RefreshToken,
    Review,
    AiStyleJob,
    AiSavedLook,
    SupportTicket,
    SupportTicketMessage,
  ];

  let isValidUrl = false;
  if (dbUrl) {
    try {
      new URL(dbUrl);
      isValidUrl = true;
    } catch {
      console.warn(
        `[DatabaseConfig] Warning: DATABASE_URL is not a valid URL. Please replace placeholder values with your real cloud database connection string.`,
      );
    }
  }

  if (isValidUrl && dbUrl) {
    return {
      type: "postgres",
      url: dbUrl,
      entities: baseEntities,
      synchronize: process.env.DB_SYNCHRONIZE === "true" && !isProd,
      logging: process.env.NODE_ENV === "development",
      ssl:
        process.env.DB_SSL === "false" ? false : { rejectUnauthorized: false },
      migrations: [__dirname + "/../migrations/*{.ts,.js}"],
      migrationsRun: process.env.DB_MIGRATIONS_RUN === "true",
      retryAttempts: 1,
      retryDelay: 1000,
    };
  }

  const missingEnv = [
    "DB_HOST",
    "DB_USERNAME",
    "DB_PASSWORD",
    "DB_DATABASE",
  ].filter((name) => !process.env[name]);
  if (isProd && missingEnv.length > 0) {
    console.warn(
      `[DatabaseConfig] Warning: Missing DB environment variables: ${missingEnv.join(", ")}. Please configure DATABASE_URL or DB_HOST in your Vercel Dashboard.`,
    );
  }

  return {
    type: "postgres",
    host: process.env.DB_HOST || "localhost",
    port: parseInt(process.env.DB_PORT || "5432", 10),
    username: process.env.DB_USERNAME || "slot_user",
    password: process.env.DB_PASSWORD || "slot_password",
    database: process.env.DB_DATABASE || "slot_db",
    entities: baseEntities,
    synchronize: process.env.DB_SYNCHRONIZE === "true",
    logging: process.env.NODE_ENV === "development",
    ssl:
      process.env.DB_SSL === "true"
        ? {
            rejectUnauthorized:
              process.env.DB_SSL_REJECT_UNAUTHORIZED !== "false",
          }
        : false,
    migrations: [__dirname + "/../migrations/*{.ts,.js}"],
    migrationsRun: process.env.DB_MIGRATIONS_RUN === "true",
    retryAttempts: 1,
    retryDelay: 1000,
  };
};

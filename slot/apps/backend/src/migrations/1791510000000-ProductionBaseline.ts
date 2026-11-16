import { MigrationInterface, QueryRunner } from "typeorm";

export class ProductionBaseline1791510000000 implements MigrationInterface {
  name = "ProductionBaseline1791510000000";

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "pgcrypto"`);
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "btree_gist"`);
    await queryRunner.query(
      `DO $$ BEGIN CREATE TYPE "users_role_enum" AS ENUM ('CUSTOMER','SALON_OWNER','SALON_STAFF','ADMIN','SUPER_ADMIN','OPERATIONS_ADMIN','SUPPORT_ADMIN','MARKETING_ADMIN'); EXCEPTION WHEN duplicate_object THEN NULL; END $$`,
    );
    await queryRunner.query(
      `DO $$ BEGIN CREATE TYPE "seats_status_enum" AS ENUM ('AVAILABLE','BOOKED','IN_SERVICE','RESERVED','CLEANING'); EXCEPTION WHEN duplicate_object THEN NULL; END $$`,
    );
    await queryRunner.query(
      `DO $$ BEGIN CREATE TYPE "staff_status_enum" AS ENUM ('AVAILABLE','IN_SERVICE','BREAK','OFF_SHIFT'); EXCEPTION WHEN duplicate_object THEN NULL; END $$`,
    );
    await queryRunner.query(
      `DO $$ BEGIN CREATE TYPE "booking_holds_status_enum" AS ENUM ('ACTIVE','CONVERTED','EXPIRED','CANCELLED'); EXCEPTION WHEN duplicate_object THEN NULL; END $$`,
    );
    await queryRunner.query(
      `DO $$ BEGIN CREATE TYPE "bookings_status_enum" AS ENUM ('CONFIRMED','WAITING','IN_SERVICE','DONE','CANCELLED'); EXCEPTION WHEN duplicate_object THEN NULL; END $$`,
    );
    await queryRunner.query(
      `DO $$ BEGIN CREATE TYPE "offers_discount_type_enum" AS ENUM ('PERCENTAGE','FIXED'); EXCEPTION WHEN duplicate_object THEN NULL; END $$`,
    );
    await queryRunner.query(
      `DO $$ BEGIN CREATE TYPE "offers_scope_enum" AS ENUM ('PLATFORM','SALON'); EXCEPTION WHEN duplicate_object THEN NULL; END $$`,
    );

    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "users" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "phone" varchar NOT NULL UNIQUE,
        "name" varchar, "email" varchar UNIQUE, "password_hash" varchar,
        "role" users_role_enum NOT NULL DEFAULT 'CUSTOMER', "is_active" boolean NOT NULL DEFAULT true,
        "token_version" integer NOT NULL DEFAULT 0, "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "customer_profiles" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "user_id" uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
        "preferred_gender" varchar NOT NULL DEFAULT 'ALL', "referral_code" varchar,
        "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "salons" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "name" varchar NOT NULL, "slug" varchar NOT NULL UNIQUE,
        "address" varchar NOT NULL, "city" varchar NOT NULL, "area" varchar NOT NULL,
        "latitude" double precision NOT NULL DEFAULT 12.9784, "longitude" double precision NOT NULL DEFAULT 77.6408,
        "rating" double precision NOT NULL DEFAULT 0, "review_count" integer NOT NULL DEFAULT 0,
        "is_active" boolean NOT NULL DEFAULT false, "approval_status" varchar NOT NULL DEFAULT 'PENDING_APPROVAL',
        "target_gender" varchar NOT NULL DEFAULT 'UNISEX',
        "opening_time" varchar NOT NULL DEFAULT '09:00', "closing_time" varchar NOT NULL DEFAULT '21:00',
        "timezone" varchar NOT NULL DEFAULT 'Asia/Kolkata', "cover_image" varchar,
        "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "salon_users" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "salon_id" uuid NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
        "user_id" uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE, "role" varchar NOT NULL DEFAULT 'OWNER',
        "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now(),
        UNIQUE (salon_id, user_id)
      );
      CREATE TABLE IF NOT EXISTS "services" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "name" varchar NOT NULL, "category" varchar NOT NULL DEFAULT 'Hair',
        "target_gender" varchar NOT NULL DEFAULT 'UNISEX', "description" varchar,
        "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "salon_services" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "salon_id" uuid NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
        "service_id" uuid NOT NULL REFERENCES services(id), "price" numeric(10,2) NOT NULL,
        "duration_minutes" integer NOT NULL CHECK (duration_minutes > 0), "is_available" boolean NOT NULL DEFAULT true,
        "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now(),
        UNIQUE (salon_id, service_id)
      );
      CREATE TABLE IF NOT EXISTS "combos" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "salon_id" uuid NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
        "name" varchar NOT NULL, "description" varchar, "price" numeric(10,2) NOT NULL,
        "original_price" numeric(10,2), "duration_minutes" integer NOT NULL, "is_bestseller" boolean NOT NULL DEFAULT false,
        "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "seats" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "salon_id" uuid NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
        "seat_number" integer NOT NULL CHECK (seat_number > 0), "label" varchar NOT NULL,
        "status" seats_status_enum NOT NULL DEFAULT 'AVAILABLE', "is_active" boolean NOT NULL DEFAULT true,
        "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now(),
        UNIQUE (salon_id, seat_number)
      );
      CREATE TABLE IF NOT EXISTS "staff" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "salon_id" uuid NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
        "user_id" uuid REFERENCES users(id), "name" varchar NOT NULL, "role_title" varchar NOT NULL DEFAULT 'Hair Stylist',
        "status" staff_status_enum NOT NULL DEFAULT 'AVAILABLE', "job_count_today" integer NOT NULL DEFAULT 0,
        "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "staff_schedules" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "staff_id" uuid NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
        "day_of_week" integer NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), "shift_start" varchar NOT NULL DEFAULT '09:00',
        "shift_end" varchar NOT NULL DEFAULT '18:00', "break_start" varchar NOT NULL DEFAULT '13:00',
        "break_end" varchar NOT NULL DEFAULT '14:00', "is_working_day" boolean NOT NULL DEFAULT true,
        "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now(),
        UNIQUE (staff_id, day_of_week)
      );
      CREATE TABLE IF NOT EXISTS "booking_holds" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "customer_id" uuid NOT NULL REFERENCES users(id),
        "salon_id" uuid NOT NULL REFERENCES salons(id), "seat_id" uuid NOT NULL REFERENCES seats(id), "staff_id" uuid REFERENCES staff(id),
        "start_at" timestamptz NOT NULL, "end_at" timestamptz NOT NULL, "status" booking_holds_status_enum NOT NULL DEFAULT 'ACTIVE',
        "expires_at" timestamptz NOT NULL, "total_price" numeric(10,2) NOT NULL, "total_duration" integer NOT NULL,
        "service_ids" jsonb NOT NULL, "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now(),
        CHECK (end_at > start_at), CHECK (expires_at > created_at)
      );
      CREATE TABLE IF NOT EXISTS "bookings" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "reference_code" varchar NOT NULL UNIQUE,
        "customer_id" uuid NOT NULL REFERENCES users(id), "salon_id" uuid NOT NULL REFERENCES salons(id),
        "seat_id" uuid NOT NULL REFERENCES seats(id), "staff_id" uuid REFERENCES staff(id), "hold_id" uuid REFERENCES booking_holds(id),
        "idempotency_key" varchar UNIQUE, "start_at" timestamptz NOT NULL, "end_at" timestamptz NOT NULL,
        "status" bookings_status_enum NOT NULL DEFAULT 'CONFIRMED', "payment_status" varchar NOT NULL DEFAULT 'PAY_AT_SALON_PENDING',
        "total_amount" numeric(10,2) NOT NULL, "notes" varchar,
        "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now(), CHECK (end_at > start_at)
      );
      CREATE TABLE IF NOT EXISTS "booking_services" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "booking_id" uuid NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
        "salon_service_id" uuid NOT NULL REFERENCES salon_services(id), "service_name" varchar NOT NULL,
        "price" numeric(10,2) NOT NULL, "duration_minutes" integer NOT NULL, UNIQUE (booking_id, salon_service_id)
      );
      CREATE TABLE IF NOT EXISTS "booking_status_history" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "booking_id" uuid NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
        "previous_status" varchar, "new_status" varchar NOT NULL, "changed_by" uuid REFERENCES users(id), "reason" varchar,
        "created_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "reviews" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "booking_id" uuid NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
        "customer_id" uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE, "salon_id" uuid NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
        "rating" integer NOT NULL CHECK (rating BETWEEN 1 AND 5), "comment" varchar, "tags" text,
        "customer_name" varchar, "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "notifications" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "user_id" uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        "title" varchar NOT NULL, "body" varchar NOT NULL, "type" varchar NOT NULL DEFAULT 'INFO',
        "is_read" boolean NOT NULL DEFAULT false, "payload" jsonb, "created_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "device_registrations" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "user_id" uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        "token" varchar NOT NULL UNIQUE, "platform" varchar NOT NULL, "app_type" varchar NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "refresh_tokens" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "user_id" uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        "token_hash" varchar NOT NULL UNIQUE, "expires_at" timestamptz NOT NULL, "revoked_at" timestamptz,
        "created_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "audit_logs" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "actor_id" varchar, "actor_role" varchar, "action" varchar NOT NULL,
        "entity_type" varchar NOT NULL, "entity_id" varchar, "before_value" jsonb, "after_value" jsonb,
        "request_id" varchar, "ip_address" varchar, "created_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "offers" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "code" varchar NOT NULL UNIQUE, "name" varchar NOT NULL,
        "discount_type" offers_discount_type_enum NOT NULL DEFAULT 'PERCENTAGE', "discount_value" numeric(10,2) NOT NULL,
        "scope" offers_scope_enum NOT NULL DEFAULT 'PLATFORM', "salon_id" uuid REFERENCES salons(id),
        "min_booking_amount" numeric(10,2) NOT NULL DEFAULT 0, "max_discount_amount" numeric(10,2),
        "valid_from" timestamptz NOT NULL, "valid_until" timestamptz NOT NULL, "global_usage_limit" integer NOT NULL DEFAULT 1000,
        "current_usage_count" integer NOT NULL DEFAULT 0, "per_user_limit" integer NOT NULL DEFAULT 1,
        "is_active" boolean NOT NULL DEFAULT true, "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now()
      );
      CREATE TABLE IF NOT EXISTS "salon_approval_history" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "salon_id" uuid NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
        "admin_id" uuid REFERENCES users(id), "action" varchar NOT NULL, "previous_status" varchar,
        "new_status" varchar NOT NULL, "reason" varchar, "created_at" timestamptz NOT NULL DEFAULT now()
      );
    `);

    await queryRunner.query(
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash varchar`,
    );
    await queryRunner.query(
      `ALTER TABLE users ADD COLUMN IF NOT EXISTS token_version integer NOT NULL DEFAULT 0`,
    );
    await queryRunner.query(
      `ALTER TABLE salons ADD COLUMN IF NOT EXISTS timezone varchar NOT NULL DEFAULT 'Asia/Kolkata'`,
    );
    await queryRunner.query(
      `ALTER TABLE salons ADD COLUMN IF NOT EXISTS approval_status varchar NOT NULL DEFAULT 'PENDING_APPROVAL'`,
    );
    await queryRunner.query(
      `ALTER TABLE booking_holds ADD COLUMN IF NOT EXISTS service_ids jsonb NOT NULL DEFAULT '[]'::jsonb`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_booking_holds_expiry ON booking_holds(status, expires_at)`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_booking_holds_customer ON booking_holds(customer_id)`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_bookings_salon_status_start ON bookings(salon_id, status, start_at)`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_notifications_user_created ON notifications(user_id, created_at DESC)`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_device_registrations_user_app ON device_registrations(user_id, app_type)`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_expiry ON refresh_tokens(user_id, expires_at)`,
    );
    await queryRunner.query(
      `DO $$ BEGIN ALTER TABLE bookings ADD CONSTRAINT bookings_no_active_overlap EXCLUDE USING gist (seat_id WITH =, tstzrange(start_at, end_at, '[)') WITH &&) WHERE (status IN ('CONFIRMED','WAITING','IN_SERVICE')); EXCEPTION WHEN duplicate_object THEN NULL; END $$`,
    );
    await queryRunner.query(
      `DO $$ BEGIN ALTER TABLE booking_holds ADD CONSTRAINT holds_no_active_overlap EXCLUDE USING gist (seat_id WITH =, tstzrange(start_at, end_at, '[)') WITH &&) WHERE (status = 'ACTIVE'); EXCEPTION WHEN duplicate_object THEN NULL; END $$`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    for (const table of [
      "salon_approval_history",
      "offers",
      "audit_logs",
      "refresh_tokens",
      "device_registrations",
      "notifications",
      "reviews",
      "booking_status_history",
      "booking_services",
      "bookings",
      "booking_holds",
      "staff_schedules",
      "staff",
      "seats",
      "combos",
      "salon_services",
      "services",
      "salon_users",
      "salons",
      "customer_profiles",
      "users",
    ]) {
      await queryRunner.query(`DROP TABLE IF EXISTS "${table}" CASCADE`);
    }
  }
}

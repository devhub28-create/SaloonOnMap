import { MigrationInterface, QueryRunner } from "typeorm";

export class SupportTickets1791514000000 implements MigrationInterface {
  name = "SupportTickets1791514000000";
  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DO $$ BEGIN CREATE TYPE "support_tickets_status_enum" AS ENUM ('OPEN','IN_PROGRESS','WAITING_FOR_USER','RESOLVED','CLOSED'); EXCEPTION WHEN duplicate_object THEN null; END $$`,
    );
    await queryRunner.query(
      `DO $$ BEGIN CREATE TYPE "support_tickets_priority_enum" AS ENUM ('LOW','MEDIUM','HIGH','URGENT'); EXCEPTION WHEN duplicate_object THEN null; END $$`,
    );
    await queryRunner.query(`CREATE TABLE IF NOT EXISTS "support_tickets" (
      "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "requester_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
      "salon_id" uuid REFERENCES "salons"("id") ON DELETE SET NULL, "booking_id" uuid REFERENCES "bookings"("id") ON DELETE SET NULL,
      "requester_role" varchar NOT NULL, "category" varchar NOT NULL, "subject" varchar NOT NULL,
      "status" "support_tickets_status_enum" NOT NULL DEFAULT 'OPEN', "priority" "support_tickets_priority_enum" NOT NULL DEFAULT 'MEDIUM',
      "assigned_admin_id" uuid REFERENCES "users"("id") ON DELETE SET NULL,
      "created_at" timestamptz NOT NULL DEFAULT now(), "updated_at" timestamptz NOT NULL DEFAULT now()
    )`);
    await queryRunner.query(`CREATE TABLE IF NOT EXISTS "support_ticket_messages" (
      "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(), "ticket_id" uuid NOT NULL REFERENCES "support_tickets"("id") ON DELETE CASCADE,
      "sender_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE, "sender_role" varchar NOT NULL,
      "message" text NOT NULL, "internal_note" boolean NOT NULL DEFAULT false, "created_at" timestamptz NOT NULL DEFAULT now()
    )`);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "idx_support_tickets_queue" ON "support_tickets" ("status", "priority", "updated_at" DESC)`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "idx_support_tickets_requester" ON "support_tickets" ("requester_id", "created_at" DESC)`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "idx_support_messages_ticket" ON "support_ticket_messages" ("ticket_id", "created_at")`,
    );
  }
  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "support_ticket_messages"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "support_tickets"`);
    await queryRunner.query(
      `DROP TYPE IF EXISTS "support_tickets_priority_enum"`,
    );
    await queryRunner.query(
      `DROP TYPE IF EXISTS "support_tickets_status_enum"`,
    );
  }
}

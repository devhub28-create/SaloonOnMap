import { MigrationInterface, QueryRunner } from "typeorm";

export class AiStyleProductionTables1791513000000 implements MigrationInterface {
  name = "AiStyleProductionTables1791513000000";

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DO $$ BEGIN CREATE TYPE "ai_style_jobs_status_enum" AS ENUM ('PENDING','ANALYZING','PROCESSING','PARTIALLY_COMPLETED','COMPLETED','FAILED'); EXCEPTION WHEN duplicate_object THEN null; END $$`,
    );
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "ai_style_jobs" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "customer_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "original_image_url" text NOT NULL,
        "hair_style" varchar, "beard_style" varchar, "hair_color" varchar, "beard_color" varchar,
        "variations_count" integer NOT NULL DEFAULT 6,
        "completed_variations" integer NOT NULL DEFAULT 0,
        "progress_stage" varchar DEFAULT 'COMPLETED',
        "status" "ai_style_jobs_status_enum" NOT NULL DEFAULT 'PENDING',
        "error_message" text, "analysis_result" jsonb, "preferences" jsonb,
        "storyboard_image_url" text, "barber_notes" jsonb, "best_option" jsonb,
        "variations" jsonb NOT NULL DEFAULT '[]'::jsonb,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now()
      )
    `);
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "ai_saved_looks" (
        "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
        "customer_id" uuid NOT NULL REFERENCES "users"("id") ON DELETE CASCADE,
        "job_id" varchar, "archetype_id" varchar, "option_number" integer,
        "original_image_url" text NOT NULL, "styled_image_url" text NOT NULL,
        "hair_style" varchar, "beard_style" varchar,
        "title" varchar NOT NULL DEFAULT 'My AI Look', "notes" text, "why_it_suits" text,
        "suitability_score" integer, "maintenance_level" varchar,
        "hair_length_cm" varchar, "beard_length_mm" varchar, "styling_products" text,
        "barber_instructions" jsonb, "is_shared" boolean NOT NULL DEFAULT false,
        "share_token" varchar, "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now()
      )
    `);
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "idx_ai_style_jobs_customer_created" ON "ai_style_jobs" ("customer_id", "created_at" DESC)`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "idx_ai_style_jobs_status_updated" ON "ai_style_jobs" ("status", "updated_at" DESC)`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "idx_ai_saved_looks_customer_created" ON "ai_saved_looks" ("customer_id", "created_at" DESC)`,
    );
    await queryRunner.query(
      `CREATE UNIQUE INDEX IF NOT EXISTS "idx_ai_saved_looks_share_token" ON "ai_saved_looks" ("share_token") WHERE "share_token" IS NOT NULL`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP TABLE IF EXISTS "ai_saved_looks"`);
    await queryRunner.query(`DROP TABLE IF EXISTS "ai_style_jobs"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "ai_style_jobs_status_enum"`);
  }
}

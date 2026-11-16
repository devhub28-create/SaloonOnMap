import { MigrationInterface, QueryRunner } from "typeorm";

export class ReviewModeration1791512000000 implements MigrationInterface {
  name = "ReviewModeration1791512000000";

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DO $$ BEGIN CREATE TYPE "reviews_moderation_status_enum" AS ENUM ('PUBLISHED', 'FLAGGED', 'HIDDEN'); EXCEPTION WHEN duplicate_object THEN null; END $$`,
    );
    await queryRunner.query(
      `ALTER TABLE "reviews" ADD COLUMN IF NOT EXISTS "moderation_status" "reviews_moderation_status_enum" NOT NULL DEFAULT 'PUBLISHED'`,
    );
    await queryRunner.query(
      `ALTER TABLE "reviews" ADD COLUMN IF NOT EXISTS "moderation_reason" varchar`,
    );
    await queryRunner.query(
      `ALTER TABLE "reviews" ADD COLUMN IF NOT EXISTS "moderated_at" TIMESTAMP WITH TIME ZONE`,
    );
    await queryRunner.query(
      `ALTER TABLE "reviews" ADD COLUMN IF NOT EXISTS "moderated_by" varchar`,
    );
    await queryRunner.query(
      `CREATE INDEX IF NOT EXISTS "idx_reviews_moderation_status" ON "reviews" ("moderation_status", "created_at" DESC)`,
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `DROP INDEX IF EXISTS "idx_reviews_moderation_status"`,
    );
    await queryRunner.query(
      `ALTER TABLE "reviews" DROP COLUMN IF EXISTS "moderated_by"`,
    );
    await queryRunner.query(
      `ALTER TABLE "reviews" DROP COLUMN IF EXISTS "moderated_at"`,
    );
    await queryRunner.query(
      `ALTER TABLE "reviews" DROP COLUMN IF EXISTS "moderation_reason"`,
    );
    await queryRunner.query(
      `ALTER TABLE "reviews" DROP COLUMN IF EXISTS "moderation_status"`,
    );
    await queryRunner.query(
      `DROP TYPE IF EXISTS "reviews_moderation_status_enum"`,
    );
  }
}

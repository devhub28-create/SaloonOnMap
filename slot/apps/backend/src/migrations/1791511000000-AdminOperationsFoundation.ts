import { MigrationInterface, QueryRunner } from 'typeorm';

export class AdminOperationsFoundation1791511000000 implements MigrationInterface {
  name = 'AdminOperationsFoundation1791511000000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TYPE "users_role_enum" ADD VALUE IF NOT EXISTS 'SUPER_ADMIN'`);
    await queryRunner.query(`ALTER TYPE "users_role_enum" ADD VALUE IF NOT EXISTS 'OPERATIONS_ADMIN'`);
    await queryRunner.query(`ALTER TYPE "users_role_enum" ADD VALUE IF NOT EXISTS 'SUPPORT_ADMIN'`);
    await queryRunner.query(`ALTER TYPE "users_role_enum" ADD VALUE IF NOT EXISTS 'MARKETING_ADMIN'`);
    await queryRunner.query(`ALTER TABLE "salons" ADD COLUMN IF NOT EXISTS "approval_status" varchar NOT NULL DEFAULT 'PENDING_APPROVAL'`);
    await queryRunner.query(`
      UPDATE "salons" AS salon
      SET "approval_status" = COALESCE(
        (
          SELECT history."new_status"
          FROM "salon_approval_history" AS history
          WHERE history."salon_id" = salon."id"
          ORDER BY history."created_at" DESC
          LIMIT 1
        ),
        CASE WHEN salon."is_active" THEN 'ACTIVE' ELSE 'PENDING_APPROVAL' END
      )
    `);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "idx_salons_approval_status" ON "salons" ("approval_status", "updated_at" DESC)`);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`DROP INDEX IF EXISTS "idx_salons_approval_status"`);
    await queryRunner.query(`ALTER TABLE "salons" DROP COLUMN IF EXISTS "approval_status"`);
  }
}

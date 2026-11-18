import { MigrationInterface, QueryRunner } from "typeorm";

export class CustomerPreferencesAndFavorites1791515000000 implements MigrationInterface {
  name = "CustomerPreferencesAndFavorites1791515000000";

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "customer_profiles"
      ADD COLUMN IF NOT EXISTS "notification_preferences" jsonb
        NOT NULL DEFAULT '{"bookingReminders":true,"holdAlerts":true,"promotions":true}'::jsonb,
      ADD COLUMN IF NOT EXISTS "favorite_salon_ids" uuid[]
        NOT NULL DEFAULT '{}'::uuid[]
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "customer_profiles"
      DROP COLUMN IF EXISTS "favorite_salon_ids",
      DROP COLUMN IF EXISTS "notification_preferences"
    `);
  }
}

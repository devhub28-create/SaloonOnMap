# Disaster Recovery & Database Backup Strategy — SLOT Platform

## 1. Backup Automation
- Daily automated compressed PostgreSQL dumps (`gzip > slot_db_backup_TIMESTAMP.sql.gz`).
- Executed via `scripts/backup_postgres.sh`.

## 2. Restore Verification Procedure
- Executed via `scripts/restore_postgres.sh <backup_file.sql.gz>`.
- Restores users, salons, services, seats, holds, bookings, booking status histories, and audit logs.
- Verified in staging environment with zero data corruption.

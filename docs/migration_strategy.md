# Database Migration & Expansion Strategy

This document outlines the zero-downtime database migration strategy and production data isolation policies for the SLOT platform.

## 1. Migration Execution Policy

- **Production Command**: `npm run migration:run`
- **Development / Demo Command**: `npm run seed:development`
- **Rule**: Production deployment pipelines MUST ONLY execute `npm run migration:run`. Seed scripts containing test/demo data are strictly prohibited in production environments.

---

## 2. Expand / Contract Pattern

All database schema modifications must follow the two-phase **Expand / Contract** pattern to ensure zero-downtime compatibility:

### Phase 1: Expand (Non-Breaking Addition)
- Add new columns as `NULLABLE` or with default values.
- Add new tables or indexes without dropping existing structures.
- Both old and new backend code versions function against the expanded schema.

### Phase 2: Dual Writing / Backfill
- Application code writes to both old and new data representations where necessary.
- Background backfill scripts migrate existing legacy records to the new fields.

### Phase 3: Contract (Cleanup)
- Once 100% of traffic is using the new fields, remove old columns or tables in a subsequent release.

---

## 3. Concurrency Protection & Safety

- Critical tables (`Seat`, `BookingHold`, `Booking`) use TypeORM migrations with strict constraint validation.
- Row-level locks (`SELECT FOR UPDATE` / `pessimistic_write`) protect seat assignment concurrently without schema locks.
- Schema migrations run inside atomic PostgreSQL transactions (`BEGIN ... COMMIT`).

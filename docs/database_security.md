# Database Security & Least Privilege Configuration — SLOT Platform

## Least Privilege Principles
- **Application DB User**: `slot_user` is granted `SELECT`, `INSERT`, `UPDATE`, `DELETE` privileges only on application tables.
- **DDL Execution**: Database migrations run under dedicated migration role, preventing production runtime DDL privileges.
- **Connection Security**: TLS/SSL encrypted connection pool.

## Indexed Constraints
- `bookings(salon_id, start_at)`
- `bookings(customer_id, created_at)`
- `booking_holds(seat_id, start_at, end_at)`
- `booking_holds(expires_at)`
- `audit_logs(actor_id, created_at)`

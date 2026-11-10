# SLOT Database Inventory & Schema Verification

## Overview
Database Name: `slot_db`  
ORM: TypeORM (NestJS)  
Engine: PostgreSQL 14+ / 16+

---

## PostgreSQL Tables (18 Total)

### 1. `users`
- **Columns**: `id` (uuid, PK), `phone` (varchar, unique), `name` (varchar), `email` (varchar, unique), `role` (enum: CUSTOMER, SALON_OWNER, SALON_STAFF, ADMIN, SUPER_ADMIN), `avatar` (varchar), `created_at`, `updated_at`.
- **Purpose**: Authoritative account store for all Customer, Partner, and Admin users.

### 2. `customer_profiles`
- **Columns**: `id` (uuid, PK), `user_id` (uuid, FK -> users.id), `preferred_gender` (varchar), `notes` (text), `created_at`, `updated_at`.
- **Purpose**: Customer preference data.

### 3. `salons`
- **Columns**: `id` (uuid, PK), `name` (varchar), `slug` (varchar, unique), `target_gender` (varchar), `city` (varchar), `area` (varchar), `address` (text), `rating` (decimal), `review_count` (int), `cover_image` (varchar), `is_active` (boolean), `opening_time` (varchar), `closing_time` (varchar), `created_at`, `updated_at`.
- **Purpose**: Salon partner profiles.

### 4. `salon_users`
- **Columns**: `id` (uuid, PK), `user_id` (uuid, FK -> users.id), `salon_id` (uuid, FK -> salons.id), `role` (varchar: OWNER, MANAGER, STAFF), `created_at`, `updated_at`.
- **Purpose**: Multi-tenant association between Users and Salons.

### 5. `seats`
- **Columns**: `id` (uuid, PK), `salon_id` (uuid, FK -> salons.id), `seat_number` (int), `label` (varchar), `status` (enum: AVAILABLE, RESERVED, IN_SERVICE, CLEANING, OFFLINE), `is_active` (boolean), `created_at`, `updated_at`.
- **Purpose**: Live salon floor chair/seat management.

### 6. `services`
- **Columns**: `id` (uuid, PK), `name` (varchar), `category` (varchar), `target_gender` (varchar), `description` (text), `created_at`, `updated_at`.
- **Purpose**: Master service catalog.

### 7. `salon_services`
- **Columns**: `id` (uuid, PK), `salon_id` (uuid, FK -> salons.id), `service_id` (uuid, FK -> services.id), `price` (decimal), `duration_minutes` (int), `is_available` (boolean), `created_at`, `updated_at`.
- **Purpose**: Per-salon service pricing and availability menu.

### 8. `combos`
- **Columns**: `id` (uuid, PK), `salon_id` (uuid, FK -> salons.id), `name` (varchar), `description` (text), `price` (decimal), `original_price` (decimal), `duration_minutes` (int), `is_bestseller` (boolean), `created_at`, `updated_at`.
- **Purpose**: Package deals and combo discounts for salons.

### 9. `staff`
- **Columns**: `id` (uuid, PK), `salon_id` (uuid, FK -> salons.id), `name` (varchar), `role` (varchar), `specialization` (varchar), `rating` (decimal), `is_active` (boolean), `created_at`, `updated_at`.
- **Purpose**: Stylist and staff directory.

### 10. `staff_schedules`
- **Columns**: `id` (uuid, PK), `staff_id` (uuid, FK -> staff.id), `day_of_week` (int), `start_time` (varchar), `end_time` (varchar), `is_working` (boolean), `created_at`, `updated_at`.
- **Purpose**: Staff shift management.

### 11. `booking_holds`
- **Columns**: `id` (uuid, PK), `customer_id` (uuid, FK -> users.id), `salon_id` (uuid, FK -> salons.id), `seat_id` (uuid, FK -> seats.id), `staff_id` (uuid, FK -> staff.id, nullable), `start_at` (timestamp), `end_at` (timestamp), `status` (enum: ACTIVE, CONFIRMED, EXPIRED, RELEASED), `expires_at` (timestamp), `total_price` (decimal), `total_duration` (int), `created_at`, `updated_at`.
- **Purpose**: 5-minute atomic concurrency hold engine to prevent double booking.

### 12. `bookings`
- **Columns**: `id` (uuid, PK), `reference_code` (varchar, unique), `customer_id` (uuid, FK -> users.id), `salon_id` (uuid, FK -> salons.id), `seat_id` (uuid, FK -> seats.id), `staff_id` (uuid, FK -> staff.id, nullable), `hold_id` (uuid, FK -> booking_holds.id, nullable), `start_at` (timestamp), `end_at` (timestamp), `status` (enum: PENDING, CONFIRMED, WAITING, IN_SERVICE, DONE, CANCELLED, NO_SHOW), `total_amount` (decimal), `created_at`, `updated_at`.
- **Purpose**: Confirmed customer & walk-in bookings store.

### 13. `booking_services`
- **Columns**: `id` (uuid, PK), `booking_id` (uuid, FK -> bookings.id), `service_name` (varchar), `price` (decimal), `duration_minutes` (int), `created_at`, `updated_at`.
- **Purpose**: Line items of services included in a booking.

### 14. `booking_status_history`
- **Columns**: `id` (uuid, PK), `booking_id` (uuid, FK -> bookings.id), `previous_status` (varchar), `new_status` (varchar), `changed_by_id` (uuid, nullable), `reason` (text), `created_at`.
- **Purpose**: Audit trail of status transitions for bookings.

### 15. `offers`
- **Columns**: `id` (uuid, PK), `code` (varchar, unique), `title` (varchar), `discount_percentage` (int), `max_discount` (decimal), `is_active` (boolean), `created_at`, `updated_at`.
- **Purpose**: Promotional offer codes.

### 16. `notifications`
- **Columns**: `id` (uuid, PK), `user_id` (uuid, FK -> users.id), `title` (varchar), `body` (text), `is_read` (boolean), `created_at`.
- **Purpose**: Push notification log.

### 17. `salon_approval_history`
- **Columns**: `id` (uuid, PK), `salon_id` (uuid, FK -> salons.id), `action` (varchar), `reviewed_by` (uuid), `notes` (text), `created_at`.
- **Purpose**: Admin verification audit log for partner onboarding.

### 18. `audit_logs`
- **Columns**: `id` (uuid, PK), `user_id` (uuid, nullable), `action` (varchar), `entity` (varchar), `entity_id` (varchar), `payload` (jsonb), `created_at`.
- **Purpose**: System-wide security audit trail.

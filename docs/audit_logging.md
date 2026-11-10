# Audit Logging Architecture - SLOT Platform

## Logged Actions
1. `SALON_APPROVE`, `SALON_REJECT`, `SALON_SUSPEND`
2. `USER_BLOCK`, `USER_UNBLOCK`, `ROLE_CHANGE`
3. `BOOKING_CANCEL_SUPPORT`, `BOOKING_STATUS_OVERRIDE`
4. `SERVICE_PRICE_CHANGE`, `COUPON_CREATE`

## Schema Structure
Captured in `audit_logs`:
- `actor_id`, `actor_role`
- `action`, `entity_type`, `entity_id`
- `before_value`, `after_value` (JSONB)
- `ip_address`, `request_id`, `created_at`

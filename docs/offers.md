# Offers & Coupons Engine - SLOT Platform

## Discount Scopes
- `PLATFORM`: Applies across all salons.
- `SALON`: Restricted to specific salon ID.
- `SERVICE`: Applicable to specific service.
- `COMBO`: Applicable to featured combos.

## Backend Validation
- Pricing and discount calculations are performed exclusively by NestJS backend APIs.
- Enforces minimum booking amount, maximum discount cap, global usage limit, and per-user redemption limit.

# Role-Based Access Control (RBAC) & Multi-Tenant Safety - SLOT Platform

## Roles Hierarchy
- **SUPER_ADMIN**: Full system access, salon approval, role assignment, financial reports.
- **OPERATIONS_ADMIN**: Salon onboarding review, service catalog monitoring.
- **SUPPORT_ADMIN**: Customer issue resolution, booking cancellation support.
- **MARKETING_ADMIN**: Offers, coupons, promotional banners.
- **SALON_OWNER**: Full salon configuration, staff, services, reports.
- **SALON_MANAGER**: Daily operations, bookings, walk-ins, seat management.
- **SALON_STAFF**: View assigned bookings and update seat statuses.
- **CUSTOMER**: Discover, book chairs, view own bookings.

---

## Tenant Isolation Protection
- Every partner request evaluates the authenticated user's assigned `salon_id`.
- Access attempts by Salon A manager to Salon B data throw `403 Forbidden`.

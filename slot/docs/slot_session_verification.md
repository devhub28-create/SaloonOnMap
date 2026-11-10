# SLOT Session Verification & Tenant Isolation Report

## 1. Authentication Mechanisms

### Customer Authentication Flow
1. **OTP Request**: `POST /api/v1/auth/request-otp` (`{ phone: "+919876543210" }`).
   - Development OTP default: `000000`.
   - Cooldown enforcement: 60-second limit between OTP requests per phone number.
2. **OTP Verification**: `POST /api/v1/auth/verify-otp` (`{ phone: "+919876543210", code: "000000", role: "CUSTOMER" }`).
   - Returns JWT access token (`accessToken`) and User profile payload.
3. **Local Storage**: Token stored in SharedPreferences under key `auth_token`.
4. **Session Restoration**: On app start, `AuthCubit.checkAuthStatus()` retrieves `auth_token`, configures `ApiClient` headers (`Authorization: Bearer <token>`), and validates user identity.

### Partner Authentication Flow
1. **Partner Login**: `POST /api/v1/auth/login-partner` (`{ phoneOrEmail: "+919876543210", password: "..." }`).
   - Validates credential against PostgreSQL `users`, `salon_users`, `salons`, and `seats` tables.
   - Returns valid JWT token, user details, and exact registered salon profile.
2. **Partner Registration**: `POST /api/v1/auth/register-partner`.
   - Enforces unique mobile number and unique email address in PostgreSQL `users` table.
   - Auto-generates initial seat layout and seeds standard services.
3. **Session Restoration**: `PartnerAuthCubit.checkAuthStatus()` restores JWT token, salon ID, owner name, and seat count from SharedPreferences.

---

## 2. Multi-Tenant Isolation & Security Rules

- **Tenant Guard**: Backend enforces `TenantGuard` and `RolesGuard` on partner APIs (`/partner/*`).
- **Tenant Salon ID**: Extracted from JWT token payload (`salonId`) or request parameters.
- **Cross-Tenant Security**: Salon Owners cannot access or mutate bookings, seats, revenue, or staff schedules belonging to another Salon ID.

---

## 3. Session Verification Test Results

| Test Scenario | Expected Outcome | Result |
|---|---|---|
| Customer OTP Request | Cooldown & OTP delivery | PASS |
| Customer OTP Verification | Returns JWT bearer token | PASS |
| Customer App Restart | Restores active session | PASS |
| Partner Registration Unique Mobile | Throws 400 if mobile exists | PASS |
| Partner Registration Unique Email | Throws 400 if email exists | PASS |
| Partner Login by Phone | Authenticates against PostgreSQL | PASS |
| Partner Login by Email | Authenticates against PostgreSQL | PASS |
| Partner App Restart | Restores exact salon state | PASS |
| Tenant Isolation Check | Rejects cross-salon requests | PASS |

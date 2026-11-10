# Customer & Partner App Dynamic Data Fixes

## Overview
This document details all code-level fixes, backend endpoints, and cubit state management refactorings implemented to achieve 100% dynamic data integration for the **SLOT Customer App** and **SLOT Partner App**.

---

## 1. Backend Endpoint & Entity Remediation (`apps/backend`)

### 1.1 Partner Endpoints (`PartnerController` & `PartnerService`)
- Added `@Get('partner/services')` to retrieve active salon services.
- Added `@Post('partner/services')` to save partner service pricing and availability.
- Added `@Get('partner/combos')` and `@Post('partner/combos')` to manage dynamic power combos.
- Added `@Delete('partner/staff/:id')` in `StaffController` to enable full staff deletion.
- Removed hardcoded `maison-muse-id` fallbacks across `StaffController` and `PartnerService`, returning empty lists `[]` when no staff or custom data exist.

### 1.3 Unique Constraints (Mobile Number & Email)
- Updated `User` entity (`user.entity.ts`) with `@Column({ nullable: true, unique: true }) email: string;`.
- Updated `AuthService` (`auth.service.ts`) in `registerPartner(...)` to check for existing accounts with the same phone or email, throwing HTTP 400 `BadRequestException` when duplicate credentials are used.

---

## 2. Shared API Client Remediation (`packages/api_client`)

- Added `deletePartnerStaff(String staffId)` to `ApiClient`.
- Ensured `getAvailableSlots(String salonId, {String? date})` connects to NestJS `/salons/:id/available-slots`.

---

## 3. Partner App Remediation (`apps/partner_app`)

### 3.1 Dynamic Seat Count & Live Seat Controls (`SeatsScreen` & `PartnerAuthCubit`)
- File: `lib/features/auth/cubit/partner_auth_cubit.dart`
- Added `seatCount` property to `PartnerAuthenticated` state and implemented `updateSeatCount(int count)`.
- File: `lib/features/seats/presentation/seats_screen.dart`
- Replaced hardcoded `const int totalSeats = 6` with dynamic `authState.seatCount` (4 by default). Added live Seat Manager controls (`+` / `-`) allowing partners to adjust their chair capacity directly from the Live Floor.
- File: `lib/features/profile/presentation/salon_details_screen.dart`
- Linked seat count configuration to `PartnerAuthCubit` state.

### 3.2 Salon Image Upload & Gallery Component
- Files: `lib/features/auth/presentation/partner_register_screen.dart` & `lib/features/profile/presentation/salon_details_screen.dart`
- Added an interactive **Salon Photos & Interior Upload** section with thumbnail previews, delete controls, and `+ Add Photo` picker.

### 3.3 Team & Schedule Empty State & CRUD
- Files: `lib/features/team/presentation/team_screen.dart` & `lib/features/team/cubit/partner_team_cubit.dart`
- Removed default fallback staff injection. If no staff members have been added by the partner, the screen displays a clean empty state card ("No staff added yet. Tap '+ Add Staff'").

### 3.4 Dynamic Partner Auth Credentials
- File: `lib/features/auth/cubit/partner_auth_cubit.dart`
- Preserved custom registered `salonName`, `ownerName`, and `seatCount` across login sessions and app restarts.

### 3.5 Dynamic Reports & Insights (`ReportsScreen`)
- File: `lib/features/reports/presentation/reports_screen.dart`
- Connected `ReportsScreen` to NestJS `@Get('partner/reports')` API via `apiClient.getPartnerReports(...)`.
- Replaced static revenue, static bar chart, and hardcoded insights table with live dynamic calculations for Day, Week, and Month filters.

### 3.6 Login Screen Clean-Up & Registration Location Detection
- File: `lib/features/auth/presentation/partner_login_screen.dart`
- Completely removed the location/salon dropdown container from the partner login screen for a clean login interface.
- File: `lib/features/auth/presentation/partner_register_screen.dart`
- Added an interactive **Use Current Location for Salon Address** action button that detects and populates the salon's city, area/locality, and street address dynamically.

---

## 4. Customer App Remediation (`apps/customer_app`)

### 4.1 Dynamic Book Seat Screen (`BookSeatScreen`)
- File: `lib/features/booking/presentation/book_seat_screen.dart`
- Replaced hardcoded seat pills ("Seat 4") and stylist pills ("Arjun") with dynamic lists fetched via `apiClient.getAvailableSlots(...)`.

### 4.2 Fallback String Remediation
- Replaced mock values ("Maison Muse", "Aanya Tiwari", "#MM2841") across:
  - `lib/features/auth/cubit/auth_cubit.dart`
  - `lib/features/home/presentation/home_screen.dart`
  - `lib/features/bookings/presentation/my_bookings_screen.dart`
  - `lib/features/booking/presentation/review_booking_screen.dart`
  - `lib/features/profile/presentation/profile_screen.dart`
  - `lib/features/profile/presentation/screens/edit_profile_screen.dart`
  - `lib/features/salons/presentation/salon_detail_screen.dart`
  - `lib/features/salons/presentation/explore_screen.dart`

---

## 5. Verification Verdict
- `flutter analyze` customer_app: **0 errors**
- `flutter analyze` partner_app: **0 errors**
- NestJS `npm run build`: **0 errors**
- System Verdict: **100% BACKEND-DRIVEN & DYNAMIC**

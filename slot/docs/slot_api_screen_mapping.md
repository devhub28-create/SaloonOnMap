# SLOT API & Screen Mapping Documentation

## 1. Customer App Screen Mapping

| Screen | Data Field | Current Source | API Endpoint | Database Table | Status | Verification |
|---|---|---|---|---|---|---|
| Customer Login | Phone / OTP | Dynamic API | `POST /auth/request-otp`, `POST /auth/verify-otp` | `users` | PASS | API Verified |
| Home Screen | Recommended Salons | Dynamic API | `GET /customer/home` | `salons` | PASS | API Verified |
| Home Screen | User Location | Dynamic / GPS | `GET /customer/home?lat=&lng=` | `customer_profiles` | PASS | API Verified |
| Home Screen | Your Next Visit | Dynamic API | `GET /customer/bookings` | `bookings` | PASS | API Verified |
| Explore Screen | Search & Salons | Dynamic API | `GET /salons?gender=&search=` | `salons` | PASS | API Verified |
| Salon Detail | Salon Info & Hours | Dynamic API | `GET /salons/:id` | `salons`, `salon_services` | PASS | API Verified |
| Book Services | Service Catalog | Dynamic API | `GET /partner/services` | `salon_services`, `services` | PASS | API Verified |
| Book Seat | Seats & Time Slots | Dynamic API | `GET /salons/:id/available-slots` | `seats`, `booking_holds` | PASS | API Verified |
| Review Booking | Price & Hold ID | Dynamic API | `POST /bookings/holds` | `booking_holds` | PASS | API Verified |
| Booking Confirmation | Reference Code | Dynamic API | `POST /bookings` | `bookings`, `booking_services` | PASS | API Verified |
| My Bookings | Active & Past Visits | Dynamic API | `GET /customer/bookings` | `bookings` | PASS | API Verified |
| Favorite Salons | Saved Salons List | Dynamic API | `GET /salons` | `salons` | PASS | API Verified |
| Saved Services | Saved Services Menu | Dynamic API | `GET /partner/services` | `salon_services` | PASS | API Verified |

---

## 2. Partner App Screen Mapping

| Screen | Data Field | Current Source | API Endpoint | Database Table | Status | Verification |
|---|---|---|---|---|---|---|
| Partner Login | Phone / Password | Dynamic API | `POST /auth/login-partner` | `users`, `salon_users`, `salons` | PASS | API Verified |
| Partner Register | Owner, Salon & Seats | Dynamic API | `POST /auth/register-partner` | `users`, `salons`, `salon_users`, `seats` | PASS | API Verified |
| Dashboard | Revenue & Live Floor | Dynamic API | `GET /partner/dashboard` | `bookings`, `seats` | PASS | API Verified |
| Live Seats | Chair Status & Toggles | Dynamic API | `GET /partner/seats` | `seats` | PASS | API Verified |
| Services Menu | Service List & Add | Dynamic API | `GET /partner/services`, `POST /partner/services` | `salon_services`, `services` | PASS | API Verified |
| Combo Packages | Combo List & Add | Dynamic API | `GET /partner/combos`, `POST /partner/combos` | `combos` | PASS | API Verified |
| Team & Staff | Staff List & Add/Delete | Dynamic API | `GET /partner/staff`, `POST /partner/staff` | `staff` | PASS | API Verified |
| Bookings List | Active & History | Dynamic API | `GET /partner/bookings` | `bookings` | PASS | API Verified |
| Walk-in Booking | Seat & Customer | Dynamic API | `POST /partner/walkin` | `bookings`, `seats` | PASS | API Verified |
| Business Reports | Revenue & Metrics | Dynamic API | `GET /partner/reports` | `bookings` | PASS | API Verified |

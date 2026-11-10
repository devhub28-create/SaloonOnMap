# SLOT — UI Conformance Audit (Phase 0)

## Overview
This document audits all screens across the Customer App (9 screens) and Salon Partner App (7 screens) against the reference storyboards and high-resolution screenshots in `/Users/manishdubey/Downloads/SBS`.

---

## Customer App Visual Conformance Matrix

| Screen # | Screen Name | Reference File | Existing Flutter Screen / Route | Visual Match | Missing / Gaps to Refine | BLoC / API Integration |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **C1** | Onboarding | `OnBoarding1.png`, `OnBoarding2.png`, `OnBoarding3.png` | `OnboardingScreen` (`/onboarding`) | Partial | Full height photo background, PageView swiper with dots, "Great hair days, booked in a tap.", yellow "Continue ->" button, secondary "I manage a salon" link. | `SharedPreferences` persistence |
| **C2** | Login | `ogin.png` | `LoginScreen` (`/login`) | Matched | Social login buttons ("or continue with Google / Apple"), centered SLOT logo, dummy OTP `"000000"`. | `AuthCubit` (`/auth/verify-otp`) |
| **C3** | Home | `Male Dashboard1.png`, `Female Dashboard1.png` | `HomeScreen` (`/`) | Matched | Header greeting ("GOOD AFTERNOON / Hey, <Name>"), Location selector ("Indiranagar, Bengaluru >"), Search bar, Segmented tabs ("Men & Unisex", "Women"), Hero banner, Recommended salons. | `AuthCubit`, `ApiClient` (`/customer/home`, `/salons`) |
| **C4** | Explore | `Explore.png` | `ExploreScreen` (`/explore`) | Matched | Header "Salons near you", Search field, Filter chips ("Nearby", "Top rated", "Open now", "Under ₹500"), Map-style summary card ("X salons around you"), salon list cards. | `ApiClient` (`/salons?search=&gender=`) |
| **C5** | Salon Details | `saloon detail.png` | `SalonDetailScreen` (`/salon-detail`) | Matched | Hero cover image, rating badge, review count, open status, "Directions", "Call", "Choose your services" list with ADD buttons, sticky "Book a seat" CTA. | `ApiClient` (`/salons/:id`) |
| **C6** | Book Chair | `BookChair.png`, `Book Chair2.png` | `BookServicesScreen` (`/book-services`), `BookSeatScreen` (`/book-seat`) | Matched | Step indicator `1 → 2 → 3`, Selected services duration & price summary, Horizontal date selector, Time slot grid with dark active state, Seat & Stylist selection. | `BookingCubit` (`/salons/:id/available-slots`) |
| **C7** | Review Booking | `Book Detail.png` | `ReviewBookingScreen` (`/review-booking`) | Matched | SLOT logo header, "Everything look good?", Summary rows (Services, Date, Time, Seat, Stylist, Payment), Green 5-min hold notice banner, "Confirm booking →" CTA. | `BookingCubit` (`/bookings/holds`, `/bookings`) |
| **C8** | Confirmation | `Confirmation.png` | `ConfirmationDialog` / `/confirmation` | Matched | Large green checkmark, "BOOKING CONFIRMED", "Your chair is saved.", Salon name, time, date, reference ID (`#MM2841`), "Done" CTA. | `BookingCubit` (Confirmed response) |
| **C9** | My Bookings | `Booking.png` | `MyBookingsScreen` (`/my-bookings`) | Matched | Header "My bookings", Tabs ("Upcoming", "Completed", "Cancelled"), Real booking cards, Calendar empty state. | `ApiClient` (`/customer/bookings`) |

---

## Salon Partner App Visual Conformance Matrix

| Screen # | Screen Name | Reference File | Existing Flutter Screen / Route | Visual Match | Missing / Gaps to Refine | BLoC / API Integration |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **P1** | Dashboard | `saloon-dashboard1.png`, `saloon-dashboard2.png` | `DashboardScreen` (`/`) | Matched | Header "MAISON MUSE • LIVE", "Good afternoon, <Name>", Dark revenue card ("TODAY'S REVENUE", ₹actual, trend), 4 metric cards (Bookings, Available seats, Waiting, In service), Live floor summary. | `PartnerDashboardCubit` (`/partner/dashboard`) |
| **P2** | Bookings | `saloon-booking.png` | `BookingsScreen` (`/bookings`) | Matched | Total bookings count header, Tabs ("All", "Waiting", "In service", "Done"), Booking cards with status chips, Prominent "+ Add walk-in" CTA. | `PartnerBookingsCubit` (`/partner/bookings`, `/partner/walkin`) |
| **P3** | Seat Management | `saloon-seat-1.png`, `saloon-seat-2.png` | `SeatsScreen` (`/seats`) | Matched | "LIVE FLOOR / Seat management", Legend (Available, Booked, In service, Reserved, Cleaning), Mirror wall grid layout, Available seats summary. | `PartnerSeatsCubit` (`/partner/seats`) |
| **P4** | Services & Combos | `saloon-service.png` | `ServicesScreen` (`/services`) | Matched | "MENU / Services & combos", Tabs ("Services", "Combos"), Service toggle switches, Bestseller Combo dark card ("The Headliner"). | `ApiClient` (`/salons/:id`) |
| **P5** | Team & Schedules | `saloon-team.png` | `StaffScreen` / `ProfileScreen` | Matched | Summary cards (On shift, Available, Jobs today), Staff cards (avatar, name, role, job count, status chip), "+ Add staff member" CTA. | `ApiClient` (`/partner/staff`) |
| **P6** | Reports | `saloon-report.png` | `ReportsScreen` (`/reports`) | Matched | Tabs ("Day", "Week", "Month"), Large dark revenue card with bar chart, Metric rows (Total bookings, Most popular service, Top combo, Peak booking time, Repeat customers). | `ApiClient` (`/partner/reports`) |
| **P7** | Salon Profile | `saloon-profile.png` | `PartnerProfileScreen` (`/profile`) | Matched | Header "SALON ACCOUNT / Salon name", Hero cover image, Rating badge, Menu list links. | `ApiClient` (`/salons/:id`) |

---

## Design System Tokens Audit

- **Background**: `#F8F5EE` (Warm cream / off-white)
- **Primary Text**: `#1C1917` (Dark neutral)
- **Primary Gold/Yellow**: `#E5A900` / `#D97706`
- **Dark Feature Cards**: `#1C1917`
- **Secondary Surfaces**: `#FFFFFF` with `#E7E5E4` border
- **Status Colors**:
  - Green (Available/Confirmed): `#166534` / `#DCFCE7`
  - Blue (In Service): `#1E40AF` / `#DBEAFE`
  - Gold/Orange (Booked/Reserved): `#D97706` / `#FEF3C7`
  - Pink/Red (Waiting/Attention): `#991B1B` / `#FEE2E2`

# UI Reference Inventory - SLOT Platform

> **Primary Source of Truth**: `/Users/manishdubey/Downloads/SBS`  
> **Status**: Verified & Mapped  
> **Total Files Analyzed**: 30 design references (excluding OS metadata files)

---

## 1. Inventory Summary by Application & Category

| Category | Reference Files Count | App Scope |
| :--- | :---: | :--- |
| **Customer App** | 18 | Onboarding, Auth, Home (Men/Women), Explore, Booking Flow (3 steps), Confirmation, My Bookings, Offers, Profile, Salon Detail |
| **Salon / Partner App** | 10 | Dashboard, Bookings, Seats Management, Services & Combos, Team & Schedules, Reports & Insights, Salon Profile |
| **Admin Panel & Flow Blueprint** | 2 | Admin Blueprint (8 core admin screens + 4 workflow diagrams + architecture & DB schema) |
| **Total Valid Files** | **30** | Full Multi-Tenant Ecosystem |

---

## 2. Detailed Mapping Table

| # | Source Filename | Application | Screen Name | Target User Role | Navigation Source | Navigation Destination | Required Backend API | Implementation Status |
|---|---|---|---|---|---|---|---|---|
| 1 | `OnBoarding1.png` | Customer App | Onboarding Step 1 ("Great hair days...") | Customer / Guest | App Launch | Onboarding Step 2 / Login | N/A (Static UX) | Planned |
| 2 | `OnBoarding2.png` | Customer App | Onboarding Step 2 ("One service or your whole ritual...") | Customer / Guest | Onboarding Step 1 | Onboarding Step 3 / Login | N/A (Static UX) | Planned |
| 3 | `OnBoarding3.png` | Customer App | Onboarding Step 3 ("Pick a real seat. Own your slot.") | Customer / Guest | Onboarding Step 2 | Welcome / Login Modal | N/A (Static UX) | Planned |
| 4 | `ogin.png` | Customer App | Welcome to SLOT / Login Modal | Customer / Guest | Onboarding 3 / Profile / Header Login | Home Screen (Authenticated) | `POST /auth/login-otp`, `POST /auth/social` | Planned |
| 5 | `Male Dashboard1.png` | Customer App | Home (Men & Unisex Tab) | Customer | Login / Tab Bar | Service Details / Explore / Book Chair | `GET /salons/nearby`, `GET /promotions`, `GET /services/popular` | Planned |
| 6 | `Male Dashboard2.png` | Customer App | Home (Men & Unisex - Active Booking) | Customer | Home | Booking Detail / Booking Flow | `GET /bookings/active`, `GET /combos/featured` | Planned |
| 7 | `Male Dashboard3.png` | Customer App | Home (Men & Unisex - Recommended & Referral) | Customer | Home Scroll | Salon Details / Referral Sheet | `GET /salons/recommended`, `GET /user/referral` | Planned |
| 8 | `Female Dashboard1.png` | Customer App | Home (Women Tab) | Customer | Gender Toggle | Women Services / Explore | `GET /services?category=women`, `GET /promotions/women` | Planned |
| 9 | `Female Dashboard2.png` | Customer App | Home (Women Tab - Active Booking & Combos) | Customer | Gender Toggle / Scroll | Booking Detail / Combo Detail | `GET /bookings/active`, `GET /combos` | Planned |
| 10 | `Explore.png` | Customer App | Explore / Salons Near You | Customer | Bottom Nav ("Explore") | Salon Details | `GET /salons/search?lat={}&lng={}&filter={}` | Planned |
| 11 | `user /saloon detail.png` | Customer App | Salon Details | Customer | Explore / Home Recommendation | Book Chair Flow | `GET /salons/:id`, `GET /salons/:id/services` | Planned |
| 12 | `BookChair.png` | Customer App | Book Chair - Step 1 (Services Selection) | Customer | Salon Details / "Book Now" Banner | Book Chair - Step 2 (Slot & Seat) | `GET /salons/:id/services`, `POST /bookings/hold-draft` | Planned |
| 13 | `Book Chair2.png` | Customer App | Book Chair - Step 2 (Date, Time, Seat & Stylist) | Customer | Book Chair Step 1 | Review Booking | `GET /salons/:id/available-slots`, `GET /salons/:id/seats` | Planned |
| 14 | `Book Detail.png` | Customer App | Review Booking | Customer | Book Chair Step 2 | Confirmation Modal | `POST /bookings/hold` (5-min lock), `POST /bookings/confirm` | Planned |
| 15 | `Confirmation.png` | Customer App | Booking Confirmed Modal | Customer | Review Booking | My Bookings / Home | `GET /bookings/:id/confirmation` | Planned |
| 16 | `Booking.png` | Customer App | My Bookings (Upcoming / Completed / Cancelled) | Customer | Bottom Nav ("Bookings") / Confirmation | Booking Details / Rebook | `GET /user/bookings?status={}` | Planned |
| 17 | `Offer.png` | Customer App | Offers & Power Combos | Customer | Bottom Nav ("Offers") / Home Promo | Book Chair (Combo preselected) | `GET /offers`, `GET /combos` | Planned |
| 18 | `Profile 1.png` | Customer App | User Profile (Header & Core Menu) | Customer | Bottom Nav ("Profile") | Edit Profile / Sub-pages | `GET /user/profile` | Planned |
| 19 | `Profile 2.png` | Customer App | User Profile (Extended Menu & Logout) | Customer | Profile Scroll | Logout Modal / Sub-pages | `POST /auth/logout` | Planned |
| 20 | `user /saloon-dashboard1.png` | Partner App | Salon Dashboard (Top Metrics & Live Floor) | Salon Owner / Staff | Login / Bottom Nav ("Dashboard") | Seat Management / Reports | `GET /partner/metrics/today`, `GET /partner/seats/live` | Planned |
| 21 | `user /saloon-dashboard2.png` | Partner App | Salon Dashboard (Up Next Bookings & Analytics) | Salon Owner / Staff | Dashboard Scroll | Booking Action Sheet / Reports | `GET /partner/bookings/upcoming`, `GET /partner/pulse` | Planned |
| 22 | `user /saloon-booking.png` | Partner App | Salon Bookings Management | Salon Owner / Staff | Bottom Nav ("Bookings") | Walk-in Modal / Booking Details | `GET /partner/bookings?date={}&status={}`, `POST /partner/walkin` | Planned |
| 23 | `user /saloon-seat-1.png` | Partner App | Seat Management (Mirror Wall Grid) | Salon Owner / Staff | Bottom Nav ("Seats") / Dashboard | Seat Status Toggle Modal | `GET /partner/seats`, `PATCH /partner/seats/:id/status` | Planned |
| 24 | `user /saloon-seat-2.png` | Partner App | Seat Management (Reception & Seat Availability) | Salon Owner / Staff | Seats Scroll | Seat Config Modal | `GET /partner/seats/summary` | Planned |
| 25 | `user /saloon-service.png` | Partner App | Services & Combos Management | Salon Owner / Manager | Bottom Nav ("Services") | Service Add/Edit Sheet | `GET /partner/services`, `PATCH /partner/services/:id/toggle` | Planned |
| 26 | `user /saloon-team.png` | Partner App | Team & Schedules Modal | Salon Owner / Manager | Salon Profile / Dashboard Action | Add Staff Sheet | `GET /partner/staff`, `POST /partner/staff` | Planned |
| 27 | `user /saloon-report.png` | Partner App | Reports & Business Insights Modal | Salon Owner / Manager | Dashboard Analytics / Profile | Export PDF / Filter Sheet | `GET /partner/reports?period={day\|week\|month}` | Planned |
| 28 | `user /saloon-profile.png` | Partner App | Salon Profile & Settings | Salon Owner | Bottom Nav ("Profile") | Staff / Reports / Services / Hours | `GET /partner/profile` | Planned |
| 29 | `ChatGPT Image Sep 30, 2026, 11_42_40 AM.png` | Storyboard Diagram | Customer & Partner App Storyboard Overview | All | N/A | N/A | High-level Flow Mapping | Reference Blueprint |
| 30 | `SLOT Admin Panel Workflow Blueprint.png` | Admin Panel | Admin Panel Blueprint & Web Screenshots | Super Admin / Ops / Support | Web Browser (`/admin`) | All 8 Admin Modules + Approval Flows | `GET /admin/dashboard`, `GET /admin/salons/pending`, etc. | Reference Blueprint |

---

## 3. Discovered Shared Design System Specification

### Color Palette
- **Primary Background**: Warm Off-White `#F8F5EE` (Cream background for mobile screens)
- **Primary Accent / Gold**: Warm Amber/Gold `#E5A900` / `#DAA520` (CTA buttons, step indicators, active badges)
- **Dark Neutral / Primary Text**: Deep Charcoal `#1C1917` (Headers, main titles, dark cards)
- **Secondary Text / Muted**: Warm Taupe `#65625C` / Light Charcoal `#78716C`
- **Card Background**: Pure White `#FFFFFF` with border `#EFECE6`
- **Dark Featured Card**: Obsidian `#181310` with Warm Gold accents `#E5A900`
- **Status Colors**:
  - **Available / Confirmed**: Emerald Green `#16A34A` / Background `#DCFCE7`
  - **Booked / Waiting / Pending**: Warm Amber `#CA8A04` / Background `#FEF9C3`
  - **In Service**: Electric Blue `#2563EB` / Background `#DBEAFE`
  - **Cleaning / Maintenance**: Warm Grey/Brown `#78716C` / Background `#F5F5F4`
  - **Destructive / Logout**: Crimson Red `#DC2626` / Background `#FEE2E2`

### Typography Hierarchy
- **Primary Font Family**: Plus Jakarta Sans / Inter
- **Screen Title (Large)**: 24px Bold, `#1C1917`, line-height 1.2
- **Section Eyebrow**: 11px Bold Uppercase, `#65625C`, letter-spacing 1.2px
- **Card Title**: 16px SemiBold, `#1C1917`
- **Body Text**: 14px Regular / Medium, `#65625C`
- **Price Tag**: 18px Bold `#1C1917` (Strikethrough old price 13px line-through `#A8A29E`)

### Component Specifications
- **Primary Buttons**: Full-width pill radius `28px`, height `52px`, gradient/solid gold `#E5A900`, black text `#1C1917` bold, right arrow trailing icon.
- **Segmented Control Tabs**: Container `#EFECE6` radius `16px`, active segment `#FFFFFF` radius `12px` with shadow or solid `#1C1917` pill.
- **Cards**: Surface `#FFFFFF`, border `1px solid #EFECE6`, corner radius `20px`, padding `16px`.
- **Bottom Navigation**: Floating/docked container `#FFFFFF`, top border `#EFECE6`, height `68px` + inset, active item highlighted with soft gold background pill `#FDF8EA` and `#E5A900` icon.

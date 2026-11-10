# Screen & Navigation Flow Map - SLOT Platform

This document outlines the complete screen-to-screen navigation flows for **Customer App**, **Salon / Partner App**, and **Admin Panel**, including cross-app interactions based on the storyboard blueprint (`ChatGPT Image Sep 30, 2026, 11_42_40 AM.png` and `SLOT Admin Panel Workflow Blueprint.png`).

---

## 1. Customer App Flow (Discover → Book → Confirm → Manage)

```mermaid
flowchart TD
    A[Launch App] --> B{First Time User?}
    B -- Yes --> C[Onboarding 1: Great Hair Days]
    C --> D[Onboarding 2: One Service or Ritual]
    D --> E[Onboarding 3: Pick Real Seat]
    E --> F[Login Modal: Phone OTP / Social]
    B -- No / Skip --> G[Home Screen]
    F --> G

    subgraph Home Tab Navigation
        G[Home Screen] -->|Gender Switch| G1[Men & Unisex / Women View]
        G -->|Tap Banner / Combo| H[Offers & Power Combos]
        G -->|Tap Search / Explore| I[Explore Salons & Map]
        G -->|Tap Profile Icon| J[User Profile]
    end

    subgraph Booking Journey
        G -->|Tap Salon / Service| K[Salon Details Screen]
        I -->|Tap Salon Card| K
        K -->|Tap 'Book Chair'| L[Book Chair Step 1: Select Services]
        L -->|Tap 'Choose Date & Time'| M[Book Chair Step 2: Date, Slot, Seat & Stylist]
        M -->|Tap 'Review'| N[Review Booking: Breakdown & 5-min Hold]
        N -->|Tap 'Confirm Booking'| O[Booking Confirmed Modal #MM2841]
        O -->|Tap 'Done'| P[My Bookings: Upcoming Tab]
    end

    subgraph Account & Management
        P -->|Tap Booking Card| Q[Booking Details & Actions]
        J -->|Tap My Bookings| P
        J -->|Tap Logout| F
    end
```

### Detailed Customer Step Breakdown
1. **Onboarding (Steps 1–3)**: `OnBoarding1.png` → `OnBoarding2.png` → `OnBoarding3.png`
   - Action: Swipe cards or tap "Continue →". Bottom button "I manage a salon" switches to Partner Onboarding.
2. **Login / Auth Modal**: `ogin.png`
   - Enter Phone (+91 98765 43210) → Receive OTP / Google Login / Apple Login → Enters main app.
3. **Home Screen**: `Male Dashboard1.png` / `Female Dashboard1.png`
   - Gender selector (Men & Unisex vs Women) dynamically updates hero banner, popular services, and recommendations.
   - Shows active booking banner if booking exists (`Confirmed: Maison Muse 4:15 PM`).
4. **Explore & Search**: `Explore.png`
   - Live location map with custom salon pins, search bar with filter chips (`Nearby`, `Top rated`, `Open now`, `Under ₹500`).
5. **Salon Details**: `user /saloon detail.png`
   - Salon banner image, name, rating (4.9), distance (0.8km), operating hours, service menu list.
6. **Book Chair - Step 1 (Services)**: `BookChair.png`
   - Select multiple services (e.g. Signature Haircut ₹399 + Beard Sculpt ₹249), live duration counter (45 min) and price total (₹648).
7. **Book Chair - Step 2 (Slot, Seat & Stylist)**: `Book Chair2.png`
   - Date picker pills (Sun 28, Mon 29, Tue 30...)
   - Time slot pills (3:30 PM, 4:00 PM Full, 4:15 PM selected...)
   - Physical seat selection pills (Seat 1, Seat 2, Seat 3, Seat 4)
   - Preferred stylist selection (Arjun, Maya, No preference)
8. **Review Booking**: `Book Detail.png`
   - Full summary (Services, Date, Time, Seat, Stylist, Payment mode: Pay at salon, Total ₹648).
   - Dynamic 5-minute seat hold timer banner ("Your seat and slot are held for 5 minutes").
9. **Booking Confirmed Modal**: `Confirmation.png`
   - Green checkmark animation, reference ID `#MM2841`, arrival instructions, "Done" button leading to My Bookings.
10. **My Bookings**: `Booking.png`
    - Segmented tabs: `Upcoming`, `Completed`, `Cancelled`.

---

## 2. Salon / Partner App Flow (Dashboard → Bookings → Live Floor → Services → Reports)

```mermaid
flowchart TD
    PA[Partner Launch / Switch Role] --> PB[Partner Login / Salon Switcher]
    PB --> PC[Salon Dashboard: Live Floor & Metrics]

    subgraph Partner Core Operations
        PC -->|Tap Revenue / Pulse| PD[Reports & Insights Modal]
        PC -->|Tap Live Floor / Manage| PE[Seat Management: Mirror Wall Grid]
        PC -->|Tap Bookings Tab| PF[18 Bookings List & Filter]
        PC -->|Tap Services Tab| PG[Services & Combos Menu Toggle]
        PC -->|Tap Profile Tab| PH[Salon Profile & Staff Management]
    end

    subgraph Real-Time Salon Actions
        PF -->|Tap '+ Add Walk-in'| PI[Walk-in Booking Modal]
        PF -->|Tap Booking Action| PJ[Assign Seat / Start Service / Mark Complete]
        PE -->|Tap Seat Card| PK[Seat Status Change: Available / Reserved / In Service / Cleaning]
        PH -->|Tap Staff & Schedules| PL[Team & Schedules Modal + Add Staff]
    end
```

### Detailed Partner Step Breakdown
1. **Salon Dashboard**: `user /saloon-dashboard1.png` & `user /saloon-dashboard2.png`
   - Header: `Maison Muse · LIVE`, Revenue counter (`₹18,640` +14% vs last week).
   - Live Metric Tiles: 18 Bookings, 4 Available seats, 3 Waiting, 5 In service.
   - Quick Seat Status Carousel (Seats 01, 02, 03, 04 status preview).
   - "Up Next" Queue cards with 3-dot action menus.
2. **Bookings List**: `user /saloon-booking.png`
   - Date banner (`SUNDAY · 28 SEP`), status filter chips (`All`, `Waiting`, `In service`, `Done`).
   - Hourly grouped timeline view (4 PM block, 5 PM block).
   - Action buttons: Assign seat, Start service, Mark completed, Cancel.
   - Floating CTA: `+ Add walk-in`.
3. **Seat Management (Live Floor)**: `user /saloon-seat-1.png` & `user /saloon-seat-2.png`
   - Visual floor plan mapped to physical "MIRROR WALL" and "RECEPTION".
   - Interactive seat tiles showing Seat #, Current Status (`Available`, `Booked`, `In service`, `Reserved`, `Cleaning`), Customer Name & ETA.
   - Live indicator: `2 seats available · Next opening at 4:45 PM`.
4. **Services & Combos Menu**: `user /saloon-service.png`
   - Toggle switch for instant availability of services (Signature Haircut, Beard Sculpt, Hydra Hair Spa, Glow Facial).
   - Featured Combo cards ("The Headliner" 3 services · 90 min · ₹1,299).
5. **Team & Schedules**: `user /saloon-team.png`
   - Counter metrics: 7 On shift, 3 Available, 14 Jobs today.
   - Staff list cards with shift status (`Available`, `In service`, `Break`) & job counts.
   - CTA: `+ Add staff member`.
6. **Reports & Analytics**: `user /saloon-report.png`
   - Period selector: `Day`, `Week`, `Month`.
   - Revenue chart, total bookings (126), most popular service, top combo, peak hours (5:00 - 7:00 PM), repeat customer rate (68%).
7. **Salon Profile**: `user /saloon-profile.png`
   - Cover photo, rating (4.9 · 2,841 reviews), quick access menu to Staff, Reports, Services, Salon Details & Hours.

---

## 3. Admin Panel & Cross-System Workflows

```mermaid
flowchart TD
    subgraph Admin Web App Modules
        AD[Admin Login] --> ADB[Admin Dashboard]
        ADB --> AD1[1. Platform Overview & Metrics]
        ADB --> AD2[2. Salon Management]
        ADB --> AD3[3. User Management]
        ADB --> AD4[4. Booking Management]
        ADB --> AD5[5. Services Management]
        ADB --> AD6[6. Offers & Coupons]
        ADB --> AD7[7. Reports & Analytics]
    end

    subgraph Cross-App Flow 1: Salon Onboarding
        SO1[Salon Owner Submits Application] -->|Partner App| AD2
        AD2 -->|Admin Reviews Photos, Docs & Location| SO2{Decision}
        SO2 -- Approve --> SO3[Salon Status set to Active & Visible to Customers]
        SO2 -- Request Changes / Reject --> SO4[Notification to Salon Owner]
    end

    subgraph Cross-App Flow 2: Booking Lifecycle & Issue Resolution
        CU1[Customer Books Chair] -->|Hold 5 min| SB[Salon App Receives Booking]
        CU2[Customer Raises Issue / Cancel] --> AD4
        AD4 -->|Admin Reviews & Takes Action| AD4A[Approve Refund / Reschedule / Cancel]
        AD4A -->|Push Notification & Socket Event| CU3[Customer & Salon App Updated]
    end
```

### Key Admin Modules & Roles
1. **Super Admin**: Full platform access, manage salon approvals, users, platform settings, view financial reports.
2. **Operations Admin**: Manage salon onboarding approvals, monitor live bookings, service catalog.
3. **Support Admin**: Handle customer issue resolution, refunds, booking cancellations, user management.
4. **Marketing Admin**: Create & control global promotional banners, power combos, coupon codes.

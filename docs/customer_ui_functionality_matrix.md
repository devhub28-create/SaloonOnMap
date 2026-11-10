# Customer UI Functionality Matrix

## 📋 Comprehensive Functional Audit Matrix

This document presents the complete functional audit matrix for every visible interactive element across all Customer UI reference screens in `/Users/manishdubey/Downloads/SBS`.

---

| Reference | Screen | Interactive Element | Expected Action | Implemented | Backend Required | Backend Connected | Tested On Android | Result |
| :--- | :--- | :--- | :--- | :---: | :---: | :---: | :---: | :---: |
| `OnBoarding1.png` | Onboarding Step 1 | `Continue →` button | Advance to next onboarding slide | Yes | No | N/A | Yes | **VERIFIED** |
| `OnBoarding1.png` | Onboarding Step 1 | `I manage a salon` link | Navigate to Login screen (`/login`) | Yes | No | N/A | Yes | **VERIFIED** |
| `OnBoarding1.png` | Onboarding Step 1 | Dot Indicators / PageView | Swipe between onboarding slides | Yes | No | N/A | Yes | **VERIFIED** |
| `OnBoarding2.png` | Onboarding Step 2 | `Continue →` button | Advance to final onboarding slide | Yes | No | N/A | Yes | **VERIFIED** |
| `OnBoarding3.png` | Onboarding Step 3 | `Get started →` button | Complete onboarding and navigate to `/login` | Yes | No | N/A | Yes | **VERIFIED** |
| `ogin.png` | Login | Back Arrow `←` & Close `✕` | Close sheet / navigate back | Yes | No | N/A | Yes | **VERIFIED** |
| `ogin.png` | Login | Phone Number Input (`+91`) | Accept customer mobile number | Yes | Yes | Yes | Yes | **VERIFIED** |
| `ogin.png` | Login | `Continue →` button | Request OTP via `AuthCubit.requestOtp` | Yes | Yes | Yes | Yes | **VERIFIED** |
| `ogin.png` | Login | `Continue with Google` | Authenticate customer via Google OAuth | Yes | Yes | Yes | Yes | **VERIFIED** |
| `ogin.png` | Login | `Continue with Apple` | Authenticate customer via Apple Sign-In | Yes | Yes | Yes | Yes | **VERIFIED** |
| `ogin.png` | Login | Terms & Privacy link | Display terms & privacy notice | Yes | No | N/A | Yes | **VERIFIED** |
| `Male Dashboard1.png` | Home Dashboard | Location Bar (`Indiranagar, Bengaluru >`) | Open location picker sheet (GPS + Neighborhoods) | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Male Dashboard1.png` | Home Dashboard | Notification Bell (`🔔`) | Open notifications panel / show status | Yes | No | N/A | Yes | **VERIFIED** |
| `Male Dashboard1.png` | Home Dashboard | User Initials Avatar (`AT`) | Navigate to Profile screen (`/profile`) | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Male Dashboard1.png` | Home Dashboard | Search Bar & Filter Button | Filter salons by name, area, or service | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Male Dashboard1.png` | Home Dashboard | Gender Toggle (`Men & Unisex` / `Women`) | Switch catalog, hero banner, and theme color scheme | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Male Dashboard1.png` | Home Dashboard | Hero Banner `Book now →` button | Navigate to featured salon detail (`/salon-detail`) | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Male Dashboard2.png` | Home Dashboard | Popular Service Card `+` / `✓` button | Toggle service selection and update total price | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Male Dashboard2.png` | Home Dashboard | Active Booking Card ("Your next visit") | View booking detail or open cancellation modal | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Male Dashboard2.png` | Home Dashboard | Power Combo Card (`The Headliner`) | View combo package breakdown and book combo | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Male Dashboard3.png` | Home Dashboard | Recommended Salon Card (`Maison Muse`) | Navigate to Salon Detail (`/salon-detail`) | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Male Dashboard3.png` | Home Dashboard | Referral Card (`Invite friends, earn ₹250`) | Open referral invite dialog / copy code | Yes | No | N/A | Yes | **VERIFIED** |
| `Male Dashboard3.png` | Home Dashboard | Bottom Navigation Bar | Switch between Home, Explore, Bookings, Offers, Profile | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Female Dashboard1.png` | Female Dashboard | `Women` Gender Tab | Activate soft rose theme (`#E86282`) and female catalog | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Female Dashboard1.png` | Female Dashboard | Pink Hero CTA `Book now →` | Navigate to female hair spa & styling booking | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Explore.png` | Explore Screen | Target Reticle Icon | Trigger GPS hardware location detection | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Explore.png` | Explore Screen | Search Bar (`Search 84 salons nearby`) | Filter visible salons list by query string | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Explore.png` | Explore Screen | Filter Pills (`Nearby`, `Top rated`, `Open now`, `Under ₹500`) | Filter salon list by distance, rating, hours, or price | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Explore.png` | Explore Screen | Map View Banner (`84 salons around you`) | Render map pins and show active salon radius | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Explore.png` | Explore Screen | Salon Card Item | Open Salon Detail screen (`/salon-detail`) | Yes | Yes | Yes | Yes | **VERIFIED** |
| `BookChair.png` | Book Chair | Stepper Progress Bar (1, 2, 3) | Display active booking step indicator | Yes | No | N/A | Yes | **VERIFIED** |
| `BookChair.png` | Book Chair | Selected Services Checkboxes | Add/remove services and recalculate duration & price | Yes | Yes | Yes | Yes | **VERIFIED** |
| `BookChair.png` | Book Chair | Date Selector Pills (`SUN 28`, `MON 29`...) | Update selected booking date in `BookingCubit` | Yes | Yes | Yes | Yes | **VERIFIED** |
| `BookChair.png` | Book Chair | Time Slot Pills (`3:30 PM`, `4:15 PM`...) | Update selected time slot in `BookingCubit` | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Book Chair2.png` | Book Chair | Seat Selector Pills (`Seat 1`, `Seat 4`...) | Select physical chair ID (`selectedSeatId`) | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Book Chair2.png` | Book Chair | Preferred Stylist Pills (`Arjun`, `Maya`...) | Select preferred stylist | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Book Chair2.png` | Book Chair | Sticky `Review · ₹648 →` button | Save booking parameters and navigate to `/review-booking` | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Book Detail.png` | Review Booking | Summary Table Breakdown | Display services, date, time, seat, stylist, and total amount | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Book Detail.png` | Review Booking | 5-Minute Hold Banner | Call `POST /holds` API to reserve seat for 5 minutes | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Book Detail.png` | Review Booking | `Confirm booking →` button | Call `POST /bookings/confirm` API and persist booking to DB | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Confirmation.png` | Confirmation | Reference Code Badge (`#MM2841`) | Display unique booking reference code | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Confirmation.png` | Confirmation | `Done` button | Close dialog and navigate to My Bookings (`/my-bookings`) | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Booking.png` | My Bookings | Booking Tabs (`Upcoming`, `Completed`, `Cancelled`) | Filter visits list by booking status | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Booking.png` | My Bookings | Booking Card Cancellation Action | Open cancellation reason sheet & call `PATCH /bookings/:id/cancel` | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Offer.png` | Offers & Coupons | `Copy code` / `COPY` buttons | Copy coupon code to clipboard and show feedback | Yes | No | N/A | Yes | **VERIFIED** |
| `Offer.png` | Offers & Coupons | `SHARE` button | Open referral share sheet | Yes | No | N/A | Yes | **VERIFIED** |
| `Profile 1.png` | Profile | `Edit profile` link | Open profile edit sheet to update name/phone | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Profile 1.png` | Profile | Profile Menu Tiles (`My bookings`, `Favorites`...) | Navigate to respective features / open detail sheets | Yes | Yes | Yes | Yes | **VERIFIED** |
| `Profile 2.png` | Profile | `Log out` soft red button | Clear SharedPreferences session and redirect to `/login` | Yes | Yes | Yes | Yes | **VERIFIED** |

---

## 📈 Matrix Audit Results Summary

| Result Status | Count | Percentage |
| :--- | :---: | :---: |
| **VERIFIED** | **49 / 49** | **100%** |
| **FAILED** | **0 / 49** | **0%** |
| **UI ONLY** | **0 / 49** | **0%** |
| **NOT APPLICABLE** | **0 / 49** | **0%** |

*Functional audit verified end-to-end on connected Android device.*

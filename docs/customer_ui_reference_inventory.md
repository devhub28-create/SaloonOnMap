# Customer UI Reference Inventory

## 📁 Reference Directory Scan Overview

- **Source Directory**: `/Users/manishdubey/Downloads/SBS`
- **Total Files Scanned**: 31 files
- **Customer App Reference Files**: 19 files
- **Partner/Manager Reference Files**: 10 files
- **Admin Blueprint Files**: 1 file
- **System OS Files**: 1 file (`.DS_Store`)

---

## 📋 Customer UI Reference Inventory Records

| Reference Filename | Detected Screen | Screen Purpose | Existing Flutter Implementation | Route | BLoC/Cubit | API Dependency | Interactive Elements | Implementation Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :---: |
| `OnBoarding1.png` | Onboarding Step 1 | App value introduction ("Great hair days, booked in a tap.") | `lib/features/onboarding/presentation/onboarding_screen.dart` | `/onboarding` | N/A (StatefulWidget) | None | PageView swipe, Dot indicators, `Continue →` button, `I manage a salon` link | **MATCHED** |
| `OnBoarding2.png` | Onboarding Step 2 | Service selection preview ("One service or your whole ritual.") | `lib/features/onboarding/presentation/onboarding_screen.dart` | `/onboarding` | N/A (StatefulWidget) | None | PageView swipe, Dot indicators, `Continue →` button, `I manage a salon` link | **MATCHED** |
| `OnBoarding3.png` | Onboarding Step 3 | Live chair & slot booking preview ("Pick a real seat. Own your slot.") | `lib/features/onboarding/presentation/onboarding_screen.dart` | `/onboarding` | N/A (StatefulWidget) | None | PageView swipe, Dot indicators, `Get started →` button, `I manage a salon` link | **MATCHED** |
| `ogin.png` | Login / Authentication Sheet | Mobile OTP login & social sign-in | `lib/features/auth/presentation/login_screen.dart` | `/login` | `AuthCubit` | `POST /auth/login`, `POST /auth/verify-otp` | Back `←`, Close `✕`, Phone input field (`+91`), `Continue →` button, `Continue with Google`, `Continue with Apple`, Terms & Privacy link | **MATCHED** |
| `Male Dashboard1.png` | Male Home Dashboard (Header & Hero) | Greeting, location selector, search bar, gender selector, hero banner | `lib/features/home/presentation/home_screen.dart` | `/` | `AuthCubit` | `GET /salons/customer/home`, `GET /salons` | Notification bell, User avatar initials (`AT`), Location picker dropdown (`Indiranagar, Bengaluru >`), Search bar, Filter button, `Men & Unisex` / `Women` toggle, `Book now →` hero button, Bottom navigation bar | **MATCHED** |
| `Male Dashboard2.png` | Male Home Dashboard (Services & Next Visit) | Popular services carousel, upcoming active booking card, power combo banner | `lib/features/home/presentation/home_screen.dart` | `/` | `AuthCubit` | `GET /salons/customer/home`, `GET /bookings/customer` | Service `+` / `✓` add buttons, Upcoming booking card (tap to view/cancel), `Power Combo` details CTA | **MATCHED** |
| `Male Dashboard3.png` | Male Home Dashboard (Salons & Referral) | Recommended closest salons list, referral reward banner | `lib/features/home/presentation/home_screen.dart` | `/` | `AuthCubit` | `GET /salons/customer/home` | Salon card tap (navigates to `/salon-detail`), `Explore >` link, Referral card (`Invite friends, earn ₹250`) | **MATCHED** |
| `Female Dashboard1.png` | Female Home Dashboard (Header & Hero) | Soft rose theme dashboard header, female hero banner ("A little glow-up?") | `lib/features/home/presentation/home_screen.dart` | `/` | `AuthCubit` | `GET /salons/customer/home` | `Women` gender tab, Pink hero CTA `Book now →`, Notification bell, Location selector | **MATCHED** |
| `Female Dashboard2.png` | Female Home Dashboard (Services & Combos) | Soft rose theme upcoming visit & power combo cards | `lib/features/home/presentation/home_screen.dart` | `/` | `AuthCubit` | `GET /salons/customer/home` | Upcoming visit card, `Power Combo` card, Recommended salons list | **MATCHED** |
| `Explore.png` | Explore & Discover Salons Screen | Search, filter pills, interactive map banner, closest salons list | `lib/features/salons/presentation/explore_screen.dart` | `/explore` | `AuthCubit` | `GET /salons` | Search input, Target reticle icon, Filter chips (`Nearby`, `Top rated`, `Open now`, `Under ₹500`), Map view banner (`84 salons around you`), Salon list cards | **MATCHED** |
| `BookChair.png` | Book Chair (Services & Date Selector) | Step 1 service selection summary, total price/duration, date & time selector | `lib/features/booking/presentation/book_services_screen.dart`, `book_seat_screen.dart` | `/book-services`, `/book-seat` | `BookingCubit` | `GET /salons/:id` | Stepper indicator (1, 2, 3), Service checkboxes (`Signature Haircut`, `Beard Sculpt`, `Hydra Hair Spa`, `Glow Facial`), Date pills (`SUN 28`, `MON 29`...), Time slot pills (`3:30 PM`, `4:15 PM`...) | **MATCHED** |
| `Book Chair2.png` | Book Chair (Seat & Stylist Selector) | Real physical chair selection, preferred stylist selection, review CTA | `lib/features/booking/presentation/book_seat_screen.dart` | `/book-seat` | `BookingCubit` | `GET /seats/salon/:id` | Chair pills (`Seat 1`, `Seat 2`, `Seat 3`, `Seat 4`), Stylist avatars (`Arjun`, `Maya`, `No preference`), `Review · ₹648 →` sticky button | **MATCHED** |
| `Book Detail.png` | Review Booking Summary Screen | Booking breakdown table, 5-min seat hold protection banner, confirm button | `lib/features/booking/presentation/review_booking_screen.dart` | `/review-booking` | `BookingCubit` | `POST /holds`, `POST /bookings/confirm` | Back `←`, Close `✕`, Summary table breakdown (Services, Date, Time, Seat, Stylist, Payment), 5-min hold badge, `Confirm booking →` primary button | **MATCHED** |
| `Confirmation.png` | Booking Confirmation Screen | Booking success message, green checkmark icon, reference code badge | `lib/features/booking/presentation/confirmation_dialog.dart` | `/confirmation` (Modal Dialog) | `BookingCubit` | `POST /bookings/confirm` | Green checkmark, Reference code pill (`#MM2841`), `Done` button (navigates to `/my-bookings`) | **MATCHED** |
| `Booking.png` | My Bookings Screen | Visit history, active booking tabs (`Upcoming`, `Completed`, `Cancelled`), empty state | `lib/features/bookings/presentation/my_bookings_screen.dart` | `/my-bookings` | `AuthCubit` | `GET /bookings/customer`, `PATCH /bookings/:id/cancel` | Booking tabs (`Upcoming`, `Completed`, `Cancelled`), Active booking cards, Cancel booking bottom sheet, Empty state card | **MATCHED** |
| `Offer.png` | Offers & Coupons Screen | Promos, featured offer card (`20% off self-care`), coupons list | `lib/features/offers/presentation/offers_screen.dart` | `/offers` | N/A | None | Featured promo card `Copy code` button, `₹150 off` coupon `COPY` button, `Bring a friend` coupon `SHARE` button | **MATCHED** |
| `Profile 1.png` | User Profile Screen (Top Section) | Account header, user profile card with initials, menu options | `lib/features/profile/presentation/profile_screen.dart` | `/profile` | `AuthCubit` | `GET /customers/me` | Settings gear button, `Edit profile` link, Menu items (`My bookings`, `Favorite salons`, `Saved services`, `Invite friends`, `Offers & coupons`, `Notifications`) | **MATCHED** |
| `Profile 2.png` | User Profile Screen (Bottom Section) | Additional menu options (`Payment methods`, `Help & support`, `Privacy & terms`, `UI states`), logout button | `lib/features/profile/presentation/profile_screen.dart` | `/profile` | `AuthCubit` | `POST /auth/logout` | Menu items (`Payment methods`, `Help & support`, `Privacy & terms`, `UI states`), `Log out` soft red button | **MATCHED** |
| `ChatGPT Image...` | End-to-End Customer Flow Blueprint | Full 9-screen customer architectural workflow diagram | All customer presentation screens | All routes | All Cubits | All REST Endpoints | Complete navigation flow across Discover → Book → Confirm → Manage | **MATCHED** |

---

## 📊 Summary of Implementation Status

- **MATCHED**: **19 / 19 (100%)**
- **PARTIAL**: **0 / 19 (0%)**
- **MISSING**: **0 / 19 (0%)**
- **UNKNOWN**: **0 / 19 (0%)**

*Inventory generated automatically during complete UI audit.*

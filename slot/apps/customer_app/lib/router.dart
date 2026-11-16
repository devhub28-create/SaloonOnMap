import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/onboarding/presentation/onboarding_screen.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/salons/presentation/explore_screen.dart';
import 'features/salons/presentation/salon_detail_screen.dart';
import 'features/booking/presentation/book_services_screen.dart';
import 'features/booking/presentation/book_seat_screen.dart';
import 'features/booking/presentation/review_booking_screen.dart';
import 'features/bookings/presentation/my_bookings_screen.dart';
import 'features/offers/presentation/offers_screen.dart';
import 'features/profile/presentation/profile_screen.dart';

// Profile internal screens
import 'features/profile/presentation/screens/edit_profile_screen.dart';
import 'features/profile/presentation/screens/settings_screen.dart';
import 'features/profile/presentation/screens/favorite_salons_screen.dart';
import 'features/profile/presentation/screens/invite_friends_screen.dart';
import 'features/profile/presentation/screens/notifications_screen.dart';
import 'features/profile/presentation/screens/payment_methods_screen.dart';
import 'features/profile/presentation/screens/help_support_screen.dart';
import 'features/profile/presentation/screens/privacy_terms_screen.dart';
import 'features/ai_style_studio/presentation/ai_style_studio_screen.dart';
import 'features/ai_style_studio/presentation/saved_looks_screen.dart';

GoRouter createCustomerRouter(AuthCubit authCubit) {
  return GoRouter(
    initialLocation: authCubit.isAuthenticated ? '/' : '/login',
    refreshListenable: _BlocListenable(authCubit),
    redirect: (context, state) {
      final isAuthenticated = authCubit.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Always permit viewing login/signup screen when navigated to
      if (isLoggingIn) {
        return null;
      }

      if (!isAuthenticated && !isOnboarding) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
          path: '/explore', builder: (context, state) => const ExploreScreen()),
      GoRoute(
        path: '/salon-detail',
        builder: (context, state) => SalonDetailScreen(
          salonData: state.extra is Map
              ? Map<String, dynamic>.from(state.extra as Map)
              : null,
        ),
      ),
      GoRoute(
          path: '/book-services',
          builder: (context, state) => const BookServicesScreen()),
      GoRoute(
          path: '/book-seat',
          builder: (context, state) => const BookSeatScreen()),
      GoRoute(
          path: '/review-booking',
          builder: (context, state) => const ReviewBookingScreen()),
      GoRoute(
          path: '/my-bookings',
          builder: (context, state) => const MyBookingsScreen()),
      GoRoute(
          path: '/offers', builder: (context, state) => const OffersScreen()),
      GoRoute(
          path: '/profile', builder: (context, state) => const ProfileScreen()),

      // Profile internal sub-routes
      GoRoute(
          path: '/profile/edit',
          builder: (context, state) => const EditProfileScreen()),
      GoRoute(
          path: '/profile/settings',
          builder: (context, state) => const SettingsScreen()),
      GoRoute(
          path: '/profile/favorites',
          builder: (context, state) => const FavoriteSalonsScreen()),
      GoRoute(
          path: '/profile/invite',
          builder: (context, state) => const InviteFriendsScreen()),
      GoRoute(
          path: '/profile/notifications',
          builder: (context, state) => const NotificationsScreen()),
      GoRoute(
          path: '/profile/payment-methods',
          builder: (context, state) => const PaymentMethodsScreen()),
      GoRoute(
          path: '/profile/help',
          builder: (context, state) => const HelpSupportScreen()),
      GoRoute(
          path: '/profile/privacy',
          builder: (context, state) => const PrivacyTermsScreen()),
      GoRoute(
          path: '/ai-style-studio',
          builder: (context, state) => const AiStyleStudioScreen()),
      GoRoute(
          path: '/saved-ai-looks',
          builder: (context, state) => const SavedLooksScreen()),
    ],
  );
}

class _BlocListenable extends ChangeNotifier {
  _BlocListenable(AuthCubit cubit) {
    cubit.stream.listen((_) {
      notifyListeners();
    });
  }
}

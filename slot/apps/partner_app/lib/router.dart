import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:design_system/design_system.dart';

import 'features/auth/cubit/partner_auth_cubit.dart';
import 'features/auth/presentation/partner_login_screen.dart';
import 'features/auth/presentation/partner_register_screen.dart';
import 'features/auth/presentation/pending_approval_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/bookings/presentation/bookings_screen.dart';
import 'features/seats/presentation/seats_screen.dart';
import 'features/services/presentation/services_screen.dart';
import 'features/profile/presentation/profile_screen.dart';
import 'features/profile/presentation/salon_details_screen.dart';
import 'features/reports/presentation/reports_screen.dart';
import 'features/team/presentation/team_screen.dart';
import 'features/profile/presentation/partner_support_screen.dart';
import 'features/profile/presentation/partner_notifications_screen.dart';

class PartnerShellScaffold extends StatelessWidget {
  final Widget child;
  final String location;
  const PartnerShellScaffold({
    super.key,
    required this.child,
    required this.location,
  });

  int get _currentIndex => switch (location) {
        '/bookings' => 1,
        '/seats' => 2,
        '/services' => 3,
        '/profile' => 4,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: SlotBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) context.go('/');
          if (index == 1) context.go('/bookings');
          if (index == 2) context.go('/seats');
          if (index == 3) context.go('/services');
          if (index == 4) context.go('/profile');
        },
        items: const [
          SlotNavItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
          SlotNavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
          SlotNavItem(icon: Icons.event_seat_rounded, label: 'Seats'),
          SlotNavItem(icon: Icons.content_cut_rounded, label: 'Services'),
          SlotNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

GoRouter createPartnerRouter(PartnerAuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isAuthScreen = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isPendingScreen = state.matchedLocation == '/pending';

      if (authState is PartnerUnauthenticated && !isAuthScreen) {
        return '/login';
      }

      if (authState is PartnerAuthenticated && isAuthScreen) {
        return '/';
      }

      if (authState is PartnerPendingApproval && !isPendingScreen) {
        return '/pending';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const PartnerLoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const PartnerRegisterScreen(),
      ),
      GoRoute(
        path: '/pending',
        builder: (context, state) {
          final authState = authCubit.state;
          return PendingApprovalScreen(
            state: authState as PartnerPendingApproval,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) => PartnerShellScaffold(
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: '/bookings',
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const BookingsScreen()),
          ),
          GoRoute(
            path: '/seats',
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const SeatsScreen()),
          ),
          GoRoute(
            path: '/services',
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const ServicesScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                _noTransitionPage(state, const PartnerProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/partner/reports',
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: '/partner/team',
        builder: (context, state) => const TeamScreen(),
      ),
      GoRoute(
        path: '/partner/salon-details',
        builder: (context, state) => const SalonDetailsScreen(),
      ),
      GoRoute(
        path: '/partner/support',
        builder: (context, state) => const PartnerSupportScreen(),
      ),
      GoRoute(
        path: '/partner/notifications',
        builder: (context, state) => const PartnerNotificationsScreen(),
      ),
    ],
  );
}

Page<void> _noTransitionPage(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/cubit/admin_auth_cubit.dart';
import 'features/auth/presentation/admin_login_screen.dart';
import 'layout/admin_layout.dart';
import 'features/dashboard/presentation/admin_dashboard_screen.dart';
import 'features/salons/presentation/admin_salons_screen.dart';
import 'features/users/presentation/admin_users_screen.dart';
import 'features/bookings/presentation/admin_bookings_screen.dart';
import 'features/audit_logs/presentation/admin_audit_logs_screen.dart';
import 'features/offers/presentation/admin_offers_screen.dart';
import 'features/reviews/presentation/admin_reviews_screen.dart';
import 'features/notifications/presentation/admin_notifications_screen.dart';
import 'features/ai_operations/presentation/admin_ai_operations_screen.dart';
import 'features/analytics/presentation/admin_analytics_screen.dart';
import 'features/support/presentation/admin_support_screen.dart';
import 'features/system_health/presentation/admin_system_health_screen.dart';
import 'core/auth/admin_permissions.dart';

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

GoRouter createAdminRouter(AdminAuthCubit authCubit) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authCubit.stream),
    redirect: (context, state) {
      final authState = authCubit.state;
      final isLoggingIn = state.matchedLocation == '/login';

      if (authState is AdminUnauthenticated && !isLoggingIn) {
        return '/login';
      }

      if (authState is AdminAuthenticated && isLoggingIn) {
        return '/';
      }

      if (authState is AdminAuthenticated &&
          !isLoggingIn &&
          !AdminPermissions.canViewRoute(
              authState.role, state.matchedLocation)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminLayout(child: child),
        routes: [
          GoRoute(
              path: '/',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminDashboardScreen())),
          GoRoute(
              path: '/salons',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminSalonsScreen())),
          GoRoute(
              path: '/users',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminUsersScreen())),
          GoRoute(
              path: '/bookings',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminBookingsScreen())),
          GoRoute(
              path: '/offers',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminOffersScreen())),
          GoRoute(
              path: '/reviews',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminReviewsScreen())),
          GoRoute(
              path: '/notifications',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminNotificationsScreen())),
          GoRoute(
              path: '/ai-operations',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminAiOperationsScreen())),
          GoRoute(
              path: '/analytics',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminAnalyticsScreen())),
          GoRoute(
              path: '/support',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminSupportScreen())),
          GoRoute(
              path: '/system-health',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminSystemHealthScreen())),
          GoRoute(
              path: '/audit-logs',
              pageBuilder: (context, state) =>
                  _noTransitionPage(state, const AdminAuditLogsScreen())),
        ],
      ),
    ],
  );
}

Page<void> _noTransitionPage(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

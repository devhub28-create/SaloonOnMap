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
              builder: (context, state) => const AdminDashboardScreen()),
          GoRoute(
              path: '/salons',
              builder: (context, state) => const AdminSalonsScreen()),
          GoRoute(
              path: '/users',
              builder: (context, state) => const AdminUsersScreen()),
          GoRoute(
              path: '/bookings',
              builder: (context, state) => const AdminBookingsScreen()),
          GoRoute(
              path: '/audit-logs',
              builder: (context, state) => const AdminAuditLogsScreen()),
        ],
      ),
    ],
  );
}

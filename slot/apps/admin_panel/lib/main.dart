import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/admin_api_service.dart';
import 'features/auth/cubit/admin_auth_cubit.dart';
import 'features/dashboard/cubit/admin_dashboard_cubit.dart';
import 'features/salons/cubit/admin_salons_cubit.dart';
import 'features/users/cubit/admin_users_cubit.dart';
import 'features/bookings/cubit/admin_bookings_cubit.dart';
import 'features/audit_logs/cubit/admin_audit_logs_cubit.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final adminApiService = AdminApiService.instance;
  final adminAuthCubit = AdminAuthCubit(apiClient: adminApiService);
  adminApiService.onUnauthorized = adminAuthCubit.handleSessionExpired;
  adminAuthCubit.checkAuthStatus();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AdminAuthCubit>.value(value: adminAuthCubit),
        BlocProvider(
            create: (_) =>
                AdminDashboardCubit(apiClient: adminApiService)..fetchDashboard()),
        BlocProvider(
            create: (_) =>
                AdminSalonsCubit(apiClient: adminApiService)..fetchPendingSalons()),
        BlocProvider(
            create: (_) => AdminUsersCubit(apiClient: adminApiService)..fetchUsers()),
        BlocProvider(
            create: (_) =>
                AdminBookingsCubit(apiClient: adminApiService)..fetchBookings()),
        BlocProvider(
            create: (_) =>
                AdminAuditLogsCubit(apiClient: adminApiService)..fetchLogs()),
      ],
      child: SlotAdminPanelApp(authCubit: adminAuthCubit),
    ),
  );
}

class SlotAdminPanelApp extends StatelessWidget {
  final AdminAuthCubit authCubit;
  const SlotAdminPanelApp({super.key, required this.authCubit});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SLOT Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Plus Jakarta Sans',
      ),
      routerConfig: createAdminRouter(authCubit),
    );
  }
}

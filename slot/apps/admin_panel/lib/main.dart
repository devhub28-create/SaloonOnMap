import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'core/network/admin_api_service.dart';
import 'features/auth/cubit/admin_auth_cubit.dart';
import 'features/dashboard/cubit/admin_dashboard_cubit.dart';
import 'features/salons/cubit/admin_salons_cubit.dart';
import 'features/users/cubit/admin_users_cubit.dart';
import 'features/bookings/cubit/admin_bookings_cubit.dart';
import 'features/audit_logs/cubit/admin_audit_logs_cubit.dart';
import 'features/offers/cubit/admin_offers_cubit.dart';
import 'features/notifications/cubit/admin_notifications_cubit.dart';
import 'features/ai_operations/cubit/admin_ai_operations_cubit.dart';
import 'features/analytics/cubit/admin_analytics_cubit.dart';
import 'features/support/cubit/admin_support_cubit.dart';
import 'features/system_health/cubit/admin_system_health_cubit.dart';
import 'features/reviews/cubit/admin_reviews_cubit.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final adminApiService = AdminApiService.instance;
  final adminAuthCubit = AdminAuthCubit(apiClient: adminApiService);
  adminApiService.onUnauthorized = adminAuthCubit.handleSessionExpired;
  await adminAuthCubit.checkAuthStatus();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AdminAuthCubit>.value(value: adminAuthCubit),
        BlocProvider(
            create: (_) => AdminDashboardCubit(apiClient: adminApiService)),
        BlocProvider(
            create: (_) => AdminSalonsCubit(apiClient: adminApiService)),
        BlocProvider(
            create: (_) => AdminUsersCubit(apiClient: adminApiService)),
        BlocProvider(
            create: (_) => AdminBookingsCubit(apiClient: adminApiService)),
        BlocProvider(
            create: (_) => AdminAuditLogsCubit(apiClient: adminApiService)),
        BlocProvider(
            create: (_) => AdminOffersCubit(apiClient: adminApiService)),
        BlocProvider(
            create: (_) => AdminNotificationsCubit(apiClient: adminApiService)),
        BlocProvider(
            create: (_) => AdminAiOperationsCubit(apiClient: adminApiService)),
        BlocProvider(
            create: (_) => AdminAnalyticsCubit(apiClient: adminApiService)),
        BlocProvider(
            create: (_) => AdminSupportCubit(apiClient: adminApiService)),
        BlocProvider(
            create: (_) => AdminSystemHealthCubit(apiClient: adminApiService)),
        BlocProvider(
            create: (_) => AdminReviewsCubit(apiClient: adminApiService)),
      ],
      child: AdminSessionDataLoader(
        child: SlotAdminPanelApp(authCubit: adminAuthCubit),
      ),
    ),
  );
}

class AdminSessionDataLoader extends StatefulWidget {
  final Widget child;

  const AdminSessionDataLoader({super.key, required this.child});

  @override
  State<AdminSessionDataLoader> createState() => _AdminSessionDataLoaderState();
}

class _AdminSessionDataLoaderState extends State<AdminSessionDataLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          context.read<AdminAuthCubit>().state is AdminAuthenticated) {
        _refreshAll();
      }
    });
  }

  void _refreshAll() {
    final authState = context.read<AdminAuthCubit>().state;
    if (authState is! AdminAuthenticated) return;
    final role = authState.role;
    context.read<AdminDashboardCubit>().fetchDashboard();
    if ({'ADMIN', 'SUPER_ADMIN', 'OPERATIONS_ADMIN', 'SUPPORT_ADMIN'}
        .contains(role)) {
      context.read<AdminUsersCubit>().fetchUsers();
      context.read<AdminBookingsCubit>().fetchBookings();
      context.read<AdminAuditLogsCubit>().fetchLogs();
      context.read<AdminReviewsCubit>().fetchReviews();
      context.read<AdminAiOperationsCubit>().fetchOperations();
      context.read<AdminSupportCubit>().fetch();
      context.read<AdminSystemHealthCubit>().fetch();
    }
    if ({'ADMIN', 'SUPER_ADMIN', 'OPERATIONS_ADMIN'}.contains(role)) {
      context.read<AdminSalonsCubit>().fetchSalons();
      context.read<AdminAnalyticsCubit>().fetchAnalytics();
    }
    if ({'ADMIN', 'SUPER_ADMIN', 'MARKETING_ADMIN'}.contains(role)) {
      context.read<AdminOffersCubit>().fetchOffers();
    }
    if ({'ADMIN', 'SUPER_ADMIN', 'OPERATIONS_ADMIN', 'MARKETING_ADMIN'}
        .contains(role)) {
      context.read<AdminNotificationsCubit>().fetchCampaigns();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AdminAuthCubit, AdminAuthState>(
      listenWhen: (previous, current) =>
          previous is! AdminAuthenticated && current is AdminAuthenticated,
      listener: (_, __) => _refreshAll(),
      child: widget.child,
    );
  }
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
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryGold,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.darkNeutral,
          secondary: AppColors.primaryGold,
          surface: Colors.white,
          error: AppColors.statusDestructiveText,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card),
            side: const BorderSide(color: AppColors.borderLight),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.primaryGoldDark, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.darkNeutral,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.darkNeutral,
          contentTextStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderLight,
          thickness: 1,
          space: 1,
        ),
      ),
      routerConfig: createAdminRouter(authCubit),
    );
  }
}

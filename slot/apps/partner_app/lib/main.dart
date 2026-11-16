import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/network/partner_api_service.dart';
import 'features/auth/cubit/partner_auth_cubit.dart';
import 'features/dashboard/cubit/partner_dashboard_cubit.dart';
import 'features/bookings/cubit/partner_bookings_cubit.dart';
import 'features/seats/cubit/partner_seats_cubit.dart';
import 'features/services/cubit/partner_services_cubit.dart';
import 'features/team/cubit/partner_team_cubit.dart';
import 'router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final partnerApiService = PartnerApiService.instance;
  final partnerAuthCubit = PartnerAuthCubit(apiClient: partnerApiService);
  partnerApiService.onUnauthorized = partnerAuthCubit.handleSessionExpired;
  partnerAuthCubit.checkAuthStatus();
  final partnerSeatsCubit = PartnerSeatsCubit(apiClient: partnerApiService)
    ..loadSeats(6);
  final partnerServicesCubit = PartnerServicesCubit(apiClient: partnerApiService)
    ..loadServices();
  final partnerTeamCubit = PartnerTeamCubit(apiClient: partnerApiService)..loadTeam();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<PartnerAuthCubit>.value(value: partnerAuthCubit),
        BlocProvider<PartnerSeatsCubit>.value(value: partnerSeatsCubit),
        BlocProvider<PartnerServicesCubit>.value(value: partnerServicesCubit),
        BlocProvider<PartnerTeamCubit>.value(value: partnerTeamCubit),
        BlocProvider(
            create: (_) =>
                PartnerDashboardCubit(apiClient: partnerApiService)..fetchDashboard()),
        BlocProvider(
            create: (_) =>
                PartnerBookingsCubit(apiClient: partnerApiService)..fetchBookings()),
      ],
      child: PartnerApp(authCubit: partnerAuthCubit),
    ),
  );
}

class PartnerApp extends StatelessWidget {
  final PartnerAuthCubit authCubit;
  const PartnerApp({super.key, required this.authCubit});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SalonOnMap Business',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Plus Jakarta Sans',
      ),
      routerConfig: createPartnerRouter(authCubit),
    );
  }
}

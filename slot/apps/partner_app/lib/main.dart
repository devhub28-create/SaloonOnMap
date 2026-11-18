import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:api_client/api_client.dart';

import 'core/network/partner_api_service.dart';
import 'features/auth/cubit/partner_auth_cubit.dart';
import 'features/dashboard/cubit/partner_dashboard_cubit.dart';
import 'features/bookings/cubit/partner_bookings_cubit.dart';
import 'features/seats/cubit/partner_seats_cubit.dart';
import 'features/services/cubit/partner_services_cubit.dart';
import 'features/team/cubit/partner_team_cubit.dart';
import 'router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseObservabilityService.initialize(appType: 'PARTNER');
  final partnerApiService = PartnerApiService.instance;
  final partnerAuthCubit = PartnerAuthCubit(apiClient: partnerApiService);
  partnerApiService.onUnauthorized = partnerAuthCubit.handleSessionExpired;
  await partnerAuthCubit.checkAuthStatus();
  final partnerSeatsCubit = PartnerSeatsCubit(apiClient: partnerApiService);
  final partnerServicesCubit = PartnerServicesCubit(
    apiClient: partnerApiService,
  );
  final partnerTeamCubit = PartnerTeamCubit(apiClient: partnerApiService);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<PartnerAuthCubit>.value(value: partnerAuthCubit),
        BlocProvider<PartnerSeatsCubit>.value(value: partnerSeatsCubit),
        BlocProvider<PartnerServicesCubit>.value(value: partnerServicesCubit),
        BlocProvider<PartnerTeamCubit>.value(value: partnerTeamCubit),
        BlocProvider(
          create: (_) => PartnerDashboardCubit(apiClient: partnerApiService),
        ),
        BlocProvider(
          create: (_) => PartnerBookingsCubit(apiClient: partnerApiService),
        ),
      ],
      child: PartnerSessionDataLoader(
        child: PartnerApp(authCubit: partnerAuthCubit),
      ),
    ),
  );
}

class PartnerSessionDataLoader extends StatefulWidget {
  final Widget child;
  const PartnerSessionDataLoader({super.key, required this.child});

  @override
  State<PartnerSessionDataLoader> createState() =>
      _PartnerSessionDataLoaderState();
}

class _PartnerSessionDataLoaderState extends State<PartnerSessionDataLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadAuthenticatedData(),
    );
  }

  void _loadAuthenticatedData() {
    if (!mounted) return;
    final authState = context.read<PartnerAuthCubit>().state;
    if (authState is! PartnerAuthenticated) return;
    final salonId = authState.salonId;
    context.read<PartnerDashboardCubit>().fetchDashboard(salonId: salonId);
    context.read<PartnerBookingsCubit>().fetchBookings(salonId: salonId);
    context.read<PartnerSeatsCubit>().loadSeats(
          authState.seatCount,
          salonId: salonId,
        );
    context.read<PartnerServicesCubit>().loadServices(salonId: salonId);
    context.read<PartnerTeamCubit>().loadTeam(salonId: salonId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PartnerAuthCubit, PartnerAuthState>(
      listenWhen: (previous, current) =>
          previous is! PartnerAuthenticated && current is PartnerAuthenticated,
      listener: (_, __) => _loadAuthenticatedData(),
      child: widget.child,
    );
  }
}

class PartnerApp extends StatelessWidget {
  final PartnerAuthCubit authCubit;
  const PartnerApp({super.key, required this.authCubit});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SalonOnMap Business',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Plus Jakarta Sans'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en', 'IN'), Locale('en', 'US')],
      routerConfig: createPartnerRouter(authCubit),
    );
  }
}

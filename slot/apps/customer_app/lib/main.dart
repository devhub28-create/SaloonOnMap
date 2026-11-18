import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:api_client/api_client.dart';

import 'core/network/customer_api_service.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/booking/cubit/booking_cubit.dart';
import 'features/ai_style_studio/cubit/ai_style_cubit.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseObservabilityService.initialize(appType: 'CUSTOMER');
  final customerApiService = CustomerApiService.instance;
  final preferences = await SharedPreferences.getInstance();
  final hasCompletedOnboarding =
      preferences.getBool('has_completed_onboarding') ?? false;
  final authCubit = AuthCubit(apiClient: customerApiService);
  customerApiService.onUnauthorized = authCubit.handleSessionExpired;
  await authCubit.checkSession();
  final bookingCubit = BookingCubit(apiClient: customerApiService);
  final aiStyleCubit = AiStyleCubit(apiClient: customerApiService);

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<BookingCubit>.value(value: bookingCubit),
        BlocProvider<AiStyleCubit>.value(value: aiStyleCubit),
      ],
      child: CustomerApp(
        authCubit: authCubit,
        hasCompletedOnboarding: hasCompletedOnboarding,
      ),
    ),
  );
}

class CustomerApp extends StatefulWidget {
  final AuthCubit authCubit;
  final bool hasCompletedOnboarding;
  const CustomerApp({
    super.key,
    required this.authCubit,
    required this.hasCompletedOnboarding,
  });

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createCustomerRouter(
      widget.authCubit,
      hasCompletedOnboarding: widget.hasCompletedOnboarding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SalonOnMap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Plus Jakarta Sans'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('en', 'IN'), Locale('en', 'US')],
      routerConfig: _router,
    );
  }
}

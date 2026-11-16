import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'core/network/customer_api_service.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/booking/cubit/booking_cubit.dart';
import 'features/ai_style_studio/cubit/ai_style_cubit.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final customerApiService = CustomerApiService.instance;
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
      child: CustomerApp(authCubit: authCubit),
    ),
  );
}

class CustomerApp extends StatefulWidget {
  final AuthCubit authCubit;
  const CustomerApp({super.key, required this.authCubit});

  @override
  State<CustomerApp> createState() => _CustomerAppState();
}

class _CustomerAppState extends State<CustomerApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createCustomerRouter(widget.authCubit);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SalonOnMap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Plus Jakarta Sans',
      ),
      routerConfig: _router,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';
import 'package:partner_app/features/auth/cubit/partner_auth_cubit.dart';
import 'package:partner_app/features/dashboard/cubit/partner_dashboard_cubit.dart';
import 'package:partner_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:partner_app/features/seats/cubit/partner_seats_cubit.dart';

void main() {
  testWidgets('DashboardScreen smoke test', (WidgetTester tester) async {
    final apiClient = ApiClient();
    final authCubit = PartnerAuthCubit(apiClient: apiClient);
    final seatsCubit = PartnerSeatsCubit(apiClient: apiClient);
    final dashboardCubit = PartnerDashboardCubit(apiClient: apiClient);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<PartnerAuthCubit>.value(value: authCubit),
            BlocProvider<PartnerSeatsCubit>.value(value: seatsCubit),
            BlocProvider<PartnerDashboardCubit>.value(value: dashboardCubit),
          ],
          child: const DashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}

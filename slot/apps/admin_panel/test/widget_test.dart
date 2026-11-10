import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';
import 'package:admin_panel/features/dashboard/cubit/admin_dashboard_cubit.dart';
import 'package:admin_panel/features/dashboard/presentation/admin_dashboard_screen.dart';

void main() {
  testWidgets('AdminDashboardScreen smoke test', (WidgetTester tester) async {
    final apiClient = ApiClient();
    final cubit = AdminDashboardCubit(apiClient: apiClient);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AdminDashboardCubit>.value(
          value: cubit,
          child: const AdminDashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
  });
}

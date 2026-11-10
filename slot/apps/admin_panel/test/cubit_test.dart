import 'package:flutter_test/flutter_test.dart';
import 'package:api_client/api_client.dart';
import 'package:admin_panel/features/dashboard/cubit/admin_dashboard_cubit.dart';

void main() {
  group('AdminDashboardCubit Unit Tests', () {
    late ApiClient apiClient;
    late AdminDashboardCubit cubit;

    setUp(() {
      apiClient = ApiClient();
      cubit = AdminDashboardCubit(apiClient: apiClient);
    });

    test('Initial state is AdminDashboardInitialState', () {
      expect(cubit.state, isA<AdminDashboardInitialState>());
    });
  });
}

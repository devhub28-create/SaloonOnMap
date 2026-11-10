import 'package:flutter_test/flutter_test.dart';
import 'package:api_client/api_client.dart';
import 'package:partner_app/features/dashboard/cubit/partner_dashboard_cubit.dart';

void main() {
  group('PartnerDashboardCubit Unit Tests', () {
    late ApiClient apiClient;
    late PartnerDashboardCubit cubit;

    setUp(() {
      apiClient = ApiClient();
      cubit = PartnerDashboardCubit(apiClient: apiClient);
    });

    test('Initial state is PartnerDashboardInitialState', () {
      expect(cubit.state, isA<PartnerDashboardInitialState>());
    });
  });
}

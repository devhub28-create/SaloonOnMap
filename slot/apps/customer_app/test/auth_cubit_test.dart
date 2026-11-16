import 'package:flutter_test/flutter_test.dart';
import 'package:api_client/api_client.dart';
import 'package:customer_app/features/auth/cubit/auth_cubit.dart';

void main() {
  group('AuthCubit Unit Tests', () {
    late ApiClient apiClient;
    late AuthCubit authCubit;

    setUp(() {
      apiClient = ApiClient();
      authCubit = AuthCubit(apiClient: apiClient);
    });

    test('Initial state is AuthInitialState', () {
      expect(authCubit.state, isA<AuthInitialState>());
      expect(authCubit.isAuthenticated, false);
    });

    test('requestOtp emits AuthValidationErrorState for invalid phone',
        () async {
      await authCubit.requestOtp('123');
      expect(authCubit.state, isA<AuthValidationErrorState>());
    });

    test('verifyOtp emits AuthInvalidOtpState for short code', () async {
      authCubit.setPhone('9876543210');
      await authCubit.verifyOtp('12');
      expect(authCubit.state, isA<AuthInvalidOtpState>());
    });
  });
}

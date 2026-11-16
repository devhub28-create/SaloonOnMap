import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';
import 'package:customer_app/features/auth/cubit/auth_cubit.dart';
import 'package:customer_app/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('LoginScreen smoke test', (WidgetTester tester) async {
    final apiClient = ApiClient();
    final authCubit = AuthCubit(apiClient: apiClient);
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const LoginScreen(),
        ),
      ),
    );
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Your next great look\nstarts here.'), findsOneWidget);
  });
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/admin_error_message.dart';

abstract class AdminAuthState {}

class AdminAuthInitial extends AdminAuthState {}

class AdminAuthLoading extends AdminAuthState {}

class AdminAuthenticated extends AdminAuthState {
  final String token;
  final String userId;
  final String email;
  final String role;

  AdminAuthenticated({
    required this.token,
    required this.userId,
    required this.email,
    required this.role,
  });
}

class AdminUnauthenticated extends AdminAuthState {}

class AdminAuthError extends AdminAuthState {
  final String message;
  AdminAuthError(this.message);
}

class AdminAuthCubit extends Cubit<AdminAuthState> {
  final ApiClient apiClient;

  AdminAuthCubit({required this.apiClient}) : super(AdminAuthInitial());

  static const String _keyToken = 'admin_jwt_token';
  static const String _keyEmail = 'admin_email';
  static const String _keyRole = 'admin_role';
  static const String _keyUserId = 'admin_user_id';

  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final email = prefs.getString(_keyEmail);
      final role = prefs.getString(_keyRole);
      final userId = prefs.getString(_keyUserId);

      if (token != null && token.isNotEmpty) {
        apiClient.setAuthToken(token);
        emit(AdminAuthenticated(
          token: token,
          userId: userId ?? '',
          email: email ?? '',
          role: role ?? 'ADMIN',
        ));
      } else {
        emit(AdminUnauthenticated());
      }
    } catch (e) {
      emit(AdminUnauthenticated());
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(AdminAuthLoading());
    if (email.trim().isEmpty) {
      emit(AdminAuthError('Please enter your admin email address.'));
      return;
    }

    if (password.trim().isEmpty) {
      emit(AdminAuthError('Please enter your password.'));
      return;
    }

    try {
      final response = await apiClient.loginAdmin(email.trim(), password);
      final token = response['accessToken']?.toString();
      final user =
          Map<String, dynamic>.from(response['user'] as Map? ?? const {});
      if (token == null || token.isEmpty) {
        throw StateError('Authentication server did not return a token.');
      }
      final prefs = await SharedPreferences.getInstance();
      final cleanEmail = email.trim();
      final role = user['role']?.toString() ?? 'ADMIN';
      final userId = user['id']?.toString() ?? '';

      final refreshToken = response['refreshToken']?.toString();
      if (refreshToken == null || refreshToken.isEmpty) {
        emit(AdminAuthError(
            'Authentication server did not return a secure session.'));
        return;
      }
      await apiClient.saveSession(token, refreshToken);
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyEmail, cleanEmail);
      await prefs.setString(_keyRole, role);
      await prefs.setString(_keyUserId, userId);

      emit(AdminAuthenticated(
        token: token,
        userId: userId,
        email: cleanEmail,
        role: role,
      ));
    } catch (e) {
      emit(AdminAuthError(adminErrorMessage(
        e,
        fallback: 'Admin login failed. Check your credentials and connection.',
      )));
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyRole);
      await prefs.remove(_keyUserId);
      emit(AdminUnauthenticated());
    } catch (e) {
      emit(AdminUnauthenticated());
    }
  }

  Future<void> handleSessionExpired() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyUserId);
    await apiClient.clearSession();
    emit(AdminUnauthenticated());
  }
}

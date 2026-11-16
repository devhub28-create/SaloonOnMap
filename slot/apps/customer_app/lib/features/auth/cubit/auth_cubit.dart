import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthState {}

class AuthInitialState extends AuthState {}

class AuthRequestingOtpState extends AuthState {}

class AuthOtpRequestedState extends AuthState {
  final String phone;
  AuthOtpRequestedState(this.phone);
}

class AuthVerifyingOtpState extends AuthState {}

class AuthAuthenticatedState extends AuthState {
  final Map<String, dynamic> user;
  final String accessToken;
  AuthAuthenticatedState({required this.user, required this.accessToken});
}

class AuthUnauthenticatedState extends AuthState {}

class AuthValidationErrorState extends AuthState {
  final String message;
  AuthValidationErrorState(this.message);
}

class AuthNetworkErrorState extends AuthState {
  final String message;
  AuthNetworkErrorState(this.message);
}

class AuthRateLimitedState extends AuthState {
  final String message;
  AuthRateLimitedState(this.message);
}

class AuthExpiredOtpState extends AuthState {
  final String message;
  AuthExpiredOtpState(this.message);
}

class AuthInvalidOtpState extends AuthState {
  final String message;
  AuthInvalidOtpState(this.message);
}

class AuthCubit extends Cubit<AuthState> {
  final ApiClient apiClient;
  String? _currentPhone;
  String? _token;
  Map<String, dynamic>? _user;

  AuthCubit({required this.apiClient}) : super(AuthInitialState());

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<void> checkSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUserJson = prefs.getString('auth_user');

      if (savedToken != null &&
          savedToken.isNotEmpty &&
          savedUserJson != null) {
        _token = savedToken;
        _user = jsonDecode(savedUserJson) as Map<String, dynamic>;
        apiClient.setAuthToken(_token!);
        emit(AuthAuthenticatedState(user: _user!, accessToken: _token!));
        return;
      }
    } catch (_) {}

    emit(AuthUnauthenticatedState());
  }

  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('auth_user', jsonEncode(user));
    } catch (_) {}
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
    } catch (_) {}
  }

  void setPhone(String phone) {
    String clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (!clean.startsWith('+')) {
      clean = '+91$clean';
    }
    _currentPhone = clean;
  }

  Future<void> requestOtp(String phone) async {
    String clean = phone.replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.length < 10) {
      emit(AuthValidationErrorState(
          'Please enter a valid 10-digit phone number.'));
      return;
    }
    if (!clean.startsWith('+')) {
      clean = '+91$clean';
    }

    _currentPhone = clean;
    emit(AuthRequestingOtpState());

    try {
      await apiClient.requestOtp(_currentPhone!);
      emit(AuthOtpRequestedState(_currentPhone!));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 429) {
        emit(AuthRateLimitedState(
            'Too many OTP requests. Please wait a minute and try again.'));
      } else {
        emit(AuthNetworkErrorState(_apiErrorMessage(
          e,
          fallback: 'Could not send the OTP. Please try again.',
        )));
      }
    }
  }

  Future<void> verifyOtp(
    String code, {
    String? name,
    String? email,
    String role = 'CUSTOMER',
  }) async {
    if (_currentPhone == null) {
      emit(AuthValidationErrorState(
          'Phone number is missing. Please enter phone number.'));
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code.trim())) {
      emit(AuthInvalidOtpState('Enter the complete 6-digit OTP.'));
      return;
    }

    emit(AuthVerifyingOtpState());

    try {
      final response = await apiClient.verifyOtp(
        _currentPhone!,
        code.trim(),
        name: name,
        email: email,
      );
      _token = response['accessToken']?.toString();
      _user = response['user'] is Map
          ? Map<String, dynamic>.from(response['user'] as Map)
          : null;

      if (_token != null && _user != null) {
        final refreshToken = response['refreshToken']?.toString();
        if (refreshToken == null || refreshToken.isEmpty) {
          emit(AuthNetworkErrorState(
              'Authentication server did not return a secure session.'));
          return;
        }
        await apiClient.saveSession(_token!, refreshToken);
        await _saveSession(_token!, _user!);
        emit(AuthAuthenticatedState(user: _user!, accessToken: _token!));
      } else {
        emit(AuthInvalidOtpState(
            'Invalid response from authentication server.'));
      }
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('expired')) {
        emit(AuthExpiredOtpState('The OTP has expired. Request a new code.'));
      } else if (message.contains('invalid') ||
          message.contains('unauthorized')) {
        emit(AuthInvalidOtpState('The OTP is invalid. Please try again.'));
      } else {
        emit(AuthNetworkErrorState(_apiErrorMessage(
          e,
          fallback: 'Could not verify the OTP. Please try again.',
        )));
      }
    }
  }

  String _apiErrorMessage(Object error, {required String fallback}) {
    if (error is! DioException) return fallback;
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) return message.join(' ');
      if (message.toString().trim().isNotEmpty) return message.toString();
    }
    return fallback;
  }

  Future<void> logout() async {
    try {
      await apiClient.logout();
    } catch (_) {
      await apiClient.clearSession();
    }
    await _clearSession();
    _token = null;
    _user = null;
    _currentPhone = null;
    emit(AuthUnauthenticatedState());
  }

  Future<void> handleSessionExpired() async {
    await _clearSession();
    await apiClient.clearSession();
    _token = null;
    _user = null;
    emit(AuthUnauthenticatedState());
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_token == null) {
      emit(AuthUnauthenticatedState());
      return;
    }
    try {
      final profile = await apiClient.updateCustomerProfile(updates);
      _user = {...?_user, ...profile};
      await _saveSession(_token!, _user!);
      emit(AuthAuthenticatedState(user: _user!, accessToken: _token!));
    } catch (error) {
      emit(AuthNetworkErrorState('Could not update profile: $error'));
    }
  }
}

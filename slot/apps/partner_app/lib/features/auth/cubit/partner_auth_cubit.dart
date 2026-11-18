import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/partner_api_urls.dart';

abstract class PartnerAuthState {}

class PartnerAuthInitial extends PartnerAuthState {}

class PartnerAuthLoading extends PartnerAuthState {}

class PartnerAuthenticated extends PartnerAuthState {
  final String token;
  final String salonId;
  final String salonName;
  final String ownerName;
  final int seatCount;
  final String city;
  final String area;
  final String address;
  final String coverImage;

  PartnerAuthenticated({
    required this.token,
    required this.salonId,
    required this.salonName,
    required this.ownerName,
    this.seatCount = 4,
    this.city = 'Bengaluru',
    this.area = '',
    this.address = '',
    this.coverImage = '',
  });
}

class PartnerUnauthenticated extends PartnerAuthState {}

class PartnerPendingApproval extends PartnerAuthState {
  final String salonName;
  final String ownerName;

  PartnerPendingApproval({required this.salonName, required this.ownerName});
}

class PartnerAuthError extends PartnerAuthState {
  final String message;
  PartnerAuthError(this.message);
}

class PartnerAuthCubit extends Cubit<PartnerAuthState> {
  final ApiClient apiClient;
  late final PushNotificationService _pushNotifications =
      PushNotificationService(apiClient: apiClient, appType: 'PARTNER');

  PartnerAuthCubit({required this.apiClient}) : super(PartnerAuthInitial());

  static const String _legacyKeyToken = 'partner_jwt_token';
  static const String _keySalonId = 'partner_salon_id';
  static const String _keySalonName = 'partner_salon_name';
  static const String _keyOwnerName = 'partner_owner_name';
  static const String _keySeatCount = 'partner_seat_count';
  static const String _keyCity = 'partner_city';
  static const String _keyArea = 'partner_area';
  static const String _keyAddress = 'partner_address';
  static const String _keyCoverImage = 'partner_cover_image';

  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final restored = await apiClient.restoreSession();
      final token = apiClient.accessToken;
      final salonId = prefs.getString(_keySalonId);
      final salonName = prefs.getString(_keySalonName);
      final ownerName = prefs.getString(_keyOwnerName);
      final seatCount = prefs.getInt(_keySeatCount) ?? 4;
      final city = prefs.getString(_keyCity) ?? 'Bengaluru';
      final area = prefs.getString(_keyArea) ?? '';
      final address = prefs.getString(_keyAddress) ?? '';
      final coverImage = prefs.getString(_keyCoverImage) ?? '';

      if (restored && token != null && token.isNotEmpty) {
        await prefs.remove(_legacyKeyToken);
        try {
          await apiClient.getPartnerSalon();
        } on DioException catch (error) {
          if (error.response?.statusCode == 403) {
            emit(
              PartnerPendingApproval(
                salonName: salonName ?? 'My Salon',
                ownerName: ownerName ?? 'Partner',
              ),
            );
            return;
          }
          if (error.response?.statusCode == 401) {
            await _clearStoredSession();
            emit(PartnerUnauthenticated());
            return;
          }
          emit(
            PartnerAuthError(
              'Could not verify your salon status. Check your connection and try again.',
            ),
          );
          return;
        }
        emit(
          PartnerAuthenticated(
            token: token,
            salonId: salonId ?? '',
            salonName: (salonName != null && salonName.isNotEmpty)
                ? salonName
                : 'My Salon',
            ownerName: (ownerName != null && ownerName.isNotEmpty)
                ? ownerName
                : 'Partner',
            seatCount: seatCount,
            city: city,
            area: area,
            address: address,
            coverImage: coverImage,
          ),
        );
        _pushNotifications.register();
      } else {
        emit(PartnerUnauthenticated());
      }
    } catch (e) {
      emit(PartnerUnauthenticated());
    }
  }

  Future<void> login({
    required String phoneOrEmail,
    required String password,
    String? selectedSalonId,
  }) async {
    emit(PartnerAuthLoading());
    await Future.delayed(const Duration(milliseconds: 600));

    if (phoneOrEmail.trim().isEmpty) {
      emit(PartnerAuthError('Please enter your phone number or email.'));
      return;
    }

    if (password.trim().isEmpty) {
      emit(PartnerAuthError('Please enter your password.'));
      return;
    }

    try {
      final response = await apiClient.dio.post(
        PartnerApiUrls.partnerLoginEndpoint,
        data: {'phoneOrEmail': phoneOrEmail.trim(), 'password': password},
      );

      final token = response.data['accessToken'] as String?;
      if (token == null || token.isEmpty) {
        emit(
          PartnerAuthError(
            'Login succeeded but the server did not return an access token.',
          ),
        );
        return;
      }
      final salonData = response.data['salon'];
      final userData = response.data['user'];

      final salonId = (salonData != null && salonData['id'] != null)
          ? salonData['id'].toString()
          : '';
      final salonName = (salonData != null &&
              salonData['name'] != null &&
              salonData['name'].toString().isNotEmpty)
          ? salonData['name'].toString()
          : 'My Salon';
      final ownerName = (userData != null &&
              userData['name'] != null &&
              userData['name'].toString().isNotEmpty)
          ? userData['name'].toString()
          : 'Partner';
      final seatCount = (salonData != null && salonData['seatCount'] != null)
          ? (salonData['seatCount'] as num).toInt()
          : 4;
      final city = (salonData != null && salonData['city'] != null)
          ? salonData['city'].toString()
          : '';
      final area = (salonData != null && salonData['area'] != null)
          ? salonData['area'].toString()
          : '';
      final address = (salonData != null && salonData['address'] != null)
          ? salonData['address'].toString()
          : '';
      final coverImage = (salonData != null && salonData['cover_image'] != null)
          ? salonData['cover_image'].toString()
          : (salonData != null && salonData['coverImage'] != null)
              ? salonData['coverImage'].toString()
              : '';

      final isPending = salonData is Map && salonData['isActive'] == false;

      final refreshToken = response.data['refreshToken']?.toString();
      if (refreshToken == null || refreshToken.isEmpty) {
        emit(PartnerAuthError('Login succeeded without a secure session.'));
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKeyToken);
      await prefs.setString(_keySalonId, salonId);
      await prefs.setString(_keySalonName, salonName);
      await prefs.setString(_keyOwnerName, ownerName);
      await prefs.setInt(_keySeatCount, seatCount);
      await prefs.setString(_keyCity, city);
      await prefs.setString(_keyArea, area);
      await prefs.setString(_keyAddress, address);
      await prefs.setString(_keyCoverImage, coverImage);
      await apiClient.saveSession(token, refreshToken);

      if (isPending) {
        emit(
          PartnerPendingApproval(salonName: salonName, ownerName: ownerName),
        );
        return;
      }

      emit(
        PartnerAuthenticated(
          token: token,
          salonId: salonId,
          salonName: salonName,
          ownerName: ownerName,
          seatCount: seatCount,
          city: city,
          area: area,
          address: address,
          coverImage: coverImage,
        ),
      );
      _pushNotifications.register();
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final msg = e.response?.data['message'];
        final errText = msg is List ? msg.join(', ') : msg?.toString();
        if (errText != null && errText.isNotEmpty) {
          emit(PartnerAuthError(errText));
          return;
        }
      }
      emit(
        PartnerAuthError(
          'Unable to connect to server. Please check your connection.',
        ),
      );
    } catch (e) {
      emit(PartnerAuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> registerSalon({
    required String ownerName,
    required String phone,
    required String email,
    required String password,
    required String salonName,
    required String targetGender,
    required String city,
    required String area,
    required String address,
    required int seatCount,
    String? coverImage,
    List<String>? images,
  }) async {
    emit(PartnerAuthLoading());

    String? token;
    String? refreshToken;
    String salonId = '';
    String savedCover = coverImage ?? '';
    bool isPending = false;

    try {
      final response = await apiClient.dio.post(
        PartnerApiUrls.partnerRegisterEndpoint,
        data: {
          'ownerName': ownerName,
          'phone': phone.trim(),
          'email': email.trim(),
          'password': password,
          'salonName': salonName,
          'targetGender': targetGender,
          'city': city,
          'area': area,
          'address': address,
          'seatCount': seatCount,
          if (coverImage != null && coverImage.isNotEmpty)
            'coverImage': coverImage,
          if (images != null && images.isNotEmpty) 'images': images,
        },
      );

      if (response.data != null) {
        if (response.data['accessToken'] != null) {
          token = response.data['accessToken'];
        }
        if (response.data['refreshToken'] != null) {
          refreshToken = response.data['refreshToken'].toString();
        }
        if (response.data['salon'] != null &&
            response.data['salon']['id'] != null) {
          salonId = response.data['salon']['id'];
        }
      }

      final salonData = response.data['salon'];
      if (salonData is Map) {
        if (salonData['cover_image'] != null &&
            salonData['cover_image'].toString().isNotEmpty) {
          savedCover = salonData['cover_image'].toString();
        }
        isPending = salonData['isActive'] == false;
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final msg = e.response?.data['message'];
        final errText = msg is List ? msg.join(', ') : msg?.toString();
        if (errText != null && errText.isNotEmpty) {
          emit(PartnerAuthError(errText));
          return;
        }
      }
      emit(
        PartnerAuthError(
          'Unable to connect to server: ${e.message ?? e.toString()}',
        ),
      );
      return;
    } catch (e) {
      emit(PartnerAuthError('Registration error: ${e.toString()}'));
      return;
    }

    if (token == null ||
        token.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      emit(
        PartnerAuthError(
          'Registration succeeded but the server did not return an access token.',
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKeyToken);
      await prefs.setString(_keySalonId, salonId);
      await prefs.setString(_keySalonName, salonName);
      await prefs.setString(_keyOwnerName, ownerName);
      await prefs.setInt(_keySeatCount, seatCount);
      await prefs.setString(_keyCity, city);
      await prefs.setString(_keyArea, area);
      await prefs.setString(_keyAddress, address);
      await prefs.setString(_keyCoverImage, savedCover);
      await apiClient.saveSession(token, refreshToken);

      if (isPending) {
        emit(
          PartnerPendingApproval(salonName: salonName, ownerName: ownerName),
        );
        return;
      }

      emit(
        PartnerAuthenticated(
          token: token,
          salonId: salonId,
          salonName: salonName,
          ownerName: ownerName,
          seatCount: seatCount,
          city: city,
          area: area,
          address: address,
          coverImage: savedCover,
        ),
      );
      _pushNotifications.register();
    } catch (e) {
      emit(PartnerAuthError('Save profile error: ${e.toString()}'));
    }
  }

  Future<bool> refreshApprovalStatus() async {
    final current = state;
    if (current is! PartnerPendingApproval) {
      return current is PartnerAuthenticated;
    }
    try {
      final salon = await apiClient.getPartnerSalon();
      if (salon['isActive'] == false || salon['is_active'] == false) {
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      final token = apiClient.accessToken;
      if (token == null || token.isEmpty) {
        await handleSessionExpired();
        return false;
      }
      emit(
        PartnerAuthenticated(
          token: token,
          salonId:
              salon['id']?.toString() ?? prefs.getString(_keySalonId) ?? '',
          salonName: salon['name']?.toString() ?? current.salonName,
          ownerName: prefs.getString(_keyOwnerName) ?? current.ownerName,
          seatCount: (salon['seatCount'] as num?)?.toInt() ??
              (salon['seat_count'] as num?)?.toInt() ??
              prefs.getInt(_keySeatCount) ??
              4,
          city: salon['city']?.toString() ?? prefs.getString(_keyCity) ?? '',
          area: salon['area']?.toString() ?? prefs.getString(_keyArea) ?? '',
          address: salon['address']?.toString() ??
              prefs.getString(_keyAddress) ??
              '',
          coverImage: salon['coverImage']?.toString() ??
              salon['cover_image']?.toString() ??
              prefs.getString(_keyCoverImage) ??
              '',
        ),
      );
      _pushNotifications.register();
      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 403) return false;
      if (error.response?.statusCode == 401) await handleSessionExpired();
      rethrow;
    }
  }

  Future<void> updateSeatCount(int newCount) async {
    if (newCount < 1) return;
    final currentState = state;
    if (currentState is PartnerAuthenticated) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_keySeatCount, newCount);
        if (currentState.salonId.isNotEmpty) {
          await apiClient.setPartnerSeatCount(currentState.salonId, newCount);
        }

        emit(
          PartnerAuthenticated(
            token: currentState.token,
            salonId: currentState.salonId,
            salonName: currentState.salonName,
            ownerName: currentState.ownerName,
            seatCount: newCount,
            city: currentState.city,
            area: currentState.area,
            address: currentState.address,
            coverImage: currentState.coverImage,
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> updateCoverImage(String newCoverImage) async {
    final currentState = state;
    if (currentState is PartnerAuthenticated) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyCoverImage, newCoverImage);
        try {
          await apiClient.dio.patch(
            PartnerApiUrls.salonProfileEndpoint,
            data: {'coverImage': newCoverImage},
          );
        } catch (_) {}

        emit(
          PartnerAuthenticated(
            token: currentState.token,
            salonId: currentState.salonId,
            salonName: currentState.salonName,
            ownerName: currentState.ownerName,
            seatCount: currentState.seatCount,
            city: currentState.city,
            area: currentState.area,
            address: currentState.address,
            coverImage: newCoverImage,
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> logout() async {
    await _pushNotifications.unregister();
    try {
      await apiClient.logout();
      await _clearStoredSession();
      emit(PartnerUnauthenticated());
    } catch (e) {
      await _clearStoredSession();
      emit(PartnerUnauthenticated());
    }
  }

  Future<void> handleSessionExpired() async {
    await _pushNotifications.unregister();
    await _clearStoredSession();
    emit(PartnerUnauthenticated());
  }

  Future<void> _clearStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_legacyKeyToken);
      await prefs.remove(_keySalonId);
      await prefs.remove(_keySalonName);
      await prefs.remove(_keyOwnerName);
      await prefs.remove(_keySeatCount);
      await prefs.remove(_keyCity);
      await prefs.remove(_keyArea);
      await prefs.remove(_keyAddress);
      await prefs.remove(_keyCoverImage);
      await apiClient.clearSession();
    } catch (_) {}
  }
}

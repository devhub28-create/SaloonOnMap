import 'package:dio/dio.dart';
export 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum Environment { development, staging, production }

class ApiConfig {
  static const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'production',
  );
  static const String configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String configuredWsUrl = String.fromEnvironment('WS_URL');

  // Vercel Production Base URL (Pointed to live cloud deployment)
  static const String vercelBaseUrl = 'https://salononmap.vercel.app/api/v1';
  static const String vercelWsUrl = 'wss://salononmap.vercel.app';
  static const String vercelDeploymentUrl =
      'https://salononmap-dzohxt0y6-devhub28-6640.vercel.app/api/v1';

  static const String fallbackLanUrl = 'http://192.168.2.51:3000/api/v1';
  static const String fallbackLanWsUrl = 'ws://192.168.2.51:3000';
  static const String emulatorBaseUrl = 'http://10.0.2.2:3000/api/v1';

  static String? _activeBaseUrl;

  static String get baseUrl {
    if (_activeBaseUrl != null && _activeBaseUrl!.isNotEmpty)
      return _activeBaseUrl!;
    if (configuredBaseUrl.isNotEmpty) return configuredBaseUrl;
    // Primary Vercel Cloud API Endpoint (No localhost)
    return vercelBaseUrl;
  }

  static void setActiveBaseUrl(String url) {
    _activeBaseUrl = url;
  }

  static String get wsUrl {
    if (configuredWsUrl.isNotEmpty) return configuredWsUrl;
    if (_activeBaseUrl != null && _activeBaseUrl!.isNotEmpty) {
      return _activeBaseUrl!
          .replaceAll('http', 'ws')
          .replaceAll(RegExp(r'/api/v1/?$'), '');
    }
    return vercelWsUrl;
  }

  static String formatImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&q=80&w=1000';
    }
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
    if (trimmed.startsWith('/')) {
      return '$base$trimmed';
    }
    return '$base/$trimmed';
  }
}

/// Centralized API Endpoints & URLs repository across all Slot apps.
/// Formats endpoints and full URLs as: fullUrl = baseUrl + endpoint.
class ApiEndpoints {
  const ApiEndpoints();

  static String get baseUrl => ApiConfig.baseUrl;

  // Auth & Profile
  static const String requestOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String customerProfile = '/auth/customer/profile';
  static const String loginPartner = '/auth/login-partner';
  static const String registerPartner = '/auth/register-partner';
  static const String loginAdmin = '/auth/login-admin';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';

  // Full URLs: baseUrl + endpoint
  static String get requestOtpUrl => '$baseUrl$requestOtp';
  static String get verifyOtpUrl => '$baseUrl$verifyOtp';
  static String get customerProfileUrl => '$baseUrl$customerProfile';
  static String get loginPartnerUrl => '$baseUrl$loginPartner';
  static String get registerPartnerUrl => '$baseUrl$registerPartner';
  static String get loginAdminUrl => '$baseUrl$loginAdmin';
  static String get logoutUrl => '$baseUrl$logout';
  static String get refreshUrl => '$baseUrl$refresh';

  // Customer Discovery & Bookings
  static const String customerHome = '/customer/home';
  static const String customerOffers = '/customer/offers';
  static const String customerBookings = '/customer/bookings';
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';

  static String get customerHomeUrl => '$baseUrl$customerHome';
  static String get customerOffersUrl => '$baseUrl$customerOffers';
  static String get customerBookingsUrl => '$baseUrl$customerBookings';
  static String get notificationsUrl => '$baseUrl$notifications';
  static String get notificationsReadAllUrl => '$baseUrl$notificationsReadAll';

  // Salons & Booking Actions
  static const String salons = '/salons';
  static const String bookings = '/bookings';
  static const String bookingHolds = '/bookings/holds';
  static const String reviews = '/reviews';
  static const String uploadSalonImage = '/salons/upload-image';

  static String get salonsUrl => '$baseUrl$salons';
  static String get bookingsUrl => '$baseUrl$bookings';
  static String get bookingHoldsUrl => '$baseUrl$bookingHolds';
  static String get reviewsUrl => '$baseUrl$reviews';
  static String get uploadSalonImageUrl => '$baseUrl$uploadSalonImage';

  static String salonDetailsUrl(String id) => '$baseUrl$salons/$id';
  static String availableSlotsUrl(String salonId) =>
      '$baseUrl$salons/$salonId/available-slots';
  static String cancelBookingUrl(String bookingId) =>
      '$baseUrl$bookings/$bookingId/cancel';
  static String bookingStatusUrl(String bookingId) =>
      '$baseUrl$bookings/$bookingId/status';
  static String salonReviewsUrl(String salonId) =>
      '$baseUrl$salons/$salonId/reviews';
  static String bookingReviewUrl(String bookingId) =>
      '$baseUrl$reviews/booking/$bookingId';

  // Partner Desk
  static const String partnerSalon = '/partner/salon';
  static const String partnerDashboard = '/partner/dashboard';
  static const String partnerBookings = '/partner/bookings';
  static const String partnerWalkIn = '/partner/walkin';
  static const String partnerSeats = '/partner/seats';
  static const String partnerServices = '/partner/services';
  static const String partnerCombos = '/partner/combos';
  static const String partnerStaff = '/partner/staff';
  static const String partnerReports = '/partner/reports';
  static const String partnerReviews = '/partner/reviews';

  static String get partnerSalonUrl => '$baseUrl$partnerSalon';
  static String get partnerDashboardUrl => '$baseUrl$partnerDashboard';
  static String get partnerBookingsUrl => '$baseUrl$partnerBookings';
  static String get partnerWalkInUrl => '$baseUrl$partnerWalkIn';
  static String get partnerSeatsUrl => '$baseUrl$partnerSeats';
  static String get partnerServicesUrl => '$baseUrl$partnerServices';
  static String get partnerCombosUrl => '$baseUrl$partnerCombos';
  static String get partnerStaffUrl => '$baseUrl$partnerStaff';
  static String get partnerReportsUrl => '$baseUrl$partnerReports';
  static String get partnerReviewsUrl => '$baseUrl$partnerReviews';
  static String partnerSeatStatusUrl(String seatId) =>
      '$baseUrl$partnerSeats/$seatId/status';
  static String partnerServiceByIdUrl(String id) =>
      '$baseUrl$partnerServices/$id';
  static String partnerStaffByIdUrl(String id) => '$baseUrl$partnerStaff/$id';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminPendingSalons = '/admin/salons/pending';
  static const String adminUsers = '/admin/users';
  static const String adminBookings = '/admin/bookings';
  static const String adminAuditLogs = '/admin/audit-logs';

  static String get adminDashboardUrl => '$baseUrl$adminDashboard';
  static String get adminPendingSalonsUrl => '$baseUrl$adminPendingSalons';
  static String get adminUsersUrl => '$baseUrl$adminUsers';
  static String get adminBookingsUrl => '$baseUrl$adminBookings';
  static String get adminAuditLogsUrl => '$baseUrl$adminAuditLogs';
  static String adminReviewSalonUrl(String salonId) =>
      '$baseUrl/admin/salons/$salonId/review';
  static String adminUserStatusUrl(String userId) =>
      '$baseUrl$adminUsers/$userId/status';

  // AI Style Studio
  static const String aiStyleOptions = '/style-studio/options';
  static const String aiStyleHealth = '/style-studio/health';
  static const String aiStyleAnalyze = '/style-studio/analyze';
  static const String aiStyleGenerations = '/style-studio/generations';
  static const String aiStyleSaveLook = '/style-studio/save-look';
  static const String aiStyleSavedLooks = '/style-studio/saved-looks';

  static String get aiStyleOptionsUrl => '$baseUrl$aiStyleOptions';
  static String get aiStyleHealthUrl => '$baseUrl$aiStyleHealth';
  static String get aiStyleAnalyzeUrl => '$baseUrl$aiStyleAnalyze';
  static String get aiStyleGenerationsUrl => '$baseUrl$aiStyleGenerations';
  static String get aiStyleSaveLookUrl => '$baseUrl$aiStyleSaveLook';
  static String get aiStyleSavedLooksUrl => '$baseUrl$aiStyleSavedLooks';
  static String aiStyleJobUrl(String jobId) =>
      '$baseUrl$aiStyleGenerations/$jobId';
  static String aiStyleLooksUrl(String jobId) =>
      '$baseUrl$aiStyleGenerations/$jobId/looks';

  // Reverse Geocoding
  static const String reverseGeocodeUrl =
      'https://nominatim.openstreetmap.org/reverse';
}

class ApiClient {
  late final Dio dio;
  final FlutterSecureStorage _storage;
  Future<void> Function()? onUnauthorized;
  Future<void>? _refreshInFlight;

  static const _accessTokenKey = 'slot_access_token';
  static const _refreshTokenKey = 'slot_refresh_token';

  ApiClient({String? baseUrl, FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final isConnError =
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout;
          final reqUri = error.requestOptions.uri;
          final isLocal =
              reqUri.host == '127.0.0.1' ||
              reqUri.host == 'localhost' ||
              reqUri.host == '10.0.2.2';

          if (isConnError &&
              isLocal &&
              !error.requestOptions.extra.containsKey('retried_lan_fallback')) {
            final candidateUrls = <String>[
              if (reqUri.host != '10.0.2.2' &&
                  !kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.android)
                ApiConfig.emulatorBaseUrl,
              if (reqUri.host != '127.0.0.1') 'http://127.0.0.1:3000/api/v1',
              ApiConfig.fallbackLanUrl,
            ];

            for (final candidateUrl in candidateUrls) {
              try {
                final fallbackOptions = error.requestOptions.copyWith();
                fallbackOptions.extra['retried_lan_fallback'] = true;
                fallbackOptions.baseUrl = candidateUrl;
                final retryDio = Dio(
                  BaseOptions(
                    baseUrl: candidateUrl,
                    connectTimeout: const Duration(seconds: 5),
                    receiveTimeout:
                        error.requestOptions.receiveTimeout ??
                        const Duration(minutes: 3),
                    sendTimeout: error.requestOptions.sendTimeout,
                    headers: error.requestOptions.headers,
                  ),
                );
                final response = await retryDio.fetch<dynamic>(fallbackOptions);
                dio.options.baseUrl = candidateUrl;
                ApiConfig.setActiveBaseUrl(candidateUrl);
                return handler.resolve(response);
              } catch (_) {
                // Try next candidate
              }
            }
          }

          final isUnauthorized = error.response?.statusCode == 401;
          final path = error.requestOptions.path;
          if (!isUnauthorized ||
              path.contains('/auth/refresh') ||
              path.contains('/auth/login')) {
            handler.next(error);
            return;
          }
          try {
            _refreshInFlight ??= _refreshAccessToken();
            await _refreshInFlight;
            _refreshInFlight = null;
            final response = await dio.fetch<dynamic>(
              error.requestOptions
                ..headers['Authorization'] =
                    dio.options.headers['Authorization'],
            );
            handler.resolve(response);
          } catch (_) {
            _refreshInFlight = null;
            await clearSession();
            await onUnauthorized?.call();
            handler.next(error);
          }
        },
      ),
    );
  }

  Future<bool> restoreSession() async {
    if (kIsWeb) return false;
    try {
      final token = await _storage.read(key: _accessTokenKey);
      final refresh = await _storage.read(key: _refreshTokenKey);
      if (token == null || refresh == null) return false;
      setAuthToken(token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveSession(String accessToken, String refreshToken) async {
    if (!kIsWeb) {
      try {
        await _storage.write(key: _accessTokenKey, value: accessToken);
        await _storage.write(key: _refreshTokenKey, value: refreshToken);
      } catch (_) {}
    }
    setAuthToken(accessToken);
  }

  Future<void> _refreshAccessToken() async {
    if (kIsWeb) throw StateError('No refresh token on web');
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) throw StateError('No refresh token');
    final refreshDio = Dio(dio.options);
    final response = await refreshDio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final access = response.data['accessToken']?.toString();
    final rotatedRefresh = response.data['refreshToken']?.toString();
    if (access == null || rotatedRefresh == null)
      throw StateError('Invalid refresh response');
    await saveSession(access, rotatedRefresh);
  }

  Future<void> logout() async {
    try {
      await dio.post('/auth/logout');
    } catch (_) {
    } finally {
      await clearSession();
    }
  }

  Future<void> clearSession() async {
    clearAuthToken();
    if (!kIsWeb) {
      try {
        await _storage.delete(key: _accessTokenKey);
        await _storage.delete(key: _refreshTokenKey);
      } catch (_) {}
    }
  }

  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }

  // Auth APIs
  Future<Map<String, dynamic>> requestOtp(String phone) async {
    final response = await dio.post(
      '/auth/request-otp',
      data: {'phone': phone},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> verifyOtp(
    String phone,
    String code, {
    String? name,
    String? email,
  }) async {
    final payload = <String, dynamic>{'phone': phone, 'code': code};
    if (name != null && name.trim().isNotEmpty) {
      payload['name'] = name.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      payload['email'] = email.trim();
    }
    final response = await dio.post('/auth/verify-otp', data: payload);
    return response.data;
  }

  Future<Map<String, dynamic>> loginAdmin(String email, String password) async {
    final response = await dio.post(
      '/auth/login-admin',
      data: {'email': email, 'password': password},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getCustomerProfile() async {
    final response = await dio.get('/auth/customer/profile');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateCustomerProfile(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.patch('/auth/customer/profile', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Customer Home & Salons API
  Future<Map<String, dynamic>> getCustomerHome({
    String gender = 'MEN',
    double? lat,
    double? lng,
    String? area,
  }) async {
    final response = await dio.get(
      '/customer/home',
      queryParameters: {
        'gender': gender,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (area != null) 'area': area,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getCustomerOffers() async {
    final response = await dio.get('/customer/offers');
    return response.data;
  }

  Future<List<dynamic>> getNotifications() async {
    final response = await dio.get('/notifications');
    return response.data;
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await dio.get('/notifications/unread-count');
    final data = Map<String, dynamic>.from(response.data as Map);
    return (data['count'] as num? ?? 0).toInt();
  }

  Future<void> markAllNotificationsRead() async {
    await dio.patch('/notifications/read-all');
  }

  Future<List<dynamic>> getSalons({
    String? search,
    String? gender,
    double? lat,
    double? lng,
    String? area,
  }) async {
    final response = await dio.get(
      '/salons',
      queryParameters: {
        if (search != null) 'search': search,
        if (gender != null) 'gender': gender,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (area != null) 'area': area,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getSalonDetails(String id) async {
    final response = await dio.get('/salons/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> getAvailableSlots(
    String salonId, {
    String? date,
    int? duration,
  }) async {
    final response = await dio.get(
      '/salons/$salonId/available-slots',
      queryParameters: {
        if (date != null) 'date': date,
        if (duration != null) 'duration': duration,
      },
    );
    return response.data;
  }

  // Booking Holds & Confirmations
  Future<Map<String, dynamic>> createHold(Map<String, dynamic> data) async {
    final response = await dio.post('/bookings/holds', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> confirmBooking(
    Map<String, dynamic> data, {
    String? idempotencyKey,
  }) async {
    final options = idempotencyKey != null
        ? Options(headers: {'Idempotency-Key': idempotencyKey})
        : null;
    final response = await dio.post('/bookings', data: data, options: options);
    return response.data;
  }

  Future<Map<String, dynamic>> cancelBooking(
    String bookingId, {
    String? reason,
  }) async {
    final response = await dio.patch(
      '/bookings/$bookingId/cancel',
      data: {'reason': reason ?? 'Customer requested cancellation'},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required String status,
    String? reason,
  }) async {
    final response = await dio.patch(
      '/bookings/$bookingId/status',
      data: {'status': status, if (reason != null) 'reason': reason},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // Reviews APIs
  Future<Map<String, dynamic>> createReview({
    required String bookingId,
    required int rating,
    String? comment,
    List<String>? tags,
  }) async {
    final response = await dio.post(
      '/reviews',
      data: {
        'bookingId': bookingId,
        'rating': rating,
        if (comment != null) 'comment': comment,
        if (tags != null) 'tags': tags,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getSalonReviews(
    String salonId, {
    int? limit,
    int? offset,
  }) async {
    final response = await dio.get(
      '/salons/$salonId/reviews',
      queryParameters: {
        if (limit != null) 'limit': limit,
        if (offset != null) 'offset': offset,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>?> getBookingReview(String bookingId) async {
    final response = await dio.get('/reviews/booking/$bookingId');
    if (response.data == null || response.data == '') return null;
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getPartnerReviews({String? salonId}) async {
    final response = await dio.get(
      '/partner/reviews',
      queryParameters: salonId != null ? {'salonId': salonId} : null,
    );
    return response.data;
  }

  Future<String> uploadSalonImage(dynamic fileOrPath) async {
    try {
      FormData formData;
      if (fileOrPath is String) {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(fileOrPath),
        });
      } else {
        formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(fileOrPath.path),
        });
      }
      final response = await dio.post('/salons/upload-image', data: formData);
      if (response.data != null && response.data['url'] != null) {
        return response.data['url'].toString();
      }
      return '';
    } catch (e) {
      debugPrint('Failed to upload salon image: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getCustomerBookings({
    String? customerId,
    String? status,
  }) async {
    final response = await dio.get(
      '/customer/bookings',
      queryParameters: {
        if (customerId != null) 'customerId': customerId,
        if (status != null) 'status': status,
      },
    );
    return response.data;
  }

  // Partner APIs
  Future<Map<String, dynamic>> getPartnerDashboard({String? salonId}) async {
    final response = await dio.get(
      '/partner/dashboard',
      queryParameters: salonId != null ? {'salonId': salonId} : null,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getPartnerSalon() async {
    final response = await dio.get('/partner/salon');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updatePartnerSalon(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.patch('/partner/salon', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getPartnerBookings({
    String? salonId,
    String? status,
  }) async {
    final response = await dio.get(
      '/partner/bookings',
      queryParameters: {
        if (salonId != null) 'salonId': salonId,
        if (status != null) 'status': status,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getPartnerSeats({String? salonId}) async {
    final response = await dio.get(
      '/partner/seats',
      queryParameters: {if (salonId != null) 'salonId': salonId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updatePartnerSeatStatus(
    String seatId,
    String status,
  ) async {
    final response = await dio.patch(
      '/partner/seats/$seatId/status',
      data: {'status': status},
    );
    return response.data;
  }

  Future<List<dynamic>> setPartnerSeatCount(
    String salonId,
    int seatCount,
  ) async {
    final response = await dio.put(
      '/partner/seats',
      data: {'salonId': salonId, 'seatCount': seatCount},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> addWalkIn(Map<String, dynamic> data) async {
    final response = await dio.post('/partner/walkin', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getPartnerReports({
    String? period,
    String? salonId,
  }) async {
    final response = await dio.get(
      '/partner/reports',
      queryParameters: {
        if (period != null) 'period': period,
        if (salonId != null) 'salonId': salonId,
      },
    );
    return response.data;
  }

  Future<List<dynamic>> getPartnerServices({String? salonId}) async {
    final response = await dio.get(
      '/partner/services',
      queryParameters: {if (salonId != null) 'salonId': salonId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> addPartnerService(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/partner/services', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updatePartnerService(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.patch('/partner/services/$id', data: data);
    return response.data;
  }

  Future<List<dynamic>> getPartnerCombos({String? salonId}) async {
    final response = await dio.get(
      '/partner/combos',
      queryParameters: {if (salonId != null) 'salonId': salonId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> addPartnerCombo(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/partner/combos', data: data);
    return response.data;
  }

  Future<List<dynamic>> getPartnerStaff({String? salonId}) async {
    final response = await dio.get(
      '/partner/staff',
      queryParameters: {if (salonId != null) 'salonId': salonId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> addPartnerStaff(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/partner/staff', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updatePartnerStaff(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.patch('/partner/staff/$id', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> deletePartnerStaff(String id) async {
    final response = await dio.delete('/partner/staff/$id');
    return response.data;
  }

  // Admin APIs
  Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await dio.get('/admin/dashboard');
    return response.data;
  }

  Future<List<dynamic>> getPendingSalons() async {
    final response = await dio.get('/admin/salons/pending');
    return response.data;
  }

  Future<Map<String, dynamic>> getAdminSalons({
    String? search,
    String? status,
    int page = 1,
    int limit = 25,
  }) async {
    final response = await dio.get(
      '/admin/salons',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status != 'ALL') 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> reviewSalon(
    String salonId,
    String action, {
    String? reason,
  }) async {
    final response = await dio.post(
      '/admin/salons/$salonId/review',
      data: {'action': action, if (reason != null) 'reason': reason},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAdminUsers({
    String? search,
    String? role,
    String? status,
    int page = 1,
    int limit = 25,
  }) async {
    final response = await dio.get(
      '/admin/users',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (role != null && role != 'ALL') 'role': role,
        if (status != null && status != 'ALL') 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getAdminBookings({
    String? search,
    String? status,
    int page = 1,
    int limit = 25,
  }) async {
    final response = await dio.get(
      '/admin/bookings',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status != 'ALL') 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateAdminBookingStatus(
    String bookingId,
    String status,
    String reason,
  ) async {
    final response = await dio.patch(
      '/admin/bookings/$bookingId/status',
      data: {'status': status, 'reason': reason.trim()},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getAdminReviews({
    String? search,
    String? status,
    int page = 1,
    int limit = 25,
  }) async {
    final response = await dio.get(
      '/admin/reviews',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status != 'ALL') 'status': status,
        'page': page,
        'limit': limit,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> moderateAdminReview(
    String reviewId,
    String status, {
    String? reason,
  }) async {
    final response = await dio.patch(
      '/admin/reviews/$reviewId/moderation',
      data: {
        'status': status,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getAdminAuditLogs({
    String? search,
    String? action,
    String? entityType,
    int page = 1,
    int limit = 25,
  }) async {
    final response = await dio.get(
      '/admin/audit-logs',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (action != null && action != 'ALL') 'action': action,
        if (entityType != null && entityType != 'ALL') 'entityType': entityType,
        'page': page,
        'limit': limit,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getAdminNotificationCampaigns() async {
    final response = await dio.get('/admin/notification-campaigns');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> sendAdminNotificationCampaign(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post(
      '/admin/notification-campaigns',
      data: data,
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getAdminAiStyleOperations() async {
    final response = await dio.get('/admin/ai-style/operations');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getAdminAnalytics({int days = 30}) async {
    final response = await dio.get(
      '/admin/analytics',
      queryParameters: {'days': days},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getAdminSystemHealth() async {
    final response = await dio.get('/admin/system-health');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createSupportTicket(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/support/tickets', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getMySupportTickets() async {
    final response = await dio.get('/support/tickets/my');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> addSupportTicketMessage(
    String ticketId,
    String message,
  ) async {
    final response = await dio.post(
      '/support/tickets/$ticketId/messages',
      data: {'message': message},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getAdminSupportTickets({
    String? search,
    String? status,
    String? priority,
    int page = 1,
  }) async {
    final response = await dio.get(
      '/admin/support-tickets',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (status != null && status != 'ALL') 'status': status,
        if (priority != null && priority != 'ALL') 'priority': priority,
        'page': page,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> replyToSupportTicket(
    String ticketId,
    String message, {
    bool internalNote = false,
  }) async {
    final response = await dio.post(
      '/admin/support-tickets/$ticketId/messages',
      data: {'message': message, 'internalNote': internalNote},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateSupportTicketStatus(
    String ticketId,
    String status,
  ) async {
    final response = await dio.patch(
      '/admin/support-tickets/$ticketId/status',
      data: {'status': status},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateUserStatus(
    String userId,
    bool isActive, {
    String? reason,
  }) async {
    final response = await dio.patch(
      '/admin/users/$userId/status',
      data: {
        'isActive': isActive,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateAdminUserRole(
    String userId,
    String role,
  ) async {
    final response = await dio.patch(
      '/admin/users/$userId/role',
      data: {'role': role},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<List<dynamic>> getAdminOffers() async {
    final response = await dio.get('/admin/offers');
    return response.data;
  }

  Future<Map<String, dynamic>> createAdminOffer(
    Map<String, dynamic> data,
  ) async {
    final response = await dio.post('/admin/offers', data: data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> updateAdminOfferStatus(
    String offerId,
    bool isActive,
  ) async {
    final response = await dio.patch(
      '/admin/offers/$offerId/status',
      data: {'isActive': isActive},
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  // AI Style Studio APIs (/style-studio/*)
  Future<Map<String, dynamic>> getAiStyleOptions() async {
    final response = await dio.get('/style-studio/options');
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> getAiStyleHealth() async {
    final response = await dio.get('/style-studio/health');
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> analyzeAiPhoto({
    required String imageBase64,
  }) async {
    final response = await dio.post(
      '/style-studio/analyze',
      data: {'imageBase64': imageBase64},
      options: Options(
        sendTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
      ),
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> generateAiStyle({
    required String imageBase64,
    String? sideImageBase64,
    String? backImageBase64,
    String? hairStyle,
    String? beardStyle,
    String? hairColor,
    String? beardColor,
    String maintenanceLevel = 'any',
    String styleVibe = 'any',
    String hairLengthPref = 'any',
    String beardPref = 'any',
    int variationsCount = 6,
    String mode = 'storyboard',
    bool consentGiven = true,
    bool async = true,
  }) async {
    final response = await dio.post(
      '/style-studio/generations',
      data: {
        'imageBase64': imageBase64,
        if (sideImageBase64 != null) 'sideImageBase64': sideImageBase64,
        if (backImageBase64 != null) 'backImageBase64': backImageBase64,
        if (hairStyle != null) 'hairStyle': hairStyle,
        if (beardStyle != null) 'beardStyle': beardStyle,
        if (hairColor != null) 'hairColor': hairColor,
        if (beardColor != null) 'beardColor': beardColor,
        'maintenanceLevel': maintenanceLevel,
        'styleVibe': styleVibe,
        'hairLengthPref': hairLengthPref,
        'beardPref': beardPref,
        'variationsCount': variationsCount,
        'mode': mode,
        'consentGiven': consentGiven,
        'async': async,
      },
      options: Options(
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
      ),
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data);
  }

  Future<List<dynamic>> getAiStyleGenerations() async {
    final response = await dio.get('/style-studio/generations');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getAiStyleJob(String jobId) async {
    final response = await dio.get('/style-studio/generations/$jobId');
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data);
  }

  Future<List<dynamic>> getAiGenerationLooks(String jobId) async {
    final response = await dio.get('/style-studio/generations/$jobId/looks');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> deleteAiStyleGeneration(String jobId) async {
    final response = await dio.delete('/style-studio/generations/$jobId');
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> saveAiLook({
    String? jobId,
    String? archetypeId,
    int? optionNumber,
    required String originalImageUrl,
    required String styledImageUrl,
    String? hairStyle,
    String? beardStyle,
    String? title,
    String? notes,
    String? whyItSuits,
    int? suitabilityScore,
    String? maintenanceLevel,
    String? hairLengthCm,
    String? beardLengthMm,
    String? stylingProducts,
    List<String>? barberInstructions,
  }) async {
    final response = await dio.post(
      '/style-studio/save-look',
      data: {
        if (jobId != null) 'jobId': jobId,
        if (archetypeId != null) 'archetypeId': archetypeId,
        if (optionNumber != null) 'optionNumber': optionNumber,
        'originalImageUrl': originalImageUrl,
        'styledImageUrl': styledImageUrl,
        if (hairStyle != null) 'hairStyle': hairStyle,
        if (beardStyle != null) 'beardStyle': beardStyle,
        if (title != null) 'title': title,
        if (notes != null) 'notes': notes,
        if (whyItSuits != null) 'whyItSuits': whyItSuits,
        if (suitabilityScore != null) 'suitabilityScore': suitabilityScore,
        if (maintenanceLevel != null) 'maintenanceLevel': maintenanceLevel,
        if (hairLengthCm != null) 'hairLengthCm': hairLengthCm,
        if (beardLengthMm != null) 'beardLengthMm': beardLengthMm,
        if (stylingProducts != null) 'stylingProducts': stylingProducts,
        if (barberInstructions != null)
          'barberInstructions': barberInstructions,
      },
    );
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data);
  }

  Future<List<dynamic>> getSavedAiLooks() async {
    final response = await dio.get('/style-studio/saved-looks');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> deleteSavedAiLook(String lookId) async {
    final response = await dio.delete('/style-studio/saved-looks/$lookId');
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data);
  }

  Future<Map<String, dynamic>> shareAiLook(String lookId) async {
    final response = await dio.post('/style-studio/looks/$lookId/share');
    return response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data);
  }
}

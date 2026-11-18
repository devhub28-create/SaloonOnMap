import 'dart:developer' as developer;

import 'package:api_client/api_client.dart';

import '../constants/partner_api_urls.dart';
export '../constants/partner_api_urls.dart';

/// Centralized API Handling Service for the Partner App.
/// Encapsulates authentication, salon desk management, bookings & walk-ins,
/// seating, staff/team, services catalog, and reporting with uniform error handling.
class PartnerApiService extends ApiClient {
  static PartnerApiService? _instance;

  PartnerApiService({super.baseUrl, super.storage});

  /// Access singleton instance if needed across widgets and cubits
  static PartnerApiService get instance => _instance ??= PartnerApiService();

  /// Direct access to centralized Partner API URLs & Endpoints
  static PartnerApiUrls get urls => const PartnerApiUrls();

  /// Centralized request execution wrapper with uniform logging & exception mapping
  Future<T> handleRequest<T>(
    Future<T> Function() apiCall, {
    String operation = 'Partner API Call',
  }) async {
    try {
      return await apiCall();
    } on DioException catch (dioErr) {
      final statusCode = dioErr.response?.statusCode;
      final responseData = dioErr.response?.data;
      String errorMessage =
          'Network error occurred. Please check your connection.';

      if (responseData is Map && responseData['message'] != null) {
        final msg = responseData['message'];
        errorMessage = msg is List ? msg.join(', ') : msg.toString();
      } else if (statusCode != null) {
        switch (statusCode) {
          case 400:
            errorMessage =
                'Invalid request parameters. Please check your details.';
            break;
          case 401:
            errorMessage =
                'Invalid credentials or expired session. Please log in again.';
            break;
          case 403:
            errorMessage =
                'Your salon account is pending approval or inactive.';
            break;
          case 404:
            errorMessage = 'Salon resource was not found.';
            break;
          case 409:
            errorMessage = 'Conflict detected with existing record.';
            break;
          case 500:
          case 502:
          case 503:
            errorMessage =
                'Salon server is experiencing issues. Please try again shortly.';
            break;
          default:
            errorMessage = 'Request failed (HTTP $statusCode).';
        }
      }

      developer.log(
        '[$operation Error] $errorMessage (Status: $statusCode)',
        error: dioErr,
      );
      throw PartnerApiException(
        errorMessage,
        statusCode: statusCode,
        originalError: dioErr,
      );
    } catch (e) {
      developer.log('[$operation Unexpected Error] $e', error: e);
      if (e is PartnerApiException) rethrow;
      throw PartnerApiException(
        'An unexpected error occurred: $e',
        originalError: e,
      );
    }
  }

  // ==========================================
  // Auth & Salon Registration APIs
  // ==========================================

  /// Authenticate salon desk partner credentials
  Future<Map<String, dynamic>> loginPartner({
    required String phoneOrEmail,
    required String password,
  }) async {
    return handleRequest(() async {
      final response = await dio.post(
        PartnerApiUrls.partnerLoginEndpoint,
        data: {'phoneOrEmail': phoneOrEmail.trim(), 'password': password},
      );
      return Map<String, dynamic>.from(response.data as Map);
    }, operation: 'Partner Login');
  }

  /// Register new salon partner and workspace
  Future<Map<String, dynamic>> registerPartner(
    Map<String, dynamic> data,
  ) async {
    return handleRequest(() async {
      final response = await dio.post(
        PartnerApiUrls.partnerRegisterEndpoint,
        data: data,
      );
      return Map<String, dynamic>.from(response.data as Map);
    }, operation: 'Partner Registration');
  }

  /// Fetch authenticated partner salon profile
  Future<Map<String, dynamic>> fetchSalonProfile() async {
    return handleRequest(
      () => getPartnerSalon(),
      operation: 'Get Salon Profile',
    );
  }

  /// Update salon profile details (name, area, hours, gender, images)
  Future<Map<String, dynamic>> updateSalonProfile(
    Map<String, dynamic> data,
  ) async {
    return handleRequest(
      () => updatePartnerSalon(data),
      operation: 'Update Salon Profile',
    );
  }

  /// Upload salon gallery image
  Future<String> uploadImage(dynamic fileOrPath) async {
    return handleRequest(
      () => uploadSalonImage(fileOrPath),
      operation: 'Upload Salon Image',
    );
  }

  /// Reverse geocode partner salon GPS location
  Future<String> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await dio
          .get(
            PartnerApiUrls.reverseGeocodeUrl,
            queryParameters: {'format': 'json', 'lat': lat, 'lon': lng},
            options: Options(headers: {'User-Agent': 'SlotPartnerApp/1.0'}),
          )
          .timeout(const Duration(seconds: 4));

      if (response.data != null && response.data['address'] != null) {
        final addr = response.data['address'];
        final suburb =
            addr['suburb'] ?? addr['neighbourhood'] ?? addr['subdistrict'];
        final city =
            addr['city'] ?? addr['town'] ?? addr['county'] ?? 'Bengaluru';
        return suburb != null ? '$suburb, $city' : city.toString();
      }
    } catch (_) {}

    if (lat >= 22.0 && lat <= 23.5 && lng >= 75.0 && lng <= 76.5) {
      return 'Vijay Nagar, Indore';
    }
    return 'Indiranagar, Bengaluru';
  }

  // ==========================================
  // Dashboard & Metrics APIs
  // ==========================================

  /// Fetch real-time salon dashboard stats and today's schedule
  Future<Map<String, dynamic>> fetchDashboard({required String salonId}) async {
    return handleRequest(
      () => getPartnerDashboard(salonId: salonId),
      operation: 'Get Partner Dashboard',
    );
  }

  // ==========================================
  // Bookings & Walk-In APIs
  // ==========================================

  /// Fetch bookings for salon desk with optional status filter
  Future<List<dynamic>> fetchBookings({
    required String salonId,
    String? status,
  }) async {
    return handleRequest(
      () => getPartnerBookings(salonId: salonId, status: status),
      operation: 'Get Partner Bookings',
    );
  }

  /// Add instant walk-in booking
  Future<Map<String, dynamic>> createWalkIn(Map<String, dynamic> data) async {
    return handleRequest(
      () => addWalkIn(data),
      operation: 'Create Walk-In Booking',
    );
  }

  /// Update booking status (CONFIRMED, IN_SERVICE, COMPLETED, CANCELLED)
  Future<Map<String, dynamic>> changeBookingStatus({
    required String bookingId,
    required String status,
    String? rejectionReason,
  }) async {
    return handleRequest(
      () => updateBookingStatus(
        bookingId: bookingId,
        status: status,
        reason: rejectionReason,
      ),
      operation: 'Update Booking Status',
    );
  }

  // ==========================================
  // Chairs & Seats Management APIs
  // ==========================================

  /// Fetch all chairs/seats with live status
  Future<List<dynamic>> fetchSeats({required String salonId}) async {
    return handleRequest(
      () => getPartnerSeats(salonId: salonId),
      operation: 'Get Partner Seats',
    );
  }

  /// Update chair status (AVAILABLE, IN_SERVICE, BLOCKED)
  Future<Map<String, dynamic>> changeSeatStatus({
    required String seatId,
    required String status,
    String? currentStaffName,
  }) async {
    return handleRequest(
      () => updatePartnerSeatStatus(seatId, status),
      operation: 'Update Seat Status',
    );
  }

  /// Configure total chair count for salon
  Future<List<dynamic>> updateSeatCapacity({
    required String salonId,
    required int count,
  }) async {
    return handleRequest(
      () => setPartnerSeatCount(salonId, count),
      operation: 'Set Seat Capacity',
    );
  }

  // ==========================================
  // Services & Combos Catalog APIs
  // ==========================================

  /// Fetch all active services for salon
  Future<List<dynamic>> fetchServices({required String salonId}) async {
    return handleRequest(
      () => getPartnerServices(salonId: salonId),
      operation: 'Get Partner Services',
    );
  }

  /// Fetch combo packages
  Future<List<dynamic>> fetchCombos({required String salonId}) async {
    return handleRequest(
      () => getPartnerCombos(salonId: salonId),
      operation: 'Get Partner Combos',
    );
  }

  /// Add new service to menu
  Future<Map<String, dynamic>> createService(Map<String, dynamic> data) async {
    return handleRequest(
      () => addPartnerService(data),
      operation: 'Add Partner Service',
    );
  }

  /// Update existing service
  Future<Map<String, dynamic>> updateService({
    required String serviceId,
    required Map<String, dynamic> data,
  }) async {
    return handleRequest(
      () => updatePartnerService(serviceId, data),
      operation: 'Update Partner Service',
    );
  }

  // ==========================================
  // Staff & Team Management APIs
  // ==========================================

  /// Fetch team members / stylists
  Future<List<dynamic>> fetchTeam({required String salonId}) async {
    return handleRequest(
      () => getPartnerStaff(salonId: salonId),
      operation: 'Get Partner Staff',
    );
  }

  /// Add new staff member
  Future<Map<String, dynamic>> addTeamMember(Map<String, dynamic> data) async {
    return handleRequest(
      () => addPartnerStaff(data),
      operation: 'Add Team Member',
    );
  }

  /// Update staff member details
  Future<Map<String, dynamic>> updateTeamMember({
    required String staffId,
    required Map<String, dynamic> data,
  }) async {
    return handleRequest(
      () => updatePartnerStaff(staffId, data),
      operation: 'Update Team Member',
    );
  }

  /// Remove team member
  Future<Map<String, dynamic>> removeTeamMember(String staffId) async {
    return handleRequest(
      () => deletePartnerStaff(staffId),
      operation: 'Delete Team Member',
    );
  }
}

/// Centralized API Exception for Partner App
class PartnerApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  PartnerApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => message;
}

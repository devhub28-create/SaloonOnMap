import 'dart:developer' as developer;

import 'package:api_client/api_client.dart';

import '../constants/customer_api_urls.dart';
export '../constants/customer_api_urls.dart';

/// Centralized API Handling Service for the User/Customer App.
/// Encapsulates authentication, home discovery, booking holds & confirmations,
/// reviews, notifications, reverse-geocoding, and AI styling with uniform error handling.
class CustomerApiService extends ApiClient {
  static CustomerApiService? _instance;

  CustomerApiService({super.baseUrl, super.storage});

  /// Access singleton instance if needed across widgets and cubits
  static CustomerApiService get instance => _instance ??= CustomerApiService();

  /// Direct access to centralized Customer API URLs & Endpoints
  static CustomerApiUrls get urls => const CustomerApiUrls();

  /// Centralized request execution wrapper with uniform logging & exception mapping
  Future<T> handleRequest<T>(
    Future<T> Function() apiCall, {
    String operation = 'Customer API Call',
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
                'Invalid request parameters. Please verify your details.';
            break;
          case 401:
            errorMessage = 'Your session has expired. Please sign in again.';
            break;
          case 403:
            errorMessage = 'You do not have permission to perform this action.';
            break;
          case 404:
            errorMessage = 'Requested resource was not found.';
            break;
          case 409:
            errorMessage = 'Conflict detected. Please refresh and try again.';
            break;
          case 500:
          case 502:
          case 503:
            errorMessage =
                'Server is currently unavailable. Please try again shortly.';
            break;
          default:
            errorMessage = 'Server error occurred (Code $statusCode).';
        }
      }

      developer.log(
        '[$operation Error] $errorMessage (HTTP $statusCode)',
        error: dioErr,
      );
      throw CustomerApiException(
        errorMessage,
        statusCode: statusCode,
        originalError: dioErr,
      );
    } catch (e) {
      developer.log('[$operation Unexpected Error] $e', error: e);
      if (e is CustomerApiException) rethrow;
      throw CustomerApiException(
        'An unexpected error occurred: $e',
        originalError: e,
      );
    }
  }

  // ==========================================
  // Auth & Account Management
  // ==========================================

  /// Request OTP for customer phone number
  Future<Map<String, dynamic>> requestOtpCode(String phone) async {
    return handleRequest(() => requestOtp(phone), operation: 'Request OTP');
  }

  /// Verify the one-time code delivered to the customer.
  Future<Map<String, dynamic>> verifyOtpCode(
    String phone,
    String code, {
    String? name,
    String? email,
  }) async {
    return handleRequest(
      () => verifyOtp(phone, code, name: name, email: email),
      operation: 'Verify OTP',
    );
  }

  /// Fetch authenticated customer profile
  Future<Map<String, dynamic>> fetchCustomerProfile() async {
    return handleRequest(
      () => getCustomerProfile(),
      operation: 'Get Customer Profile',
    );
  }

  /// Update customer profile details
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return handleRequest(
      () => updateCustomerProfile(data),
      operation: 'Update Customer Profile',
    );
  }

  /// Log out from customer session
  Future<void> logOutCustomer() async {
    return handleRequest(() => logout(), operation: 'Customer Logout');
  }

  // ==========================================
  // Discovery, Search & Geocoding
  // ==========================================

  /// Fetch personalized home screen feed (banners, categories, salons)
  Future<Map<String, dynamic>> fetchHomeData({double? lat, double? lng}) async {
    return handleRequest(
      () => getCustomerHome(lat: lat, lng: lng),
      operation: 'Get Customer Home Feed',
    );
  }

  /// Search and filter salons with location and categories
  Future<List<dynamic>> searchSalons({
    double? lat,
    double? lng,
    String? query,
    String? category,
    String? gender,
  }) async {
    return handleRequest(
      () => getSalons(
        lat: lat,
        lng: lng,
        search: query,
        area: category,
        gender: gender,
      ),
      operation: 'Search Salons',
    );
  }

  /// Fetch detailed salon view with services and seating
  Future<Map<String, dynamic>> fetchSalonDetails(String salonId) async {
    return handleRequest(
      () => getSalonDetails(salonId),
      operation: 'Get Salon Details',
    );
  }

  /// Centralized reverse geocoding via OpenStreetMap with fallback
  Future<String> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    try {
      final response = await dio
          .get(
            CustomerApiUrls.reverseGeocodeUrl,
            queryParameters: {'format': 'json', 'lat': lat, 'lon': lng},
            options: Options(headers: {'User-Agent': 'SlotApp/1.0'}),
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
    } catch (_) {
      // Fallback
    }

    if (lat >= 22.0 && lat <= 23.5 && lng >= 75.0 && lng <= 76.5) {
      return 'Vijay Nagar, Indore';
    }
    return 'Indiranagar, Bengaluru';
  }

  // ==========================================
  // Bookings, Holds & Reviews
  // ==========================================

  /// Fetch active and past bookings for customer
  Future<List<dynamic>> fetchCustomerBookings({String? customerId}) async {
    return handleRequest(
      () => getCustomerBookings(customerId: customerId),
      operation: 'Get Customer Bookings',
    );
  }

  /// Check seat availability slots for salon & service on date
  Future<Map<String, dynamic>> fetchAvailableSlots(
    String salonId, {
    String? date,
    int? duration,
  }) async {
    return handleRequest(
      () => getAvailableSlots(salonId, date: date, duration: duration),
      operation: 'Get Available Slots',
    );
  }

  /// Create seat hold before checkout
  Future<Map<String, dynamic>> holdSlot(Map<String, dynamic> data) async {
    return handleRequest(() => createHold(data), operation: 'Create Slot Hold');
  }

  /// Confirm booking after payment / slot confirmation
  Future<Map<String, dynamic>> confirmReservation(
    Map<String, dynamic> data,
  ) async {
    return handleRequest(
      () => confirmBooking(data),
      operation: 'Confirm Booking',
    );
  }

  /// Cancel existing booking
  Future<Map<String, dynamic>> cancelReservation(
    String bookingId, {
    String? reason,
  }) async {
    return handleRequest(
      () => cancelBooking(bookingId, reason: reason),
      operation: 'Cancel Booking',
    );
  }

  /// Submit review for completed booking
  Future<Map<String, dynamic>> submitReview({
    required String bookingId,
    required int rating,
    String? comment,
    List<String>? tags,
  }) async {
    return handleRequest(
      () => createReview(
        bookingId: bookingId,
        rating: rating,
        comment: comment,
        tags: tags,
      ),
      operation: 'Submit Review',
    );
  }

  // ==========================================
  // Offers & Notifications
  // ==========================================

  /// Fetch active deals and banners
  Future<List<dynamic>> fetchOffers() async {
    return handleRequest(() => getCustomerOffers(), operation: 'Get Offers');
  }

  /// Fetch customer notification list
  Future<List<dynamic>> fetchNotifications() async {
    return handleRequest(
      () => getNotifications(),
      operation: 'Get Notifications',
    );
  }

  /// Mark all notifications read
  Future<void> markNotificationsRead() async {
    return handleRequest(
      () => markAllNotificationsRead(),
      operation: 'Mark Notifications Read',
    );
  }
}

/// Centralized API Exception for User/Customer App
class CustomerApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  CustomerApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => message;
}

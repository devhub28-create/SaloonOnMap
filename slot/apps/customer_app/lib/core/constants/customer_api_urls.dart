import 'package:api_client/api_client.dart';

/// Centralized API URLs and Endpoints for the Customer App.
/// Contains base URL, relative endpoints, and computed full URLs
/// formatted as: fullUrl = baseUrl + endpoint.
class CustomerApiUrls {
  const CustomerApiUrls();

  /// Centralized API Base URL (environment/platform aware)
  static String get baseUrl => ApiConfig.baseUrl;

  // ==========================================
  // Relative Endpoint Strings
  // ==========================================
  static const String requestOtpEndpoint = '/auth/request-otp';
  static const String verifyOtpEndpoint = '/auth/verify-otp';
  static const String customerProfileEndpoint = '/auth/customer/profile';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';

  static const String homeEndpoint = '/customer/home';
  static const String offersEndpoint = '/customer/offers';
  static const String notificationsEndpoint = '/notifications';
  static const String notificationsReadAllEndpoint = '/notifications/read-all';

  static const String salonsEndpoint = '/salons';
  static const String bookingsEndpoint = '/bookings';
  static const String bookingHoldsEndpoint = '/bookings/holds';
  static const String customerBookingsEndpoint = '/customer/bookings';
  static const String reviewsEndpoint = '/reviews';

  // AI Style Studio Endpoints
  static const String aiStyleOptionsEndpoint = '/style-studio/options';
  static const String aiStyleHealthEndpoint = '/style-studio/health';
  static const String aiStyleAnalyzeEndpoint = '/style-studio/analyze';
  static const String aiStyleGenerationsEndpoint = '/style-studio/generations';
  static const String aiStyleSaveLookEndpoint = '/style-studio/save-look';
  static const String aiStyleSavedLooksEndpoint = '/style-studio/saved-looks';

  // Reverse Geocoding
  static const String reverseGeocodeUrl =
      'https://nominatim.openstreetmap.org/reverse';

  // ==========================================
  // Computed Full URLs: baseUrl + endpoint
  // ==========================================
  static String get requestOtpUrl => '$baseUrl$requestOtpEndpoint';
  static String get verifyOtpUrl => '$baseUrl$verifyOtpEndpoint';
  static String get customerProfileUrl => '$baseUrl$customerProfileEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';

  static String get homeUrl => '$baseUrl$homeEndpoint';
  static String get offersUrl => '$baseUrl$offersEndpoint';
  static String get notificationsUrl => '$baseUrl$notificationsEndpoint';
  static String get notificationsReadAllUrl =>
      '$baseUrl$notificationsReadAllEndpoint';

  static String get salonsUrl => '$baseUrl$salonsEndpoint';
  static String get bookingsUrl => '$baseUrl$bookingsEndpoint';
  static String get bookingHoldsUrl => '$baseUrl$bookingHoldsEndpoint';
  static String get customerBookingsUrl => '$baseUrl$customerBookingsEndpoint';
  static String get reviewsUrl => '$baseUrl$reviewsEndpoint';

  // AI Style Studio Computed URLs
  static String get aiStyleOptionsUrl => '$baseUrl$aiStyleOptionsEndpoint';
  static String get aiStyleHealthUrl => '$baseUrl$aiStyleHealthEndpoint';
  static String get aiStyleAnalyzeUrl => '$baseUrl$aiStyleAnalyzeEndpoint';
  static String get aiStyleGenerationsUrl =>
      '$baseUrl$aiStyleGenerationsEndpoint';
  static String get aiStyleSaveLookUrl => '$baseUrl$aiStyleSaveLookEndpoint';
  static String get aiStyleSavedLooksUrl =>
      '$baseUrl$aiStyleSavedLooksEndpoint';

  // ==========================================
  // Dynamic Full URLs with Path Parameters
  // ==========================================
  static String salonDetailsUrl(String salonId) =>
      '$baseUrl$salonsEndpoint/$salonId';
  static String availableSlotsUrl(String salonId) =>
      '$baseUrl$salonsEndpoint/$salonId/available-slots';
  static String cancelBookingUrl(String bookingId) =>
      '$baseUrl$bookingsEndpoint/$bookingId/cancel';
  static String bookingStatusUrl(String bookingId) =>
      '$baseUrl$bookingsEndpoint/$bookingId/status';
  static String salonReviewsUrl(String salonId) =>
      '$baseUrl$salonsEndpoint/$salonId/reviews';
  static String bookingReviewUrl(String bookingId) =>
      '$baseUrl$reviewsEndpoint/booking/$bookingId';
  static String aiStyleJobUrl(String jobId) =>
      '$baseUrl$aiStyleGenerationsEndpoint/$jobId';
  static String aiStyleLooksUrl(String jobId) =>
      '$baseUrl$aiStyleGenerationsEndpoint/$jobId/looks';
}

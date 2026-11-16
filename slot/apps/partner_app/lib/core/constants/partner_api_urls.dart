import 'package:api_client/api_client.dart';

/// Centralized API URLs and Endpoints for the Partner App.
/// Contains base URL, relative endpoints, and computed full URLs
/// formatted as: fullUrl = baseUrl + endpoint.
class PartnerApiUrls {
  const PartnerApiUrls();

  /// Centralized API Base URL (environment/platform aware)
  static String get baseUrl => ApiConfig.baseUrl;

  // ==========================================
  // Relative Endpoint Strings
  // ==========================================
  static const String partnerLoginEndpoint = '/auth/login-partner';
  static const String partnerRegisterEndpoint = '/auth/register-partner';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';

  static const String salonProfileEndpoint = '/partner/salon';
  static const String uploadSalonImageEndpoint = '/salons/upload-image';
  static const String dashboardEndpoint = '/partner/dashboard';
  static const String bookingsEndpoint = '/partner/bookings';
  static const String walkInEndpoint = '/partner/walkin';
  static const String seatsEndpoint = '/partner/seats';
  static const String servicesEndpoint = '/partner/services';
  static const String combosEndpoint = '/partner/combos';
  static const String staffEndpoint = '/partner/staff';
  static const String reportsEndpoint = '/partner/reports';
  static const String reviewsEndpoint = '/partner/reviews';

  // Reverse Geocoding
  static const String reverseGeocodeUrl = 'https://nominatim.openstreetmap.org/reverse';

  // ==========================================
  // Computed Full URLs: baseUrl + endpoint
  // ==========================================
  static String get partnerLoginUrl => '$baseUrl$partnerLoginEndpoint';
  static String get partnerRegisterUrl => '$baseUrl$partnerRegisterEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';

  static String get salonProfileUrl => '$baseUrl$salonProfileEndpoint';
  static String get uploadSalonImageUrl => '$baseUrl$uploadSalonImageEndpoint';
  static String get dashboardUrl => '$baseUrl$dashboardEndpoint';
  static String get bookingsUrl => '$baseUrl$bookingsEndpoint';
  static String get walkInUrl => '$baseUrl$walkInEndpoint';
  static String get seatsUrl => '$baseUrl$seatsEndpoint';
  static String get servicesUrl => '$baseUrl$servicesEndpoint';
  static String get combosUrl => '$baseUrl$combosEndpoint';
  static String get staffUrl => '$baseUrl$staffEndpoint';
  static String get reportsUrl => '$baseUrl$reportsEndpoint';
  static String get reviewsUrl => '$baseUrl$reviewsEndpoint';

  // ==========================================
  // Dynamic Full URLs with Path Parameters
  // ==========================================
  static String bookingStatusUrl(String bookingId) => '$baseUrl/bookings/$bookingId/status';
  static String seatStatusUrl(String seatId) => '$baseUrl$seatsEndpoint/$seatId/status';
  static String serviceByIdUrl(String id) => '$baseUrl$servicesEndpoint/$id';
  static String staffByIdUrl(String id) => '$baseUrl$staffEndpoint/$id';
}

import 'package:api_client/api_client.dart';

/// Centralized API URLs and Endpoints for the Admin Panel.
/// Contains base URL, relative endpoints, and computed full URLs
/// formatted as: fullUrl = baseUrl + endpoint.
class AdminApiUrls {
  const AdminApiUrls();

  /// Centralized API Base URL (environment/platform aware)
  static String get baseUrl => ApiConfig.baseUrl;

  // ==========================================
  // Relative Endpoint Strings
  // ==========================================
  static const String loginEndpoint = '/auth/login-admin';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';

  static const String dashboardEndpoint = '/admin/dashboard';
  static const String pendingSalonsEndpoint = '/admin/salons/pending';
  static const String usersEndpoint = '/admin/users';
  static const String bookingsEndpoint = '/admin/bookings';
  static const String auditLogsEndpoint = '/admin/audit-logs';

  // ==========================================
  // Computed Full URLs: baseUrl + endpoint
  // ==========================================
  static String get loginUrl => '$baseUrl$loginEndpoint';
  static String get logoutUrl => '$baseUrl$logoutEndpoint';
  static String get refreshTokenUrl => '$baseUrl$refreshTokenEndpoint';

  static String get dashboardUrl => '$baseUrl$dashboardEndpoint';
  static String get pendingSalonsUrl => '$baseUrl$pendingSalonsEndpoint';
  static String get usersUrl => '$baseUrl$usersEndpoint';
  static String get bookingsUrl => '$baseUrl$bookingsEndpoint';
  static String get auditLogsUrl => '$baseUrl$auditLogsEndpoint';

  // ==========================================
  // Dynamic Full URLs with Path Parameters
  // ==========================================
  static String reviewSalonUrl(String salonId) => '$baseUrl/admin/salons/$salonId/review';
  static String userStatusUrl(String userId) => '$baseUrl$usersEndpoint/$userId/status';
}

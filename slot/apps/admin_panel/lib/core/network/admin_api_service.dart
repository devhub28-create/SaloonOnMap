import 'dart:developer' as developer;
import 'package:api_client/api_client.dart';
import '../constants/admin_api_urls.dart';
export '../constants/admin_api_urls.dart';

/// Centralized API Handling Service for the Admin Panel.
/// Encapsulates platform authentication, system dashboard, salon verifications,
/// user moderation, booking oversight, and audit logs with uniform error handling.
class AdminApiService extends ApiClient {
  static AdminApiService? _instance;

  AdminApiService({super.baseUrl, super.storage});

  /// Access singleton instance if needed across widgets and cubits
  static AdminApiService get instance => _instance ??= AdminApiService();

  /// Direct access to centralized Admin API URLs & Endpoints
  static AdminApiUrls get urls => const AdminApiUrls();

  /// Centralized request execution wrapper with uniform logging & exception mapping
  Future<T> handleRequest<T>(
    Future<T> Function() apiCall, {
    String operation = 'Admin API Call',
  }) async {
    try {
      return await apiCall();
    } on DioException catch (dioErr) {
      final statusCode = dioErr.response?.statusCode;
      final responseData = dioErr.response?.data;
      String errorMessage = 'Network error occurred. Please check your connection.';

      if (responseData is Map && responseData['message'] != null) {
        final msg = responseData['message'];
        errorMessage = msg is List ? msg.join(', ') : msg.toString();
      } else if (statusCode != null) {
        switch (statusCode) {
          case 400:
            errorMessage = 'Invalid admin parameters. Please verify input.';
            break;
          case 401:
            errorMessage = 'Admin session expired or credentials invalid.';
            break;
          case 403:
            errorMessage = 'Restricted: Super-administrator permissions required.';
            break;
          case 404:
            errorMessage = 'Target resource was not found.';
            break;
          case 500:
          case 502:
          case 503:
            errorMessage = 'Admin backend is currently unreachable. Please try again shortly.';
            break;
          default:
            errorMessage = 'Admin request failed (HTTP $statusCode).';
        }
      }

      developer.log('[$operation Error] $errorMessage (Status: $statusCode)', error: dioErr);
      throw AdminApiException(errorMessage, statusCode: statusCode, originalError: dioErr);
    } catch (e) {
      developer.log('[$operation Unexpected Error] $e', error: e);
      if (e is AdminApiException) rethrow;
      throw AdminApiException('An unexpected error occurred: $e', originalError: e);
    }
  }

  // ==========================================
  // Admin Auth APIs
  // ==========================================

  /// Authenticate platform administrator credentials
  Future<Map<String, dynamic>> loginAdministrator({
    required String email,
    required String password,
  }) async {
    return handleRequest(
      () => loginAdmin(email.trim(), password),
      operation: 'Admin Login',
    );
  }

  /// Administrator logout
  Future<void> logOutAdministrator() async {
    return handleRequest(
      () => logout(),
      operation: 'Admin Logout',
    );
  }

  // ==========================================
  // Platform Dashboard & Metrics
  // ==========================================

  /// Fetch overall platform metrics (GMV, active users, total salons, booking counts)
  Future<Map<String, dynamic>> fetchPlatformDashboard() async {
    return handleRequest(
      () => getAdminDashboard(),
      operation: 'Get Admin Dashboard',
    );
  }

  // ==========================================
  // Salon Approval & Onboarding Management
  // ==========================================

  /// Fetch salons awaiting platform verification
  Future<List<dynamic>> fetchPendingSalons() async {
    return handleRequest(
      () => getPendingSalons(),
      operation: 'Get Pending Salons',
    );
  }

  /// Approve or reject salon registration
  Future<Map<String, dynamic>> reviewPartnerSalon({
    required String salonId,
    required String action,
    String? reason,
  }) async {
    return handleRequest(
      () => reviewSalon(salonId, action, reason: reason),
      operation: 'Review Salon ($action)',
    );
  }

  // ==========================================
  // User Management APIs
  // ==========================================

  /// Fetch all platform users across customers and partners
  Future<List<dynamic>> fetchPlatformUsers() async {
    return handleRequest(
      () => getAdminUsers(),
      operation: 'Get Admin Users',
    );
  }

  /// Toggle user activation state (ban / unban)
  Future<Map<String, dynamic>> changeUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    return handleRequest(
      () => updateUserStatus(userId, isActive),
      operation: 'Update User Status',
    );
  }

  // ==========================================
  // Booking Oversight & Audit Logs
  // ==========================================

  /// Fetch platform-wide bookings for auditing
  Future<List<dynamic>> fetchPlatformBookings() async {
    return handleRequest(
      () => getAdminBookings(),
      operation: 'Get Admin Bookings',
    );
  }

  /// Fetch administrative audit logs for compliance tracking
  Future<List<dynamic>> fetchAuditLogs() async {
    return handleRequest(
      () => getAdminAuditLogs(),
      operation: 'Get Audit Logs',
    );
  }
}

/// Centralized API Exception for Admin Panel
class AdminApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  AdminApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => message;
}

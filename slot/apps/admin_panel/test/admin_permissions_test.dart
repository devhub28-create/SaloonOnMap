import 'package:admin_panel/core/auth/admin_permissions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminPermissions', () {
    test('operations admins can manage salons but cannot manage offers', () {
      expect(
          AdminPermissions.canViewRoute('OPERATIONS_ADMIN', '/salons'), isTrue);
      expect(AdminPermissions.canManageSalons('OPERATIONS_ADMIN'), isTrue);
      expect(AdminPermissions.canViewRoute('OPERATIONS_ADMIN', '/offers'),
          isFalse);
    });

    test('support admins can inspect but cannot moderate reviews', () {
      expect(
          AdminPermissions.canViewRoute('SUPPORT_ADMIN', '/reviews'), isTrue);
      expect(AdminPermissions.canModerateReviews('SUPPORT_ADMIN'), isFalse);
    });

    test('operations admins can moderate reviews and bookings', () {
      expect(AdminPermissions.canModerateReviews('OPERATIONS_ADMIN'), isTrue);
      expect(AdminPermissions.canManageBookings('OPERATIONS_ADMIN'), isTrue);
      expect(AdminPermissions.canManageAdminRoles('OPERATIONS_ADMIN'), isFalse);
      expect(AdminPermissions.canManageAdminRoles('SUPER_ADMIN'), isTrue);
    });

    test('support admins only see support-safe operational routes', () {
      expect(AdminPermissions.canViewRoute('SUPPORT_ADMIN', '/users'), isTrue);
      expect(
          AdminPermissions.canViewRoute('SUPPORT_ADMIN', '/bookings'), isTrue);
      expect(
          AdminPermissions.canViewRoute('SUPPORT_ADMIN', '/salons'), isFalse);
      expect(
          AdminPermissions.canViewRoute('SUPPORT_ADMIN', '/support'), isTrue);
      expect(AdminPermissions.canViewRoute('SUPPORT_ADMIN', '/system-health'),
          isTrue);
      expect(AdminPermissions.canViewRoute('SUPPORT_ADMIN', '/analytics'),
          isFalse);
    });

    test('marketing admins can access offers without user moderation', () {
      expect(
          AdminPermissions.canViewRoute('MARKETING_ADMIN', '/offers'), isTrue);
      expect(
          AdminPermissions.canViewRoute('MARKETING_ADMIN', '/users'), isFalse);
      expect(AdminPermissions.canViewRoute('MARKETING_ADMIN', '/notifications'),
          isTrue);
      expect(AdminPermissions.canSendNotifications('MARKETING_ADMIN'), isTrue);
    });
  });
}

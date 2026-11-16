class AdminPermissions {
  const AdminPermissions._();

  static const _fullAccessRoles = {
    'ADMIN',
    'SUPER_ADMIN',
    'OPERATIONS_ADMIN',
  };

  static bool canViewRoute(String role, String route) {
    if (route == '/offers') {
      return {'ADMIN', 'SUPER_ADMIN', 'MARKETING_ADMIN'}.contains(role);
    }
    if (route == '/notifications') {
      return {'ADMIN', 'SUPER_ADMIN', 'OPERATIONS_ADMIN', 'MARKETING_ADMIN'}
          .contains(role);
    }
    if (_fullAccessRoles.contains(role)) return true;
    if (role == 'SUPPORT_ADMIN') {
      return {
        '/',
        '/users',
        '/bookings',
        '/reviews',
        '/audit-logs',
        '/ai-operations',
        '/support',
        '/system-health'
      }.contains(route);
    }
    if (role == 'MARKETING_ADMIN') {
      return {'/', '/offers', '/notifications'}.contains(route);
    }
    return false;
  }

  static bool canManageSalons(String role) => _fullAccessRoles.contains(role);

  static bool canManageUsers(String role) => _fullAccessRoles.contains(role);

  static bool canManageAdminRoles(String role) => role == 'SUPER_ADMIN';

  static bool canManageBookings(String role) => _fullAccessRoles.contains(role);

  static bool canModerateReviews(String role) =>
      _fullAccessRoles.contains(role);

  static bool canSendNotifications(String role) => {
        'ADMIN',
        'SUPER_ADMIN',
        'OPERATIONS_ADMIN',
        'MARKETING_ADMIN'
      }.contains(role);
}

import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/admin_error_message.dart';

abstract class AdminUsersState {}

class AdminUsersInitial extends AdminUsersState {}

class AdminUsersLoading extends AdminUsersState {}

class AdminUsersLoaded extends AdminUsersState {
  final List<Map<String, dynamic>> users;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String role;
  final String status;
  AdminUsersLoaded(
      {required this.users,
      required this.total,
      required this.page,
      required this.limit,
      required this.search,
      required this.role,
      required this.status});
}

class AdminUsersError extends AdminUsersState {
  final String message;
  AdminUsersError(this.message);
}

class AdminUsersCubit extends Cubit<AdminUsersState> {
  final ApiClient apiClient;
  AdminUsersCubit({required this.apiClient}) : super(AdminUsersInitial());

  Future<void> fetchUsers(
      {String search = '',
      String role = 'ALL',
      String status = 'ALL',
      int page = 1}) async {
    emit(AdminUsersLoading());
    try {
      final response = await apiClient.getAdminUsers(
          search: search, role: role, status: status, page: page);
      final users = (response['items'] as List<dynamic>? ?? const [])
          .map((user) => Map<String, dynamic>.from(user as Map))
          .toList();
      emit(AdminUsersLoaded(
          users: users,
          total: (response['total'] as num?)?.toInt() ?? users.length,
          page: (response['page'] as num?)?.toInt() ?? page,
          limit: (response['limit'] as num?)?.toInt() ?? 25,
          search: search,
          role: role,
          status: status));
    } catch (error) {
      emit(AdminUsersError(
          adminErrorMessage(error, fallback: 'Users could not be loaded.')));
    }
  }

  Future<bool> setActive(String userId, bool isActive, {String? reason}) async {
    final previous =
        state is AdminUsersLoaded ? state as AdminUsersLoaded : null;
    try {
      await apiClient.updateUserStatus(userId, isActive, reason: reason);
      await fetchUsers(
          search: previous?.search ?? '',
          role: previous?.role ?? 'ALL',
          status: previous?.status ?? 'ALL',
          page: previous?.page ?? 1);
      return true;
    } catch (error) {
      emit(AdminUsersError(adminErrorMessage(error,
          fallback: 'The user status could not be updated.')));
      return false;
    }
  }

  Future<bool> setRole(String userId, String role) async {
    final previous =
        state is AdminUsersLoaded ? state as AdminUsersLoaded : null;
    try {
      await apiClient.updateAdminUserRole(userId, role);
      await fetchUsers(
          search: previous?.search ?? '',
          role: previous?.role ?? 'ALL',
          status: previous?.status ?? 'ALL',
          page: previous?.page ?? 1);
      return true;
    } catch (error) {
      emit(AdminUsersError(adminErrorMessage(error,
          fallback: 'The administrator role could not be updated.')));
      return false;
    }
  }
}

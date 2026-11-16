import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AdminUsersState {}

class AdminUsersInitial extends AdminUsersState {}

class AdminUsersLoading extends AdminUsersState {}

class AdminUsersLoaded extends AdminUsersState {
  final List<Map<String, dynamic>> users;
  AdminUsersLoaded(this.users);
}

class AdminUsersError extends AdminUsersState {
  final String message;
  AdminUsersError(this.message);
}

class AdminUsersCubit extends Cubit<AdminUsersState> {
  final ApiClient apiClient;
  AdminUsersCubit({required this.apiClient}) : super(AdminUsersInitial());

  Future<void> fetchUsers() async {
    emit(AdminUsersLoading());
    try {
      final users = await apiClient.getAdminUsers();
      emit(AdminUsersLoaded(users
          .map((user) => Map<String, dynamic>.from(user as Map))
          .toList()));
    } catch (error) {
      emit(AdminUsersError('Failed to load users: $error'));
    }
  }

  Future<void> setActive(String userId, bool isActive) async {
    try {
      await apiClient.updateUserStatus(userId, isActive);
      await fetchUsers();
    } catch (error) {
      emit(AdminUsersError('Failed to update user: $error'));
    }
  }
}

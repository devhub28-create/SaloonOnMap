import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/admin_error_message.dart';

sealed class AdminSystemHealthState {}

class AdminSystemHealthInitial extends AdminSystemHealthState {}

class AdminSystemHealthLoading extends AdminSystemHealthState {}

class AdminSystemHealthError extends AdminSystemHealthState {
  final String message;
  AdminSystemHealthError(this.message);
}

class AdminSystemHealthLoaded extends AdminSystemHealthState {
  final Map<String, dynamic> data;
  AdminSystemHealthLoaded(this.data);
}

class AdminSystemHealthCubit extends Cubit<AdminSystemHealthState> {
  final ApiClient apiClient;
  AdminSystemHealthCubit({required this.apiClient})
      : super(AdminSystemHealthInitial());
  Future<void> fetch() async {
    emit(AdminSystemHealthLoading());
    try {
      emit(AdminSystemHealthLoaded(await apiClient.getAdminSystemHealth()));
    } catch (error) {
      emit(AdminSystemHealthError(adminErrorMessage(error,
          fallback: 'System health could not be loaded.')));
    }
  }
}

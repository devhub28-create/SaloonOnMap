import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/admin_error_message.dart';

sealed class AdminAiOperationsState {}

class AdminAiOperationsInitial extends AdminAiOperationsState {}

class AdminAiOperationsLoading extends AdminAiOperationsState {}

class AdminAiOperationsError extends AdminAiOperationsState {
  final String message;
  AdminAiOperationsError(this.message);
}

class AdminAiOperationsLoaded extends AdminAiOperationsState {
  final Map<String, dynamic> data;
  AdminAiOperationsLoaded(this.data);
}

class AdminAiOperationsCubit extends Cubit<AdminAiOperationsState> {
  final ApiClient apiClient;
  AdminAiOperationsCubit({required this.apiClient})
      : super(AdminAiOperationsInitial());
  Future<void> fetchOperations() async {
    emit(AdminAiOperationsLoading());
    try {
      emit(
          AdminAiOperationsLoaded(await apiClient.getAdminAiStyleOperations()));
    } catch (error) {
      emit(AdminAiOperationsError(adminErrorMessage(error,
          fallback: 'AI operations could not be loaded.')));
    }
  }
}

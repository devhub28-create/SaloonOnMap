import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AdminAuditLogsState {}

class AdminAuditLogsInitial extends AdminAuditLogsState {}

class AdminAuditLogsLoading extends AdminAuditLogsState {}

class AdminAuditLogsLoaded extends AdminAuditLogsState {
  final List<Map<String, dynamic>> logs;
  AdminAuditLogsLoaded(this.logs);
}

class AdminAuditLogsError extends AdminAuditLogsState {
  final String message;
  AdminAuditLogsError(this.message);
}

class AdminAuditLogsCubit extends Cubit<AdminAuditLogsState> {
  final ApiClient apiClient;
  AdminAuditLogsCubit({required this.apiClient})
      : super(AdminAuditLogsInitial());

  Future<void> fetchLogs() async {
    emit(AdminAuditLogsLoading());
    try {
      final logs = await apiClient.getAdminAuditLogs();
      emit(AdminAuditLogsLoaded(
          logs.map((log) => Map<String, dynamic>.from(log as Map)).toList()));
    } catch (error) {
      emit(AdminAuditLogsError('Failed to load audit logs: $error'));
    }
  }
}

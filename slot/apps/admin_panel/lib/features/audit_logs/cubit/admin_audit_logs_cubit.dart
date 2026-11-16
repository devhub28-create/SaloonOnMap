import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/admin_error_message.dart';

abstract class AdminAuditLogsState {}

class AdminAuditLogsInitial extends AdminAuditLogsState {}

class AdminAuditLogsLoading extends AdminAuditLogsState {}

class AdminAuditLogsLoaded extends AdminAuditLogsState {
  final List<Map<String, dynamic>> logs;
  final int total;
  final int page;
  final int limit;
  final List<String> actions;
  final List<String> entityTypes;
  final String search;
  final String action;
  final String entityType;
  AdminAuditLogsLoaded(
      {required this.logs,
      required this.total,
      required this.page,
      required this.limit,
      required this.actions,
      required this.entityTypes,
      required this.search,
      required this.action,
      required this.entityType});
}

class AdminAuditLogsError extends AdminAuditLogsState {
  final String message;
  AdminAuditLogsError(this.message);
}

class AdminAuditLogsCubit extends Cubit<AdminAuditLogsState> {
  final ApiClient apiClient;
  AdminAuditLogsCubit({required this.apiClient})
      : super(AdminAuditLogsInitial());

  Future<void> fetchLogs(
      {String search = '',
      String action = 'ALL',
      String entityType = 'ALL',
      int page = 1}) async {
    emit(AdminAuditLogsLoading());
    try {
      final response = await apiClient.getAdminAuditLogs(
          search: search, action: action, entityType: entityType, page: page);
      final logs = (response['items'] as List<dynamic>? ?? const [])
          .map((log) => Map<String, dynamic>.from(log as Map))
          .toList();
      emit(AdminAuditLogsLoaded(
          logs: logs,
          total: (response['total'] as num?)?.toInt() ?? logs.length,
          page: (response['page'] as num?)?.toInt() ?? page,
          limit: (response['limit'] as num?)?.toInt() ?? 25,
          actions: (response['actions'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
          entityTypes: (response['entityTypes'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
          search: search,
          action: action,
          entityType: entityType));
    } catch (error) {
      emit(AdminAuditLogsError(adminErrorMessage(error,
          fallback: 'Audit logs could not be loaded.')));
    }
  }
}

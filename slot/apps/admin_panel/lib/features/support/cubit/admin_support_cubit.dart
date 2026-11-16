import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/admin_error_message.dart';

sealed class AdminSupportState {}

class AdminSupportInitial extends AdminSupportState {}

class AdminSupportLoading extends AdminSupportState {}

class AdminSupportError extends AdminSupportState {
  final String message;
  AdminSupportError(this.message);
}

class AdminSupportLoaded extends AdminSupportState {
  final List<Map<String, dynamic>> tickets;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String status;
  final String priority;
  AdminSupportLoaded(
      {required this.tickets,
      required this.total,
      required this.page,
      required this.limit,
      required this.search,
      required this.status,
      required this.priority});
}

class AdminSupportCubit extends Cubit<AdminSupportState> {
  final ApiClient apiClient;
  AdminSupportCubit({required this.apiClient}) : super(AdminSupportInitial());
  Future<void> fetch(
      {String search = '',
      String status = 'ALL',
      String priority = 'ALL',
      int page = 1}) async {
    emit(AdminSupportLoading());
    try {
      final data = await apiClient.getAdminSupportTickets(
          search: search, status: status, priority: priority, page: page);
      final items = (data['items'] as List<dynamic>? ?? const [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      emit(AdminSupportLoaded(
          tickets: items,
          total: (data['total'] as num?)?.toInt() ?? items.length,
          page: (data['page'] as num?)?.toInt() ?? page,
          limit: (data['limit'] as num?)?.toInt() ?? 25,
          search: search,
          status: status,
          priority: priority));
    } catch (e) {
      emit(AdminSupportError(adminErrorMessage(e,
          fallback: 'Support tickets could not be loaded.')));
    }
  }

  Future<bool> reply(String id, String message, {bool internal = false}) async {
    final previous =
        state is AdminSupportLoaded ? state as AdminSupportLoaded : null;
    try {
      await apiClient.replyToSupportTicket(id, message, internalNote: internal);
      await fetch(
          search: previous?.search ?? '',
          status: previous?.status ?? 'ALL',
          priority: previous?.priority ?? 'ALL',
          page: previous?.page ?? 1);
      return true;
    } catch (e) {
      emit(AdminSupportError(adminErrorMessage(e,
          fallback: 'Your support reply could not be sent.')));
      return false;
    }
  }

  Future<void> setStatus(String id, String value) async {
    final previous =
        state is AdminSupportLoaded ? state as AdminSupportLoaded : null;
    try {
      await apiClient.updateSupportTicketStatus(id, value);
      await fetch(
          search: previous?.search ?? '',
          status: previous?.status ?? 'ALL',
          priority: previous?.priority ?? 'ALL',
          page: previous?.page ?? 1);
    } catch (e) {
      emit(AdminSupportError(adminErrorMessage(e,
          fallback: 'The support ticket could not be updated.')));
    }
  }
}

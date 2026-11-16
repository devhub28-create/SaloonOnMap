import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/admin_error_message.dart';

sealed class AdminNotificationsState {}

class AdminNotificationsInitial extends AdminNotificationsState {}

class AdminNotificationsLoading extends AdminNotificationsState {}

class AdminNotificationsError extends AdminNotificationsState {
  final String message;
  AdminNotificationsError(this.message);
}

class AdminNotificationsLoaded extends AdminNotificationsState {
  final List<Map<String, dynamic>> campaigns;
  final Map<String, dynamic>? lastResult;
  AdminNotificationsLoaded(this.campaigns, {this.lastResult});
}

class AdminNotificationsCubit extends Cubit<AdminNotificationsState> {
  final ApiClient apiClient;
  AdminNotificationsCubit({required this.apiClient})
      : super(AdminNotificationsInitial());

  Future<void> fetchCampaigns({Map<String, dynamic>? lastResult}) async {
    emit(AdminNotificationsLoading());
    try {
      final response = await apiClient.getAdminNotificationCampaigns();
      emit(AdminNotificationsLoaded(
          response
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList(),
          lastResult: lastResult));
    } catch (error) {
      emit(AdminNotificationsError(adminErrorMessage(error,
          fallback: 'Notification campaigns could not be loaded.')));
    }
  }

  Future<bool> send(Map<String, dynamic> data) async {
    emit(AdminNotificationsLoading());
    try {
      final result = await apiClient.sendAdminNotificationCampaign(data);
      await fetchCampaigns(lastResult: result);
      return true;
    } catch (error) {
      emit(AdminNotificationsError(adminErrorMessage(error,
          fallback: 'The notification campaign could not be sent.')));
      return false;
    }
  }
}

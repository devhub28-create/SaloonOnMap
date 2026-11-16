import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';

abstract class PartnerDashboardState {}

class PartnerDashboardInitialState extends PartnerDashboardState {}

class PartnerDashboardLoadingState extends PartnerDashboardState {}

class PartnerDashboardLoadedState extends PartnerDashboardState {
  final Map<String, dynamic> data;
  PartnerDashboardLoadedState(this.data);
}

class PartnerDashboardErrorState extends PartnerDashboardState {
  final String message;
  PartnerDashboardErrorState(this.message);
}

class PartnerDashboardCubit extends Cubit<PartnerDashboardState> {
  final ApiClient apiClient;

  PartnerDashboardCubit({required this.apiClient})
      : super(PartnerDashboardInitialState());

  Future<void> fetchDashboard({String? salonId}) async {
    emit(PartnerDashboardLoadingState());
    try {
      final data = Map<String, dynamic>.from(
          await apiClient.getPartnerDashboard(salonId: salonId));
      try {
        data['unreadNotifications'] =
            await apiClient.getUnreadNotificationCount();
      } catch (_) {
        data['unreadNotifications'] = 0;
      }
      emit(PartnerDashboardLoadedState(data));
    } catch (e) {
      emit(PartnerDashboardErrorState(
          'Failed to load partner dashboard: ${e.toString()}'));
    }
  }
}

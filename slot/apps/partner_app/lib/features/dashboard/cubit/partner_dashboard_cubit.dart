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

  PartnerDashboardCubit({required this.apiClient}) : super(PartnerDashboardInitialState());

  Future<void> fetchDashboard({String? salonId}) async {
    emit(PartnerDashboardLoadingState());
    try {
      final data = await apiClient.getPartnerDashboard(salonId: salonId);
      emit(PartnerDashboardLoadedState(data));
    } catch (e) {
      emit(PartnerDashboardErrorState('Failed to load partner dashboard: ${e.toString()}'));
    }
  }
}

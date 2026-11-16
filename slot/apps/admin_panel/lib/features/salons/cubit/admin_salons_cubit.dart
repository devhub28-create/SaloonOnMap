import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';

abstract class AdminSalonsState {}

class AdminSalonsInitialState extends AdminSalonsState {}

class AdminSalonsLoadingState extends AdminSalonsState {}

class AdminSalonsLoadedState extends AdminSalonsState {
  final List<dynamic> pendingSalons;
  AdminSalonsLoadedState(this.pendingSalons);
}

class AdminSalonsErrorState extends AdminSalonsState {
  final String message;
  AdminSalonsErrorState(this.message);
}

class AdminSalonsCubit extends Cubit<AdminSalonsState> {
  final ApiClient apiClient;

  AdminSalonsCubit({required this.apiClient})
      : super(AdminSalonsInitialState());

  Future<void> fetchPendingSalons() async {
    emit(AdminSalonsLoadingState());
    try {
      final list = await apiClient.getPendingSalons();
      emit(AdminSalonsLoadedState(list));
    } catch (e) {
      emit(AdminSalonsErrorState(
          'Failed to fetch pending salons: ${e.toString()}'));
    }
  }

  Future<void> reviewSalon(String salonId, String action,
      {String? reason}) async {
    emit(AdminSalonsLoadingState());
    try {
      await apiClient.reviewSalon(salonId, action, reason: reason);
      fetchPendingSalons();
    } catch (e) {
      emit(AdminSalonsErrorState('Failed to review salon: ${e.toString()}'));
    }
  }
}

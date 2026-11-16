import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';
import '../../../core/utils/admin_error_message.dart';

abstract class AdminDashboardState {}

class AdminDashboardInitialState extends AdminDashboardState {}

class AdminDashboardLoadingState extends AdminDashboardState {}

class AdminDashboardLoadedState extends AdminDashboardState {
  final Map<String, dynamic> overview;
  AdminDashboardLoadedState(this.overview);
}

class AdminDashboardErrorState extends AdminDashboardState {
  final String message;
  AdminDashboardErrorState(this.message);
}

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final ApiClient apiClient;

  AdminDashboardCubit({required this.apiClient})
      : super(AdminDashboardInitialState());

  Future<void> fetchDashboard() async {
    emit(AdminDashboardLoadingState());
    try {
      final res = await apiClient.getAdminDashboard();
      emit(AdminDashboardLoadedState(res['overview'] ?? {}));
    } catch (e) {
      emit(AdminDashboardErrorState(adminErrorMessage(e,
          fallback: 'The platform overview could not be loaded.')));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';
import '../../../core/utils/admin_error_message.dart';

abstract class AdminSalonsState {}

class AdminSalonsInitialState extends AdminSalonsState {}

class AdminSalonsLoadingState extends AdminSalonsState {}

class AdminSalonsLoadedState extends AdminSalonsState {
  final List<Map<String, dynamic>> salons;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String status;

  AdminSalonsLoadedState({
    required this.salons,
    required this.total,
    required this.page,
    required this.limit,
    required this.search,
    required this.status,
  });
}

class AdminSalonsErrorState extends AdminSalonsState {
  final String message;
  AdminSalonsErrorState(this.message);
}

class AdminSalonsCubit extends Cubit<AdminSalonsState> {
  final ApiClient apiClient;

  AdminSalonsCubit({required this.apiClient})
      : super(AdminSalonsInitialState());

  Future<void> fetchSalons({
    String search = '',
    String status = 'ALL',
    int page = 1,
    int limit = 25,
  }) async {
    emit(AdminSalonsLoadingState());
    try {
      final result = await apiClient.getAdminSalons(
        search: search,
        status: status,
        page: page,
        limit: limit,
      );
      final items = (result['items'] as List? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      emit(AdminSalonsLoadedState(
        salons: items,
        total: (result['total'] as num?)?.toInt() ?? items.length,
        page: (result['page'] as num?)?.toInt() ?? page,
        limit: (result['limit'] as num?)?.toInt() ?? limit,
        search: search,
        status: status,
      ));
    } catch (e) {
      emit(AdminSalonsErrorState(
          adminErrorMessage(e, fallback: 'Salons could not be loaded.')));
    }
  }

  Future<bool> reviewSalon(String salonId, String action,
      {String? reason}) async {
    final previous = state is AdminSalonsLoadedState
        ? state as AdminSalonsLoadedState
        : null;
    emit(AdminSalonsLoadingState());
    try {
      await apiClient.reviewSalon(salonId, action, reason: reason);
      await fetchSalons(
        search: previous?.search ?? '',
        status: previous?.status ?? 'ALL',
        page: previous?.page ?? 1,
        limit: previous?.limit ?? 25,
      );
      return true;
    } catch (e) {
      emit(AdminSalonsErrorState(adminErrorMessage(e,
          fallback: 'The salon review could not be saved.')));
      return false;
    }
  }
}

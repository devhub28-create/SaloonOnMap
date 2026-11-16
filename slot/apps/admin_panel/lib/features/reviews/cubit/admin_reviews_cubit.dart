import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/admin_error_message.dart';

sealed class AdminReviewsState {}

class AdminReviewsInitial extends AdminReviewsState {}

class AdminReviewsLoading extends AdminReviewsState {}

class AdminReviewsError extends AdminReviewsState {
  final String message;
  AdminReviewsError(this.message);
}

class AdminReviewsLoaded extends AdminReviewsState {
  final List<Map<String, dynamic>> reviews;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String status;
  AdminReviewsLoaded(
      {required this.reviews,
      required this.total,
      required this.page,
      required this.limit,
      required this.search,
      required this.status});
}

class AdminReviewsCubit extends Cubit<AdminReviewsState> {
  final ApiClient apiClient;
  AdminReviewsCubit({required this.apiClient}) : super(AdminReviewsInitial());

  Future<void> fetchReviews(
      {String search = '', String status = 'ALL', int page = 1}) async {
    emit(AdminReviewsLoading());
    try {
      final response = await apiClient.getAdminReviews(
          search: search, status: status, page: page);
      final items = (response['items'] as List<dynamic>? ?? const [])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
      emit(AdminReviewsLoaded(
          reviews: items,
          total: (response['total'] as num?)?.toInt() ?? items.length,
          page: (response['page'] as num?)?.toInt() ?? page,
          limit: (response['limit'] as num?)?.toInt() ?? 25,
          search: search,
          status: status));
    } catch (error) {
      emit(AdminReviewsError(
          adminErrorMessage(error, fallback: 'Reviews could not be loaded.')));
    }
  }

  Future<void> moderate(String id, String status, {String? reason}) async {
    final previous =
        state is AdminReviewsLoaded ? state as AdminReviewsLoaded : null;
    try {
      await apiClient.moderateAdminReview(id, status, reason: reason);
      await fetchReviews(
          search: previous?.search ?? '',
          status: previous?.status ?? 'ALL',
          page: previous?.page ?? 1);
    } catch (error) {
      emit(AdminReviewsError(adminErrorMessage(error,
          fallback: 'The review moderation change could not be saved.')));
    }
  }
}

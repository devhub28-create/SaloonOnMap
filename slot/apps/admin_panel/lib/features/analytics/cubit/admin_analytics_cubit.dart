import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/admin_error_message.dart';

sealed class AdminAnalyticsState {}

class AdminAnalyticsInitial extends AdminAnalyticsState {}

class AdminAnalyticsLoading extends AdminAnalyticsState {}

class AdminAnalyticsError extends AdminAnalyticsState {
  final String message;
  AdminAnalyticsError(this.message);
}

class AdminAnalyticsLoaded extends AdminAnalyticsState {
  final Map<String, dynamic> data;
  AdminAnalyticsLoaded(this.data);
}

class AdminAnalyticsCubit extends Cubit<AdminAnalyticsState> {
  final ApiClient apiClient;
  AdminAnalyticsCubit({required this.apiClient})
      : super(AdminAnalyticsInitial());
  Future<void> fetchAnalytics({int days = 30}) async {
    emit(AdminAnalyticsLoading());
    try {
      emit(AdminAnalyticsLoaded(await apiClient.getAdminAnalytics(days: days)));
    } catch (error) {
      emit(AdminAnalyticsError(adminErrorMessage(
        error,
        fallback: 'Analytics could not be loaded. Please try again.',
      )));
    }
  }
}

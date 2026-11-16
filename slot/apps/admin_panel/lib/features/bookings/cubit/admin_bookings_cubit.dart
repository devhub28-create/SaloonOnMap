import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/admin_error_message.dart';

abstract class AdminBookingsState {}

class AdminBookingsInitial extends AdminBookingsState {}

class AdminBookingsLoading extends AdminBookingsState {}

class AdminBookingsLoaded extends AdminBookingsState {
  final List<Map<String, dynamic>> bookings;
  final int total;
  final int page;
  final int limit;
  final String search;
  final String status;

  AdminBookingsLoaded({
    required this.bookings,
    required this.total,
    required this.page,
    required this.limit,
    required this.search,
    required this.status,
  });
}

class AdminBookingsError extends AdminBookingsState {
  final String message;
  AdminBookingsError(this.message);
}

class AdminBookingsCubit extends Cubit<AdminBookingsState> {
  final ApiClient apiClient;
  AdminBookingsCubit({required this.apiClient}) : super(AdminBookingsInitial());

  Future<void> fetchBookings({
    String search = '',
    String status = 'ALL',
    int page = 1,
  }) async {
    emit(AdminBookingsLoading());
    try {
      final response = await apiClient.getAdminBookings(
        search: search,
        status: status,
        page: page,
      );
      final rawItems = response['items'] as List<dynamic>? ?? const [];
      final bookings = rawItems
          .map((booking) => Map<String, dynamic>.from(booking as Map))
          .toList();
      emit(AdminBookingsLoaded(
        bookings: bookings,
        total: (response['total'] as num?)?.toInt() ?? bookings.length,
        page: (response['page'] as num?)?.toInt() ?? page,
        limit: (response['limit'] as num?)?.toInt() ?? 25,
        search: search,
        status: status,
      ));
    } catch (error) {
      emit(AdminBookingsError(
          adminErrorMessage(error, fallback: 'Bookings could not be loaded.')));
    }
  }

  Future<bool> updateStatus(
    String bookingId,
    String status,
    String reason,
  ) async {
    final previous =
        state is AdminBookingsLoaded ? state as AdminBookingsLoaded : null;
    try {
      await apiClient.updateAdminBookingStatus(bookingId, status, reason);
      await fetchBookings(
        search: previous?.search ?? '',
        status: previous?.status ?? 'ALL',
        page: previous?.page ?? 1,
      );
      return true;
    } catch (error) {
      emit(AdminBookingsError(adminErrorMessage(error,
          fallback: 'The booking could not be updated.')));
      return false;
    }
  }
}

import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AdminBookingsState {}

class AdminBookingsInitial extends AdminBookingsState {}

class AdminBookingsLoading extends AdminBookingsState {}

class AdminBookingsLoaded extends AdminBookingsState {
  final List<Map<String, dynamic>> bookings;
  AdminBookingsLoaded(this.bookings);
}

class AdminBookingsError extends AdminBookingsState {
  final String message;
  AdminBookingsError(this.message);
}

class AdminBookingsCubit extends Cubit<AdminBookingsState> {
  final ApiClient apiClient;
  AdminBookingsCubit({required this.apiClient}) : super(AdminBookingsInitial());

  Future<void> fetchBookings() async {
    emit(AdminBookingsLoading());
    try {
      final bookings = await apiClient.getAdminBookings();
      emit(AdminBookingsLoaded(bookings
          .map((booking) => Map<String, dynamic>.from(booking as Map))
          .toList()));
    } catch (error) {
      emit(AdminBookingsError('Failed to load bookings: $error'));
    }
  }
}

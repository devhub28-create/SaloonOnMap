import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';

abstract class PartnerBookingsState {}

class PartnerBookingsInitialState extends PartnerBookingsState {}

class PartnerBookingsLoadingState extends PartnerBookingsState {}

class PartnerBookingsLoadedState extends PartnerBookingsState {
  final List<dynamic> bookings;
  PartnerBookingsLoadedState(this.bookings);
}

class PartnerBookingsErrorState extends PartnerBookingsState {
  final String message;
  final bool isConflict;
  PartnerBookingsErrorState(this.message, {this.isConflict = false});
}

class PartnerWalkInSuccessState extends PartnerBookingsState {
  final Map<String, dynamic> booking;
  PartnerWalkInSuccessState(this.booking);
}

class PartnerBookingsCubit extends Cubit<PartnerBookingsState> {
  final ApiClient apiClient;

  PartnerBookingsCubit({required this.apiClient})
      : super(PartnerBookingsInitialState());

  Future<void> fetchBookings({
    String? salonId,
    String? status,
    bool silent = false,
  }) async {
    if (!silent) emit(PartnerBookingsLoadingState());
    try {
      final list = await apiClient.getPartnerBookings(
        salonId: salonId,
        status: status,
      );
      emit(PartnerBookingsLoadedState(list));
    } catch (e) {
      emit(
        PartnerBookingsErrorState(
          'Could not refresh bookings. Check your connection and try again.',
        ),
      );
    }
  }

  Future<void> addWalkIn({
    required String customerName,
    String? customerPhone,
    String? seatId,
    required String salonId,
    required List<String> serviceIds,
    required double totalPrice,
    required int totalDuration,
    String? notes,
  }) async {
    emit(PartnerBookingsLoadingState());
    try {
      final payload = <String, dynamic>{
        'customerName': customerName,
        'salonId': salonId,
        'serviceIds': serviceIds,
        'totalPrice': totalPrice,
        'totalDuration': totalDuration,
      };
      if (customerPhone != null && customerPhone.trim().isNotEmpty) {
        payload['customerPhone'] = customerPhone.trim();
      }
      if (seatId != null && seatId.trim().isNotEmpty) {
        payload['seatId'] = seatId.trim();
      }
      if (notes != null && notes.trim().isNotEmpty) {
        payload['notes'] = notes.trim();
      }

      final result = await apiClient.addWalkIn(payload);
      emit(PartnerWalkInSuccessState(result));
      await fetchBookings(salonId: salonId);
    } catch (e) {
      emit(
        PartnerBookingsErrorState(
          'Failed to create walk-in booking: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> updateBookingStatus({
    required String bookingId,
    required String targetStatus,
    String? reason,
    String? salonId,
  }) async {
    try {
      await apiClient.updateBookingStatus(
        bookingId: bookingId,
        status: targetStatus,
        reason: reason,
      );
      await fetchBookings(salonId: salonId);
    } catch (e) {
      emit(
        PartnerBookingsErrorState(
          'Failed to update booking status: ${e.toString()}',
        ),
      );
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:api_client/api_client.dart';

abstract class BookingState {}

class BookingInitialState extends BookingState {}

class BookingLoadingState extends BookingState {}

class BookingHoldCreatedState extends BookingState {
  final Map<String, dynamic> holdData;
  BookingHoldCreatedState(this.holdData);
}

class BookingConfirmedSuccessState extends BookingState {
  final Map<String, dynamic> bookingData;
  BookingConfirmedSuccessState(this.bookingData);
}

class BookingErrorState extends BookingState {
  final String message;
  final String? code;
  BookingErrorState(this.message, {this.code});
}

class BookingCubit extends Cubit<BookingState> {
  final ApiClient apiClient;

  // Selected Booking Parameters
  List<Map<String, dynamic>> selectedServices = [];
  String? selectedSalonId;
  String selectedSalonName = '';
  String selectedDate = DateTime.now().toString().substring(0, 10);
  String selectedTime = '';
  String? selectedSeatId;
  String selectedSeatLabel = '';
  String selectedStylist = 'Any Stylist';
  Map<String, dynamic>? activeHoldData;
  String? _idempotencyKey;

  BookingCubit({required this.apiClient}) : super(BookingInitialState());

  void selectSalon(
    String salonId,
    String salonName,
    List<Map<String, dynamic>> services,
  ) {
    selectedSalonId = salonId;
    selectedSalonName = salonName;
    selectedServices = services;
    selectedSeatId = null;
    selectedSeatLabel = '';
    activeHoldData = null;
    _idempotencyKey = null;
    emit(BookingInitialState());
  }

  void toggleService(Map<String, dynamic> service) {
    final index = selectedServices.indexWhere((s) => s['id'] == service['id']);
    if (index >= 0) {
      selectedServices.removeAt(index);
    } else {
      selectedServices.add(service);
    }
    emit(BookingInitialState());
  }

  void selectDateTimeSeat({
    required String date,
    required String time,
    required String seatId,
    required String seatLabel,
    required String stylist,
  }) {
    selectedDate = date;
    selectedTime = time;
    selectedSeatId = seatId;
    selectedSeatLabel = seatLabel;
    selectedStylist = stylist;
    emit(BookingInitialState());
  }

  double get totalPrice {
    return selectedServices.fold(
      0.0,
      (sum, item) => sum + (double.tryParse(item['price'].toString()) ?? 0.0),
    );
  }

  int get totalDuration {
    return selectedServices.fold(
      0,
      (sum, item) =>
          sum + (int.tryParse(item['duration_minutes'].toString()) ?? 0),
    );
  }

  Future<void> createHold(String salonId, String customerId) async {
    if (selectedSeatId == null ||
        selectedTime.isEmpty ||
        selectedServices.isEmpty) {
      emit(
        BookingErrorState(
          'Select at least one service, time, and available seat.',
        ),
      );
      return;
    }
    emit(BookingLoadingState());
    try {
      final startAt = _selectedStartAt();
      final response = await apiClient.createHold({
        'customerId': customerId,
        'salonId': salonId,
        'seatId': selectedSeatId,
        'startAt': startAt.toUtc().toIso8601String(),
        'endAt': startAt
            .add(Duration(minutes: totalDuration))
            .toUtc()
            .toIso8601String(),
        'serviceIds': selectedServices.map((s) => s['id']).toList(),
        'totalPrice': totalPrice,
        'totalDuration': totalDuration,
      });
      activeHoldData = response;
      _idempotencyKey ??=
          'booking-${response['holdId']}-${DateTime.now().microsecondsSinceEpoch}';
      emit(BookingHoldCreatedState(response));
    } catch (e) {
      final msg = e is DioException && e.response?.statusCode == 409
          ? 'Selected seat is already booked or held. Please go back and select another seat or time slot.'
          : _friendlyError(e, 'Could not reserve this slot. Please try again.');
      emit(BookingErrorState(msg));
    }
  }

  Future<void> confirmBooking(
    String customerId, {
    String? idempotencyKey,
  }) async {
    if (activeHoldData == null && selectedSalonId != null) {
      await createHold(selectedSalonId!, customerId);
    }
    final holdId = activeHoldData?['holdId']?.toString();
    if (holdId == null || holdId.isEmpty) {
      emit(
        BookingErrorState(
          'Your seat hold is not active. Return and select the slot again.',
        ),
      );
      return;
    }
    emit(BookingLoadingState());
    try {
      final response = await apiClient.confirmBooking({
        'holdId': holdId,
        'customerId': customerId,
        'serviceIds': selectedServices.map((service) => service['id']).toList(),
        'notes': 'Pay at salon',
      }, idempotencyKey: idempotencyKey ?? _idempotencyKey);
      activeHoldData = null;
      _idempotencyKey = null;
      emit(BookingConfirmedSuccessState(response));
    } catch (e) {
      final status = e is DioException ? e.response?.statusCode : null;
      final msg = status == 400 || status == 404 || status == 409
          ? 'This hold expired or the slot is no longer available. Select the slot again.'
          : _friendlyError(
              e,
              'Could not confirm the booking. Please try again.',
            );
      emit(BookingErrorState(msg, code: 'BOOKING_ERROR'));
    }
  }

  DateTime? get holdExpiresAt {
    final value = activeHoldData?['expiresAt'] ?? activeHoldData?['expires_at'];
    return value == null
        ? null
        : DateTime.tryParse(value.toString())?.toLocal();
  }

  String _friendlyError(Object error, String fallback) {
    if (error is! DioException) return fallback;
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      final message = data['message'];
      if (message is List) return message.join(' ');
      if (message.toString().trim().isNotEmpty) return message.toString();
    }
    return fallback;
  }

  DateTime _selectedStartAt() {
    final date = DateTime.parse(selectedDate);
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(selectedTime.trim());
    if (match == null) {
      throw FormatException('Invalid booking time: $selectedTime');
    }
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

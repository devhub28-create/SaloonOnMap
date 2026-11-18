import 'package:api_client/api_client.dart';
import 'package:customer_app/features/booking/cubit/booking_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBookingApi extends ApiClient {
  final List<String?> idempotencyKeys = [];
  int attempts = 0;

  @override
  Future<Map<String, dynamic>> createHold(Map<String, dynamic> data) async => {
        'holdId': 'hold-1',
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 5))
            .toUtc()
            .toIso8601String(),
      };

  @override
  Future<Map<String, dynamic>> confirmBooking(
    Map<String, dynamic> data, {
    String? idempotencyKey,
  }) async {
    idempotencyKeys.add(idempotencyKey);
    attempts += 1;
    if (attempts == 1) {
      throw DioException(
        requestOptions: RequestOptions(path: '/bookings'),
        type: DioExceptionType.connectionError,
      );
    }
    return {'id': 'booking-1'};
  }
}

void main() {
  group('BookingCubit', () {
    test('uses one idempotency key across a network retry', () async {
      final api = _FakeBookingApi();
      final cubit = BookingCubit(apiClient: api)
        ..selectSalon('salon-1', 'Salon', [
          {'id': 'service-1', 'price': 500, 'duration_minutes': 30},
        ])
        ..selectDateTimeSeat(
          date: DateTime.now()
              .add(const Duration(days: 1))
              .toString()
              .substring(0, 10),
          time: '10:00 AM',
          seatId: 'seat-1',
          seatLabel: 'Seat 1',
          stylist: 'Any Stylist',
        );

      await cubit.createHold('salon-1', 'customer-1');
      await cubit.confirmBooking('customer-1');
      expect(cubit.state, isA<BookingErrorState>());

      await cubit.confirmBooking('customer-1');
      expect(cubit.state, isA<BookingConfirmedSuccessState>());
      expect(api.idempotencyKeys, hasLength(2));
      expect(api.idempotencyKeys.first, isNotNull);
      expect(api.idempotencyKeys.first, api.idempotencyKeys.last);
    });

    test('exposes the server hold expiry in local time', () async {
      final cubit = BookingCubit(apiClient: _FakeBookingApi())
        ..selectedServices = [
          {'id': 'service-1', 'price': 500, 'duration_minutes': 30},
        ]
        ..selectedSeatId = 'seat-1'
        ..selectedTime = '10:00 AM';

      await cubit.createHold('salon-1', 'customer-1');
      expect(cubit.holdExpiresAt, isNotNull);
      expect(cubit.holdExpiresAt!.isAfter(DateTime.now()), isTrue);
    });
  });
}

import 'dart:convert';
import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PartnerSeatsState {}

class PartnerSeatsInitialState extends PartnerSeatsState {}

class PartnerSeatsLoadedState extends PartnerSeatsState {
  final Map<int, String> seatStatuses;
  final Map<int, String> seatIds;
  final int totalSeats;

  PartnerSeatsLoadedState({
    required this.seatStatuses,
    this.seatIds = const {},
    required this.totalSeats,
  });

  int get availableCount =>
      seatStatuses.values.where((s) => s == 'Available').length;
  int get inServiceCount =>
      seatStatuses.values.where((s) => s == 'In service').length;
  int get bookedCount => seatStatuses.values.where((s) => s == 'Booked').length;
}

class PartnerSeatsCubit extends Cubit<PartnerSeatsState> {
  final ApiClient apiClient;

  PartnerSeatsCubit({required this.apiClient})
      : super(PartnerSeatsInitialState());

  static const String _keySeatMap = 'partner_seat_statuses_map';

  String _fromApiStatus(String status) {
    switch (status.toUpperCase()) {
      case 'IN_SERVICE':
        return 'In service';
      case 'BOOKED':
      case 'RESERVED':
        return 'Booked';
      default:
        return 'Available';
    }
  }

  String _toApiStatus(String status) {
    switch (status) {
      case 'In service':
        return 'IN_SERVICE';
      case 'Booked':
        return 'BOOKED';
      default:
        return 'AVAILABLE';
    }
  }

  Future<void> loadSeats(int totalSeats, {String? salonId}) async {
    if (salonId != null && salonId.isNotEmpty) {
      try {
        final seats = await apiClient.getPartnerSeats(salonId: salonId);
        if (seats.isNotEmpty) {
          final statuses = <int, String>{};
          final ids = <int, String>{};
          for (final seat in seats) {
            final seatNumber = (seat['seat_number'] as num?)?.toInt() ??
                (seat['seatNumber'] as num?)?.toInt();
            final id = seat['id']?.toString();
            if (seatNumber != null) {
              statuses[seatNumber] =
                  _fromApiStatus(seat['status']?.toString() ?? 'AVAILABLE');
              if (id != null && id.isNotEmpty) ids[seatNumber] = id;
            }
          }
          emit(PartnerSeatsLoadedState(
            seatStatuses: statuses,
            seatIds: ids,
            totalSeats: seats.length,
          ));
          return;
        }
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keySeatMap);
      final Map<int, String> map = {};

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = json.decode(jsonStr) as Map<String, dynamic>;
        decoded.forEach((k, v) {
          final seatNum = int.tryParse(k);
          if (seatNum != null) {
            map[seatNum] = v.toString();
          }
        });
      }

      for (int i = 1; i <= totalSeats; i++) {
        if (!map.containsKey(i)) {
          map[i] = 'Available';
        }
      }

      emit(PartnerSeatsLoadedState(seatStatuses: map, totalSeats: totalSeats));
    } catch (e) {
      final Map<int, String> defaultMap = {};
      for (int i = 1; i <= totalSeats; i++) {
        defaultMap[i] = 'Available';
      }
      emit(PartnerSeatsLoadedState(
          seatStatuses: defaultMap, totalSeats: totalSeats));
    }
  }

  Future<void> toggleSeatStatus(int seatNumber, {int totalSeats = 6}) async {
    final currentState = state;
    final Map<int, String> map = currentState is PartnerSeatsLoadedState
        ? Map<int, String>.from(currentState.seatStatuses)
        : {};
    final Map<int, String> ids = currentState is PartnerSeatsLoadedState
        ? Map<int, String>.from(currentState.seatIds)
        : {};

    final currentStatus = map[seatNumber] ?? 'Available';
    String nextStatus = 'Available';
    if (currentStatus == 'Available') {
      nextStatus = 'In service';
    } else if (currentStatus == 'In service') {
      nextStatus = 'Booked';
    } else {
      nextStatus = 'Available';
    }

    map[seatNumber] = nextStatus;
    emit(PartnerSeatsLoadedState(
        seatStatuses: map, seatIds: ids, totalSeats: totalSeats));

    try {
      final seatId = ids[seatNumber];
      if (seatId != null && seatId.isNotEmpty) {
        await apiClient.updatePartnerSeatStatus(
            seatId, _toApiStatus(nextStatus));
      }
      final prefs = await SharedPreferences.getInstance();
      final saveMap = map.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_keySeatMap, json.encode(saveMap));
    } catch (_) {}
  }
}

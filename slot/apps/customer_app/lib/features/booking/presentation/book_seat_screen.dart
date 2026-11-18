import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';

import '../cubit/booking_cubit.dart';

class BookSeatScreen extends StatefulWidget {
  const BookSeatScreen({super.key});

  @override
  State<BookSeatScreen> createState() => _BookSeatScreenState();
}

class _BookSeatScreenState extends State<BookSeatScreen> {
  int _selectedDateIndex = 0;
  String _selectedTime = '';
  String _selectedSeatLabel = '';
  String? _selectedSeatId;
  String _selectedStylist = 'No preference';

  bool _isLoading = true;
  List<Map<String, dynamic>> _seats = [];
  List<Map<String, dynamic>> _staffList = [];
  List<Map<String, dynamic>> _timeSlots = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() => _isLoading = true);
    try {
      final bookingCubit = context.read<BookingCubit>();
      final salonId = bookingCubit.selectedSalonId;
      if (salonId == null) {
        throw StateError('Select a salon before choosing a slot.');
      }
      final selectedDate = DateTime.now().add(
        Duration(days: _selectedDateIndex),
      );
      final date =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
      final res = await bookingCubit.apiClient.getAvailableSlots(
        salonId,
        date: date,
        duration: bookingCubit.totalDuration,
      );
      final fetchedSeats = List<Map<String, dynamic>>.from(res['seats'] ?? []);
      final fetchedStaff = List<Map<String, dynamic>>.from(res['staff'] ?? []);
      final fetchedTimes = List<Map<String, dynamic>>.from(
        res['timeSlots'] ?? [],
      );

      setState(() {
        _seats = fetchedSeats;
        _staffList = fetchedStaff;
        _timeSlots = fetchedTimes;

        if (fetchedStaff.isNotEmpty) {
          _selectedStylist =
              _staffList.first['name']?.toString() ?? 'No preference';
        } else {
          _selectedStylist = 'No preference';
        }

        if (fetchedTimes.isNotEmpty) {
          final availableTimes =
              fetchedTimes.where((slot) => slot['available'] == true).toList();
          _selectedTime = availableTimes.isNotEmpty
              ? availableTimes.first['time']?.toString() ?? ''
              : '';
        } else {
          _selectedTime = '';
        }

        final availSeatIds = _availableSeatIdsForSelectedTime;
        final initialSeat = _seats.firstWhere(
          (s) => availSeatIds.contains(s['id']?.toString()),
          orElse: () => _seats.isNotEmpty ? _seats.first : const {},
        );
        if (initialSeat.isNotEmpty &&
            availSeatIds.contains(initialSeat['id']?.toString())) {
          _selectedSeatId = initialSeat['id']?.toString();
          _selectedSeatLabel = initialSeat['label']?.toString() ?? '';
        } else {
          _selectedSeatId = null;
          _selectedSeatLabel = '';
        }

        _error = null;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  List<String> get _availableSeatIdsForSelectedTime {
    if (_timeSlots.isEmpty || _selectedTime.isEmpty) return [];
    final slot = _timeSlots.firstWhere(
      (s) => s['time']?.toString() == _selectedTime,
      orElse: () => const {},
    );
    final raw = slot['availableSeatIds'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  bool _isSeatAvailableForSelectedTime(String seatId) {
    if (_selectedTime.isEmpty) return true;
    return _availableSeatIdsForSelectedTime.contains(seatId);
  }

  bool _isTimeAvailableForSelectedSeat(Map<String, dynamic> timeSlot) {
    final slotAvailable = timeSlot['available'] == true;
    if (!slotAvailable) return false;
    if (_selectedSeatId == null) return true;
    final availableSeats = (timeSlot['availableSeatIds'] as List?)
            ?.map((e) => e.toString())
            .toSet() ??
        {};
    return availableSeats.contains(_selectedSeatId);
  }

  void _onTimeSelected(String time) {
    setState(() {
      _selectedTime = time;
      final availIds = _availableSeatIdsForSelectedTime;
      if (_selectedSeatId != null && !availIds.contains(_selectedSeatId)) {
        final nextAvail = _seats.firstWhere(
          (s) => availIds.contains(s['id']?.toString()),
          orElse: () => const {},
        );
        if (nextAvail.isNotEmpty) {
          _selectedSeatId = nextAvail['id']?.toString();
          _selectedSeatLabel = nextAvail['label']?.toString() ?? '';
        } else {
          _selectedSeatId = null;
          _selectedSeatLabel = '';
        }
      }
    });
  }

  void _onSeatSelected(String id, String label) {
    if (!_isSeatAvailableForSelectedTime(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$label is occupied at $_selectedTime. Please pick another chair or time slot.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _selectedSeatId = id;
      _selectedSeatLabel = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingCubit = context.watch<BookingCubit>();
    final totalPrice = bookingCubit.totalPrice;

    final now = DateTime.now();
    final dates = List.generate(4, (i) => now.add(Duration(days: i)));
    final selectedDateObj =
        dates[_selectedDateIndex < dates.length ? _selectedDateIndex : 0];
    final selectedDateStr =
        '${selectedDateObj.year}-${selectedDateObj.month.toString().padLeft(2, '0')}-${selectedDateObj.day.toString().padLeft(2, '0')}';

    final weekdays = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Book your chair', style: AppTypography.screenTitle),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Choose Date Header
                      const Text(
                        'Choose date',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Date horizontal list
                      Row(
                        children: List.generate(dates.length, (index) {
                          final d = dates[index];
                          final dayName = weekdays[d.weekday % 7];
                          final dateNum = d.day.toString().padLeft(2, '0');
                          return _datePill(index, dayName, dateNum);
                        }),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Available Times Header
                      const Text(
                        'Available times',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Time Slots Grid
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            _timeSlots.map((ts) => _timePill(ts)).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Choose a Seat Header
                      const Text(
                        'Choose a seat',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Seat Selector
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _seats.map((seat) {
                          final sId = seat['id']?.toString() ?? '';
                          final sLabel = seat['label']?.toString() ?? 'Seat';
                          return _seatPill(sId, sLabel);
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Preferred Stylist
                      const Text(
                        'Preferred stylist',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      Row(
                        children: [
                          ..._staffList.map((st) {
                            final name = st['name']?.toString() ?? 'Staff';
                            final avatar =
                                name.isNotEmpty ? name[0].toUpperCase() : 'S';
                            return _stylistPill(name, avatar);
                          }),
                          _stylistPill('No preference', '•'),
                        ],
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: SlotPrimaryButton(
          text: 'Review · ₹${totalPrice.toInt()} →',
          onPressed: () {
            if (_selectedSeatId == null || _selectedTime.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No available seat or time is selected.'),
                ),
              );
              return;
            }
            bookingCubit.selectDateTimeSeat(
              date: selectedDateStr,
              time: _selectedTime,
              seatId: _selectedSeatId!,
              seatLabel: _selectedSeatLabel,
              stylist: _selectedStylist,
            );
            context.push('/review-booking');
          },
        ),
      ),
    );
  }

  Widget _datePill(int index, String day, String dateNum) {
    final isSelected = index == _selectedDateIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedDateIndex = index);
          _fetchSlots();
        },
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.darkNeutral : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.darkNeutral : AppColors.borderLight,
            ),
          ),
          child: Column(
            children: [
              Text(
                day,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white70 : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateNum,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.darkNeutral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timePill(Map<String, dynamic> ts) {
    final time = ts['time']?.toString() ?? '';
    final isSelected = time == _selectedTime;
    final generalAvailable = ts['available'] == true;
    final seatAvailable = _isTimeAvailableForSelectedSeat(ts);
    final isAvailable = generalAvailable && seatAvailable;

    String? displayLabel = ts['label']?.toString();
    if (generalAvailable && !seatAvailable && _selectedSeatLabel.isNotEmpty) {
      displayLabel = 'Occupied';
    }

    return GestureDetector(
      onTap: () {
        if (!generalAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$time is completely booked. Please select another slot.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        if (!seatAvailable) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$_selectedSeatLabel is occupied at $time. Select another chair or slot.',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
        _onTimeSelected(time);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: !isAvailable
              ? const Color(0xFFF3F4F6)
              : isSelected
                  ? AppColors.darkNeutral
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.darkNeutral : AppColors.borderLight,
          ),
        ),
        child: Column(
          children: [
            Text(
              time,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: !isAvailable
                    ? AppColors.textMuted
                    : isSelected
                        ? Colors.white
                        : AppColors.darkNeutral,
              ),
            ),
            if (displayLabel != null)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white24 : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFFDC2626),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _seatPill(String id, String label) {
    final isSelected = id == _selectedSeatId;
    final isAvailable = _isSeatAvailableForSelectedTime(id);

    return GestureDetector(
      onTap: () => _onSeatSelected(id, label),
      child: Container(
        width: 105,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: !isAvailable
              ? const Color(0xFFF3F4F6)
              : isSelected
                  ? const Color(0xFFFEF9C3)
                  : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: !isAvailable
                ? AppColors.borderLight
                : isSelected
                    ? AppColors.primaryGoldDark
                    : AppColors.borderLight,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.chair_alt_rounded,
              size: 22,
              color: !isAvailable
                  ? AppColors.textMuted
                  : isSelected
                      ? AppColors.primaryGoldDark
                      : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: !isAvailable
                    ? AppColors.textMuted
                    : isSelected
                        ? AppColors.darkNeutral
                        : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: !isAvailable
                    ? const Color(0xFFFEE2E2)
                    : isSelected
                        ? const Color(0xFFFEF08A)
                        : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                !isAvailable
                    ? 'Occupied'
                    : isSelected
                        ? 'Selected'
                        : 'Available',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: !isAvailable
                      ? const Color(0xFFDC2626)
                      : isSelected
                          ? AppColors.darkNeutral
                          : const Color(0xFF166534),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stylistPill(String name, String avatar) {
    final isSelected = name == _selectedStylist;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedStylist = name),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFEF9C3) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryGoldDark
                  : AppColors.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isSelected
                    ? AppColors.primaryGold
                    : const Color(0xFFEFECE6),
                child: Text(
                  avatar,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNeutral,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color:
                      isSelected ? AppColors.darkNeutral : AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

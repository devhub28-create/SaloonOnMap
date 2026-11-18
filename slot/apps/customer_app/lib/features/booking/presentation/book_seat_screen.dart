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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'STEP 2 OF 3',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 2),
            Text('Choose your appointment', style: AppTypography.screenTitle),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event_busy_outlined,
                          size: 42,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'We could not load availability',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _fetchSlots,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.darkNeutral, Color(0xFF34333A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x1FFFFFFF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.event_seat_rounded,
                                color: AppColors.primaryGold,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bookingCubit.selectedSalonName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${bookingCubit.selectedServices.length} ${bookingCubit.selectedServices.length == 1 ? 'service' : 'services'} · ${formatDuration(bookingCubit.totalDuration)}',
                                    style: const TextStyle(
                                      color: Color(0xFFD1D5DB),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _sectionHeader(
                        icon: Icons.calendar_month_rounded,
                        title: 'Pick a day',
                        subtitle: 'Availability updates as you choose.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: List.generate(dates.length, (index) {
                          final d = dates[index];
                          final dayName =
                              index == 0 ? 'TODAY' : weekdays[d.weekday % 7];
                          final dateNum = d.day.toString().padLeft(2, '0');
                          return _datePill(index, dayName, dateNum);
                        }),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _sectionHeader(
                        icon: Icons.schedule_rounded,
                        title: 'Choose a time',
                        subtitle: _selectedTime.isEmpty
                            ? 'Select an available slot.'
                            : '$_selectedTime is selected.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children:
                            _timeSlots.map((ts) => _timePill(ts)).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _sectionHeader(
                        icon: Icons.chair_alt_rounded,
                        title: 'Choose your chair',
                        subtitle: _selectedSeatLabel.isEmpty
                            ? 'Pick an available chair for your time.'
                            : '$_selectedSeatLabel is reserved for your selected time.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _seats.map((seat) {
                          final sId = seat['id']?.toString() ?? '';
                          final sLabel = seat['label']?.toString() ?? 'Seat';
                          return _seatPill(sId, sLabel);
                        }).toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _sectionHeader(
                        icon: Icons.person_pin_rounded,
                        title: 'Stylist preference',
                        subtitle:
                            'Choose a stylist or let the salon assign one.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        height: 96,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
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
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5D9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      size: 18,
                      color: AppColors.primaryGoldDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedTime.isEmpty || _selectedSeatLabel.isEmpty
                          ? 'Select a time and chair to continue'
                          : '$_selectedTime · $_selectedSeatLabel · $_selectedStylist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '₹${totalPrice.toInt()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkNeutral,
                    ),
                  ),
                ],
              ),
            ),
            SlotPrimaryButton(
              text: 'Review appointment',
              onPressed: () {
                if (_selectedSeatId == null || _selectedTime.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No available chair or time is selected.'),
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
          ],
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

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5D9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryGoldDark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkNeutral,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      );

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
    return SizedBox(
      width: 112,
      child: GestureDetector(
        onTap: () => setState(() => _selectedStylist = name),
        child: Container(
          margin: const EdgeInsets.only(right: 10),
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

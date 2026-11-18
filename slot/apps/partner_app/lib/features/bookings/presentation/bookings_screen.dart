import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';

import '../../auth/cubit/partner_auth_cubit.dart';
import '../../seats/cubit/partner_seats_cubit.dart';
import '../../services/cubit/partner_services_cubit.dart';
import '../../services/presentation/services_screen.dart';
import '../cubit/partner_bookings_cubit.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  int _selectedFilter = 0; // 0: All, 1: Waiting, 2: In service, 3: Completed
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadBookings(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadAllData() {
    final authState = context.read<PartnerAuthCubit>().state;
    final salonId =
        authState is PartnerAuthenticated ? authState.salonId : null;
    context.read<PartnerBookingsCubit>().fetchBookings(salonId: salonId);
    context.read<PartnerServicesCubit>().loadServices(salonId: salonId);
    if (salonId != null && salonId.isNotEmpty) {
      context.read<PartnerSeatsCubit>().loadSeats(6, salonId: salonId);
    }
  }

  void _loadBookings({bool silent = false}) {
    final authState = context.read<PartnerAuthCubit>().state;
    final salonId =
        authState is PartnerAuthenticated ? authState.salonId : null;
    context
        .read<PartnerBookingsCubit>()
        .fetchBookings(salonId: salonId, silent: silent);
  }

  void _updateStatus(Map<String, dynamic> booking, String targetStatus) async {
    final bookingId = (booking['id'] ??
            booking['referenceCode'] ??
            booking['reference_code'] ??
            '')
        .toString();
    if (bookingId.isEmpty) return;
    final authState = context.read<PartnerAuthCubit>().state;
    final salonId =
        authState is PartnerAuthenticated ? authState.salonId : null;
    await context.read<PartnerBookingsCubit>().updateBookingStatus(
          bookingId: bookingId,
          targetStatus: targetStatus,
          salonId: salonId,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            targetStatus == 'DONE'
                ? '✅ Service marked as Completed!'
                : '⚡ Service started! Seat is now In-Service.',
          ),
          backgroundColor: AppColors.darkNeutral,
        ),
      );
    }
  }

  void _showWalkInModal(BuildContext context) {
    final authState = context.read<PartnerAuthCubit>().state;
    final salonId = authState is PartnerAuthenticated ? authState.salonId : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) => _WalkInModalContent(salonId: salonId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: BlocBuilder<PartnerBookingsCubit, PartnerBookingsState>(
          builder: (context, state) {
            final count =
                state is PartnerBookingsLoadedState ? state.bookings.length : 0;
            final dateStr =
                'TODAY · ${formatAppDate(DateTime.now(), locale: Localizations.localeOf(context).toString()).toUpperCase()}';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text('$count bookings', style: AppTypography.screenTitle),
              ],
            );
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
              boxShadow: const [AppShadows.cardShadow],
            ),
            child: IconButton(
              tooltip: 'Refresh bookings',
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.darkNeutral,
                size: 20,
              ),
              onPressed: _loadBookings,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _loadBookings(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip(0, 'All'),
                      _chip(1, 'Waiting'),
                      _chip(2, 'In service'),
                      _chip(3, 'Completed'),
                    ],
                  ),
                ),
              ),

              // Bookings List
              Expanded(
                child: BlocBuilder<PartnerBookingsCubit, PartnerBookingsState>(
                  builder: (context, state) {
                    if (state is PartnerBookingsLoadingState) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGoldDark,
                        ),
                      );
                    }

                    if (state is PartnerBookingsErrorState) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: AppColors.textMuted,
                                size: 40,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadBookings,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final rawBookings = state is PartnerBookingsLoadedState
                        ? state.bookings
                        : [];
                    final filteredBookings = rawBookings.where((b) {
                      final status =
                          (b['status'] ?? '').toString().toUpperCase();
                      if (_selectedFilter == 1) {
                        return status == 'WAITING' || status == 'PENDING';
                      }
                      if (_selectedFilter == 2) {
                        return status == 'IN_SERVICE' || status == 'CONFIRMED';
                      }
                      if (_selectedFilter == 3) {
                        return status == 'COMPLETED' || status == 'DONE';
                      }
                      return true;
                    }).toList();

                    if (filteredBookings.isEmpty) {
                      return Center(
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xxl),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 48,
                                  color: AppColors.textMuted,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No bookings found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkNeutral,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'New customer bookings and walk-ins appear here. This list refreshes every 30 seconds.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: filteredBookings.length,
                      itemBuilder: (context, index) {
                        final b = filteredBookings[index];
                        final customerName = b['customerName'] ??
                            b['customer']?['name'] ??
                            'Walk-in Customer';
                        final initials = customerName.length >= 2
                            ? customerName.substring(0, 2).toUpperCase()
                            : 'CU';
                        final serviceName = b['serviceName'] ??
                            b['services']?[0]?['name'] ??
                            'Service unavailable';
                        final seatLabel = b['seatLabel'] ??
                            b['seat']?['label'] ??
                            'Unassigned';
                        final status = b['status'] ?? 'CONFIRMED';
                        final price = b['total_price'] ?? b['price'];
                        final time =
                            b['start_time'] ?? b['time'] ?? 'Time unavailable';

                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderLight),
                            boxShadow: const [AppShadows.cardShadow],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.darkNeutral,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          customerName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.darkNeutral,
                                          ),
                                        ),
                                        Text(
                                          price == null
                                              ? 'Price unavailable'
                                              : formatCurrency(
                                                  price,
                                                  locale:
                                                      Localizations.localeOf(
                                                    context,
                                                  ).toString(),
                                                ),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGoldDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$serviceName · $time',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF5F5F4),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            seatLabel,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkNeutral,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: status
                                                        .toString()
                                                        .toUpperCase() ==
                                                    'COMPLETED'
                                                ? const Color(0xFFDCFCE7)
                                                : const Color(0xFFFEF9C3),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: status
                                                          .toString()
                                                          .toUpperCase() ==
                                                      'COMPLETED'
                                                  ? const Color(0xFF16A34A)
                                                  : AppColors.primaryGoldDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (status.toString().toUpperCase() !=
                                        'CANCELLED') ...[
                                      const SizedBox(height: 10),
                                      const Divider(height: 1),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          if (status.toString().toUpperCase() ==
                                                  'CONFIRMED' ||
                                              status.toString().toUpperCase() ==
                                                  'WAITING') ...[
                                            OutlinedButton.icon(
                                              onPressed: () => _updateStatus(
                                                b,
                                                'IN_SERVICE',
                                              ),
                                              icon: const Icon(
                                                Icons.play_arrow_rounded,
                                                size: 16,
                                              ),
                                              label: const Text('Start'),
                                              style: OutlinedButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                foregroundColor:
                                                    AppColors.darkNeutral,
                                                side: const BorderSide(
                                                  color: AppColors.borderLight,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _updateStatus(b, 'DONE'),
                                              icon: const Icon(
                                                Icons
                                                    .check_circle_outline_rounded,
                                                size: 16,
                                              ),
                                              label: const Text('Complete'),
                                              style: ElevatedButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                backgroundColor: const Color(
                                                  0xFF16A34A,
                                                ),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ] else if (status
                                                  .toString()
                                                  .toUpperCase() ==
                                              'IN_SERVICE') ...[
                                            ElevatedButton.icon(
                                              onPressed: () =>
                                                  _updateStatus(b, 'DONE'),
                                              icon: const Icon(
                                                Icons.check_circle_rounded,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'Complete Service',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                backgroundColor: const Color(
                                                  0xFF16A34A,
                                                ),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ] else if (status
                                                      .toString()
                                                      .toUpperCase() ==
                                                  'COMPLETED' ||
                                              status.toString().toUpperCase() ==
                                                  'DONE') ...[
                                            const Row(
                                              children: [
                                                Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Color(0xFF16A34A),
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Completed',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF16A34A),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        color: AppColors.background,
        child: SlotPrimaryButton(
          text: '+ Add walk-in',
          onPressed: () => _showWalkInModal(context),
        ),
      ),
    );
  }

  Widget _chip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkNeutral : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.darkNeutral : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.primaryGold : AppColors.darkNeutral,
          ),
        ),
      ),
    );
  }
}

class _WalkInModalContent extends StatefulWidget {
  final String salonId;
  const _WalkInModalContent({required this.salonId});

  @override
  State<_WalkInModalContent> createState() => _WalkInModalContentState();
}

class _WalkInModalContentState extends State<_WalkInModalContent> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  final Set<String> _selectedServiceIds = {};
  String? _selectedSeatId;
  int _selectedDuration = 30;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    context.read<PartnerServicesCubit>().loadServices(salonId: widget.salonId);
    context.read<PartnerSeatsCubit>().loadSeats(6, salonId: widget.salonId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalculateTotal(List<ServiceModel> services) {
    final selected =
        services.where((s) => _selectedServiceIds.contains(s.id)).toList();
    final total = selected.fold(0.0, (sum, s) => sum + s.price);
    final totalMinutes = selected.fold(0, (sum, s) => sum + s.durationMinutes);
    _priceController.text = total > 0 ? total.toInt().toString() : '0';
    _selectedDuration = totalMinutes > 0 ? totalMinutes : 30;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartnerServicesCubit, PartnerServicesState>(
      builder: (context, servicesState) {
        return BlocBuilder<PartnerSeatsCubit, PartnerSeatsState>(
          builder: (context, seatsState) {
            final services = servicesState is PartnerServicesLoadedState
                ? servicesState.services.where((s) => s.isAvailable).toList()
                : <ServiceModel>[];

            if (services.isNotEmpty && _selectedServiceIds.isEmpty) {
              _selectedServiceIds.add(services.first.id);
              _recalculateTotal(services);
            }

            final seatIds = seatsState is PartnerSeatsLoadedState
                ? seatsState.seatIds
                : <int, String>{};
            final seatStatuses = seatsState is PartnerSeatsLoadedState
                ? seatsState.seatStatuses
                : <int, String>{};

            final seatItems = <Map<String, dynamic>>[];
            if (seatIds.isNotEmpty) {
              for (final entry in seatIds.entries) {
                final seatNum = entry.key;
                final seatId = entry.value;
                final status = seatStatuses[seatNum] ?? 'Available';
                seatItems.add({
                  'id': seatId,
                  'number': seatNum,
                  'status': status,
                  'isAvailable': status == 'Available',
                });
              }
            }

            if (seatItems.isNotEmpty) {
              if (_selectedSeatId == null ||
                  !seatItems.any((s) => s['id'] == _selectedSeatId)) {
                final firstAvailable = seatItems.firstWhere(
                  (s) => s['isAvailable'] == true,
                  orElse: () => seatItems.first,
                );
                _selectedSeatId = firstAvailable['id'];
              }
            }

            final isLoadingData =
                servicesState is PartnerServicesLoadingState &&
                    services.isEmpty;

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Walk-in Customer',
                          style: AppTypography.screenTitle,
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (isLoadingData)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            color: AppColors.primaryGoldDark,
                          ),
                        ),
                      )
                    else ...[
                      const Text(
                        'CUSTOMER NAME',
                        style: AppTypography.sectionEyebrow,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkNeutral,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. Rahul Sharma',
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'MOBILE NUMBER (OPTIONAL)',
                        style: AppTypography.sectionEyebrow,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkNeutral,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 98765 43210 (Optional)',
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'NOTES / SPECIAL REQUESTS (OPTIONAL)',
                        style: AppTypography.sectionEyebrow,
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkNeutral,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'e.g. Low fade taper, sensitive skin, beard oil, preferred styling...',
                          hintStyle: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.normal,
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Icon(
                              Icons.edit_note_rounded,
                              color: AppColors.textMuted,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.borderLight,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Multi-Service Selection Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SELECT SERVICES',
                            style: AppTypography.sectionEyebrow,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _selectedServiceIds.isNotEmpty
                                  ? const Color(0xFFFEF9C3)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_selectedServiceIds.length} selected · ${_selectedDuration}m',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGoldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedServiceIds.isEmpty
                                ? AppColors.statusDestructiveText
                                : AppColors.borderLight,
                          ),
                        ),
                        child: services.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  'No active services found. Pull down on Bookings to reload.',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: services.map((svc) {
                                  final isSelected =
                                      _selectedServiceIds.contains(svc.id);
                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedServiceIds.remove(svc.id);
                                        } else {
                                          _selectedServiceIds.add(svc.id);
                                        }
                                        _recalculateTotal(services);
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.darkNeutral
                                            : const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primaryGoldDark
                                              : AppColors.borderLight,
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.check_circle_rounded
                                                : Icons
                                                    .add_circle_outline_rounded,
                                            size: 16,
                                            color: isSelected
                                                ? AppColors.primaryGold
                                                : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                svc.name,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: isSelected
                                                      ? Colors.white
                                                      : AppColors.darkNeutral,
                                                ),
                                              ),
                                              Text(
                                                '₹${svc.price.toInt()} · ${svc.durationMinutes}m',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: isSelected
                                                      ? AppColors.primaryGold
                                                      : AppColors.textMuted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SALON CHAIR / SEAT',
                                  style: AppTypography.sectionEyebrow,
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedSeatId,
                                      isExpanded: true,
                                      hint: const Text('Select Chair'),
                                      icon: const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: AppColors.darkNeutral,
                                      ),
                                      items: seatItems.map((seat) {
                                        final isAvail =
                                            seat['isAvailable'] == true;
                                        return DropdownMenuItem<String>(
                                          value: seat['id'] as String,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.circle,
                                                size: 8,
                                                color: isAvail
                                                    ? const Color(0xFF16A34A)
                                                    : const Color(0xFFEAB308),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Chair ${seat['number']} (${seat['status']})',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                    color: isAvail
                                                        ? AppColors.darkNeutral
                                                        : AppColors.textMuted,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (newSeatId) {
                                        if (newSeatId != null) {
                                          setState(
                                            () => _selectedSeatId = newSeatId,
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TOTAL PRICE (₹)',
                                  style: AppTypography.sectionEyebrow,
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkNeutral,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: AppColors.borderLight,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                        color: AppColors.borderLight,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SlotPrimaryButton(
                        text: _isSubmitting
                            ? 'Seating Customer...'
                            : '⚡ Confirm & Seat Walk-in Customer',
                        onPressed: _isSubmitting ? null : _submitWalkIn,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitWalkIn() async {
    final name = _nameController.text.trim();
    final rawPhone = _phoneController.text.trim();
    final notes = _notesController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter customer name.'),
          backgroundColor: AppColors.statusDestructiveText,
        ),
      );
      return;
    }

    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service.'),
          backgroundColor: AppColors.statusDestructiveText,
        ),
      );
      return;
    }

    String? formattedPhone;
    if (rawPhone.isNotEmpty) {
      final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.length == 10) {
        formattedPhone = '+91 $digitsOnly';
      } else if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
        formattedPhone = '+91 ${digitsOnly.substring(2)}';
      } else if (!rawPhone.startsWith('+') && digitsOnly.isNotEmpty) {
        formattedPhone = '+$digitsOnly';
      } else {
        formattedPhone = rawPhone;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final chosenServiceIds = _selectedServiceIds.toList();
      final price = double.tryParse(_priceController.text.trim()) ?? 250.0;

      await context.read<PartnerBookingsCubit>().addWalkIn(
            customerName: name,
            customerPhone: formattedPhone,
            seatId: _selectedSeatId ?? '',
            salonId: widget.salonId,
            serviceIds: chosenServiceIds,
            totalPrice: price,
            totalDuration: _selectedDuration,
            notes: notes.isNotEmpty ? notes : null,
          );

      if (mounted) {
        context.read<PartnerSeatsCubit>().loadSeats(6, salonId: widget.salonId);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Walk-in created! Customer $name seated successfully.',
            ),
            backgroundColor: AppColors.darkNeutral,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create walk-in: ${e.toString()}'),
            backgroundColor: AppColors.statusDestructiveText,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}

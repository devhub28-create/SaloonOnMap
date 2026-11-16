import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _selectedTab = 0; // 0: Upcoming, 1: Completed, 2: Cancelled
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    try {
      final apiClient = context.read<AuthCubit>().apiClient;
      final customerId = context.read<AuthCubit>().user?['id']?.toString();
      if (customerId == null) throw StateError('Customer session is missing.');
      final bookings =
          await apiClient.getCustomerBookings(customerId: customerId);
      if (mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcomingList = _bookings
        .where((b) =>
            (b['status'] ?? 'CONFIRMED') == 'CONFIRMED' ||
            (b['status'] ?? '') == 'WAITING' ||
            (b['status'] ?? '') == 'IN_SERVICE')
        .toList();
    final completedList =
        _bookings.where((b) => (b['status'] ?? '') == 'DONE').toList();
    final cancelledList =
        _bookings.where((b) => (b['status'] ?? '') == 'CANCELLED').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('My bookings', style: AppTypography.screenTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            SlotSegmentedTab(
              options: const ['Upcoming', 'Completed', 'Cancelled'],
              selectedIndex: _selectedTab,
              onSelected: (index) => setState(() => _selectedTab = index),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isLoading)
              const Expanded(
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryGold)),
              )
            else if (_selectedTab == 0)
              Expanded(
                child: upcomingList.isNotEmpty
                    ? ListView.builder(
                        itemCount: upcomingList.length,
                        itemBuilder: (context, index) {
                          final b = upcomingList[index];
                          final salonName =
                              (b['salonName'] ?? b['salon']?['name'] ?? 'Salon')
                                  .toString();
                          final seatLabel = _formatSeat(b);
                          final status =
                              (b['status'] ?? 'Confirmed').toString();

                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: GestureDetector(
                              onTap: () => _showBookingDetailsBottomSheet(b),
                              child: SlotBookingCard(
                                title: salonName,
                                services:
                                    (b['serviceName'] ?? 'Service').toString(),
                                time: _formatDateTime(b['startAt']),
                                seat: seatLabel,
                                status: status,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 220,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 40, color: AppColors.primaryGoldDark),
                            SizedBox(height: 12),
                            Text('No upcoming visits yet',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Your active bookings will appear here.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
              )
            else if (_selectedTab == 1)
              Expanded(
                child: completedList.isNotEmpty
                    ? ListView.builder(
                        itemCount: completedList.length,
                        itemBuilder: (context, index) {
                          final b = completedList[index];
                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () => _showBookingDetailsBottomSheet(b),
                                  child: SlotBookingCard(
                                    title: b['salonName'] ??
                                        b['salon']?['name'] ??
                                        'Salon',
                                    services:
                                        (b['serviceName'] ?? 'Service').toString(),
                                    time: _formatDateTime(b['startAt']),
                                    seat: _formatSeat(b),
                                    status: 'Completed',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showReviewModal(b),
                                    icon: const Icon(Icons.star_rounded,
                                        color: AppColors.primaryGoldDark,
                                        size: 18),
                                    label: const Text('★ Rate & Review Visit',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.darkNeutral)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: AppColors.borderLight),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 220,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.task_alt_rounded,
                                size: 40, color: AppColors.statusAvailableText),
                            SizedBox(height: 12),
                            Text('No completed visits yet',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Your booking history will appear here.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
              )
            else
              Expanded(
                child: cancelledList.isNotEmpty
                    ? ListView.builder(
                        itemCount: cancelledList.length,
                        itemBuilder: (context, index) {
                          final b = cancelledList[index];
                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: GestureDetector(
                              onTap: () => _showBookingDetailsBottomSheet(b),
                              child: SlotBookingCard(
                                title: b['salonName'] ??
                                    b['salon']?['name'] ??
                                    'Salon',
                                services:
                                    (b['serviceName'] ?? 'Service').toString(),
                                time: _formatDateTime(b['startAt']),
                                seat: _formatSeat(b),
                                status: 'Cancelled',
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        height: 220,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cancel_outlined,
                                size: 40,
                                color: AppColors.statusDestructiveText),
                            SizedBox(height: 12),
                            Text('No cancelled visits',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            SizedBox(height: 4),
                            Text('Any cancelled bookings will appear here.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SlotBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) context.go('/');
          if (index == 1) context.go('/explore');
          if (index == 3) context.go('/offers');
          if (index == 4) context.go('/profile');
        },
        items: const [
          SlotNavItem(icon: Icons.home_rounded, label: 'Home'),
          SlotNavItem(icon: Icons.explore_outlined, label: 'Explore'),
          SlotNavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
          SlotNavItem(
              icon: Icons.confirmation_number_outlined, label: 'Offers'),
          SlotNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
      ),
    );
  }

  void _showBookingDetailsBottomSheet(Map<String, dynamic> booking) {
    final bookingId = (booking['id'] ?? '').toString();
    final salonName =
        (booking['salonName'] ?? booking['salon']?['name'] ?? 'Salon')
            .toString();
    final refCode =
        (booking['referenceCode'] ?? booking['reference_code'] ?? '')
            .toString();
    final status = (booking['status'] ?? 'CONFIRMED').toString();
    final seatLabel =
        (booking['seatLabel'] ?? booking['seat']?['label'] ?? '').toString();
    final stylistName =
        (booking['stylistName'] ?? booking['staff']?['name'] ?? 'No preference')
            .toString();
    final totalAmount =
        '₹${booking['totalAmount'] ?? booking['total_amount'] ?? 0}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(salonName,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNeutral),
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('Booking Reference: $refCode',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'CANCELLED'
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: status == 'CANCELLED'
                          ? AppColors.statusDestructiveText
                          : AppColors.statusAvailableText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _detailRow('Seat Assigned', seatLabel),
                  const Divider(),
                  _detailRow('Stylist', stylistName),
                  const Divider(),
                  _detailRow('Payment Option', 'Pay at Salon'),
                  const Divider(),
                  _detailRow('Total Price', totalAmount, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (status.toUpperCase() == 'DONE' ||
                status.toUpperCase() == 'COMPLETED')
              SlotPrimaryButton(
                text: '★ Rate & Review Salon',
                onPressed: () {
                  Navigator.of(bottomSheetContext).pop();
                  _showReviewModal(booking);
                },
              )
            else if (status.toUpperCase() != 'CANCELLED')
              OutlinedButton(
                onPressed: () {
                  Navigator.of(bottomSheetContext).pop();
                  _showCancelConfirmationDialog(bookingId, refCode);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel_outlined,
                        color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Text('Cancel Booking',
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmationDialog(String bookingId, String refCode) {
    String selectedReason = 'Change of plans';
    final reasons = [
      'Change of plans',
      'Booked wrong time or date',
      'Selected wrong salon or service',
      'Found another appointment',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.background,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cancel Booking',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.darkNeutral)),
              SizedBox(height: 4),
              Text('Please tell us why you are cancelling your visit.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: reasons
                  .map(
                    (reason) => InkWell(
                      onTap: () {
                        setDialogState(() {
                          selectedReason = reason;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Icon(
                              selectedReason == reason
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              size: 20,
                              color: selectedReason == reason
                                  ? AppColors.darkNeutral
                                  : AppColors.textMuted,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(reason,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.darkNeutral)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Keep Booking',
                  style: TextStyle(
                      color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                try {
                  final apiClient = context.read<AuthCubit>().apiClient;
                  await apiClient.cancelBooking(bookingId,
                      reason: selectedReason);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Booking $refCode cancelled successfully.'),
                        backgroundColor: AppColors.darkNeutral,
                      ),
                    );
                    _fetchBookings();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Could not cancel $refCode: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirm Cancellation',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: AppColors.darkNeutral,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSeat(dynamic b) {
    if (b == null) return '';
    if (b['seatLabel'] != null) return b['seatLabel'].toString();
    if (b['seat'] != null && b['seat']['label'] != null) {
      return b['seat']['label'].toString();
    }
    final seatVal = (b['seat_id'] ?? '').toString();
    if (seatVal.startsWith('Seat')) return seatVal;
    return seatVal;
  }

  String _formatDateTime(dynamic value) {
    final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year} · ${date.hour.toString().padLeft(2, '0')}:$minute';
  }

  void _showReviewModal(Map<String, dynamic> booking) {
    int selectedRating = 5;
    final commentController = TextEditingController();
    final selectedTags = <String>{};
    final availableTags = [
      'Great Haircut',
      'Clean & Hygienic',
      'Polite Staff',
      'Quick Service',
      'Value for Money',
      'Good Ambience',
    ];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'How was your visit at ${booking['salonName'] ?? booking['salon']?['name'] ?? 'the salon'}?',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNeutral,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Rate your experience to help us improve.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: AppSpacing.xl),

                // Star Rating Row
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (index) {
                      final starNumber = index + 1;
                      return IconButton(
                        iconSize: 36,
                        onPressed: () {
                          setModalState(() => selectedRating = starNumber);
                        },
                        icon: Icon(
                          starNumber <= selectedRating
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: AppColors.primaryGoldDark,
                        ),
                      );
                    }),
                  ),
                ),
                Center(
                  child: Text(
                    selectedRating == 5
                        ? 'Excellent! 🌟'
                        : selectedRating == 4
                            ? 'Very Good 👍'
                            : selectedRating == 3
                                ? 'Good 🙂'
                                : selectedRating == 2
                                    ? 'Fair 😐'
                                    : 'Needs Improvement 🙁',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNeutral,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Tags
                const Text('WHAT DID YOU LIKE?',
                    style: AppTypography.sectionEyebrow),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableTags.map((tag) {
                    final isTagSelected = selectedTags.contains(tag);
                    return FilterChip(
                      label: Text(tag,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: isTagSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isTagSelected
                                  ? AppColors.darkNeutral
                                  : AppColors.textMuted)),
                      selected: isTagSelected,
                      selectedColor:
                          AppColors.primaryGold.withValues(alpha: 0.3),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isTagSelected
                              ? AppColors.primaryGoldDark
                              : AppColors.borderLight,
                        ),
                      ),
                      onSelected: (selected) {
                        setModalState(() {
                          if (selected) {
                            selectedTags.add(tag);
                          } else {
                            selectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Comment TextField
                const Text('ADDITIONAL COMMENTS',
                    style: AppTypography.sectionEyebrow),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.darkNeutral),
                  decoration: InputDecoration(
                    hintText: 'Share more details about your experience...',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                SlotPrimaryButton(
                  text: 'Submit Review',
                  isLoading: isSubmitting,
                  onPressed: () async {
                    setModalState(() => isSubmitting = true);
                    try {
                      final bookingId = (booking['id'] ?? '').toString();
                      final apiClient = context.read<AuthCubit>().apiClient;
                      await apiClient.createReview(
                        bookingId: bookingId,
                        rating: selectedRating,
                        comment: commentController.text.trim(),
                        tags: selectedTags.toList(),
                      );
                      if (modalContext.mounted) {
                        Navigator.of(modalContext).pop();
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Thank you for your review!'),
                            backgroundColor: AppColors.darkNeutral,
                          ),
                        );
                        _fetchBookings();
                      }
                    } catch (e) {
                      setModalState(() => isSubmitting = false);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Failed to submit review: ${e.toString()}'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

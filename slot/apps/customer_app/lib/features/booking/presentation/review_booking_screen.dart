import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../cubit/booking_cubit.dart';
import 'confirmation_dialog.dart';

class ReviewBookingScreen extends StatefulWidget {
  const ReviewBookingScreen({super.key});

  @override
  State<ReviewBookingScreen> createState() => _ReviewBookingScreenState();
}

class _ReviewBookingScreenState extends State<ReviewBookingScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final bookingCubit = context.read<BookingCubit>();
    final userId = authState is AuthAuthenticatedState
        ? authState.user['id']?.toString()
        : null;
    final salonId = bookingCubit.selectedSalonId;
    if (userId != null && salonId != null) {
      bookingCubit.createHold(salonId, userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<BookingCubit>();
    final authState = context.watch<AuthCubit>().state;
    final userId = authState is AuthAuthenticatedState
        ? authState.user['id']?.toString()
        : null;

    final serviceNames = cubit.selectedServices.isNotEmpty
        ? cubit.selectedServices.map((s) => s['name'] ?? 'Service').join(' + ')
        : 'No services selected';
    final totalPriceStr = '₹${cubit.totalPrice.toInt()}';
    final durationStr = formatDuration(cubit.totalDuration);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Review booking', style: AppTypography.screenTitle),
      ),
      body: BlocListener<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is BookingConfirmedSuccessState) {
            final refCode = state.bookingData['referenceCode'] ??
                state.bookingData['reference_code'] ??
                '#BK${state.bookingData['id']?.toString().substring(0, 4) ?? '0000'}';
            final salonName =
                state.bookingData['salonName'] ?? cubit.selectedSalonName;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => ConfirmationDialog(
                referenceCode: refCode.toString(),
                timeStr: '${cubit.selectedTime} on ${cubit.selectedDate}',
                salonName: salonName.toString(),
              ),
            );
          } else if (state is BookingErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusDestructiveText,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.md),
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.darkNeutral,
                child: Icon(Icons.content_cut_rounded,
                    color: AppColors.primaryGold, size: 28),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(cubit.selectedSalonName.toUpperCase(),
                  style: AppTypography.sectionEyebrow),
              const SizedBox(height: 4),
              const Text('Everything look good?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xl),

              // Summary Card Table
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [AppShadows.cardShadow],
                ),
                child: Column(
                  children: [
                    _row('Services', serviceNames),
                    const Divider(),
                    _row('Date', cubit.selectedDate),
                    const Divider(),
                    _row('Time', '${cubit.selectedTime} · $durationStr'),
                    const Divider(),
                    _row('Seat', cubit.selectedSeatLabel),
                    const Divider(),
                    _row('Stylist', cubit.selectedStylist),
                    const Divider(),
                    _row('Payment', 'Pay at salon'),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total amount',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500)),
                          Text(totalPriceStr,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNeutral)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 5-minute Hold Timer Banner
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 18, color: AppColors.statusAvailableText),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your seat and slot are held for 5 minutes.',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.statusAvailableText),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: SlotPrimaryButton(
          text: 'Confirm booking →',
          isLoading: cubit.state is BookingLoadingState,
          onPressed: () {
            if (userId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Sign in again before confirming this booking.')));
              return;
            }
            cubit.confirmBooking(userId);
          },
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNeutral),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../cubit/admin_bookings_cubit.dart';

class AdminBookingsScreen extends StatelessWidget {
  const AdminBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBookingsCubit, AdminBookingsState>(
      builder: (context, state) {
        if (state is AdminBookingsLoading || state is AdminBookingsInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold));
        }
        if (state is AdminBookingsError) {
          return Center(child: Text(state.message));
        }
        final bookings = state is AdminBookingsLoaded
            ? state.bookings
            : <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const Text('PLATFORM BOOKINGS',
                style: AppTypography.sectionEyebrow),
            const SizedBox(height: 4),
            const Text('Booking Management', style: AppTypography.screenTitle),
            const SizedBox(height: AppSpacing.xl),
            if (bookings.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No bookings found.')))
            else
              ...bookings.map((booking) {
                final start =
                    DateTime.tryParse(booking['startAt']?.toString() ?? '')
                        ?.toLocal();
                final time = start == null
                    ? ''
                    : '${start.day}/${start.month}/${start.year} ${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: SlotBookingCard(
                    title:
                        '${booking['customerName'] ?? 'Customer'} · ${booking['salonName'] ?? ''}',
                    services:
                        booking['serviceName']?.toString().isNotEmpty == true
                            ? booking['serviceName'].toString()
                            : 'Service not recorded',
                    time: time,
                    seat: booking['seatLabel']?.toString() ?? '',
                    status: booking['status']?.toString() ?? '',
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

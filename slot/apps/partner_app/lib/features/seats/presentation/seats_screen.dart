import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../../auth/cubit/partner_auth_cubit.dart';
import '../cubit/partner_seats_cubit.dart';

class SeatsScreen extends StatefulWidget {
  const SeatsScreen({super.key});

  @override
  State<SeatsScreen> createState() => _SeatsScreenState();
}

class _SeatsScreenState extends State<SeatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<PartnerAuthCubit>().state;
      final totalSeats =
          authState is PartnerAuthenticated ? authState.seatCount : 4;
      final salonId =
          authState is PartnerAuthenticated ? authState.salonId : null;
      context.read<PartnerSeatsCubit>().loadSeats(totalSeats, salonId: salonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartnerAuthCubit, PartnerAuthState>(
      builder: (context, authState) {
        final salonName =
            authState is PartnerAuthenticated ? authState.salonName : 'Salon';
        final int totalSeats =
            authState is PartnerAuthenticated ? authState.seatCount : 4;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('LIVE FLOOR',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 1.1)),
                const SizedBox(height: 2),
                Text('$salonName Seats', style: AppTypography.screenTitle),
              ],
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seat Manager Bar (+ / - seat count)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [AppShadows.cardShadow],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_seat_rounded,
                                color: AppColors.primaryGoldDark, size: 20),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$totalSeats Seats Registered',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.darkNeutral)),
                                const Text('Manage chair capacity',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            InkWell(
                              onTap: totalSeats > 1
                                  ? () {
                                      final newCount = totalSeats - 1;
                                      context
                                          .read<PartnerAuthCubit>()
                                          .updateSeatCount(newCount);
                                      final salonId =
                                          authState is PartnerAuthenticated
                                              ? authState.salonId
                                              : null;
                                      context
                                          .read<PartnerSeatsCubit>()
                                          .loadSeats(newCount,
                                              salonId: salonId);
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: totalSeats > 1
                                      ? const Color(0xFFFEE2E2)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.remove,
                                    size: 16,
                                    color: totalSeats > 1
                                        ? AppColors.statusDestructiveText
                                        : Colors.grey),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('$totalSeats',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ),
                            InkWell(
                              onTap: () {
                                final newCount = totalSeats + 1;
                                context
                                    .read<PartnerAuthCubit>()
                                    .updateSeatCount(newCount);
                                final salonId =
                                    authState is PartnerAuthenticated
                                        ? authState.salonId
                                        : null;
                                context
                                    .read<PartnerSeatsCubit>()
                                    .loadSeats(newCount, salonId: salonId);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.add,
                                    size: 16,
                                    color: AppColors.statusAvailableText),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Status Legend Row
                  Row(
                    children: [
                      _legendItem('Available', const Color(0xFF16A34A)),
                      const SizedBox(width: 16),
                      _legendItem('Booked', const Color(0xFFD97706)),
                      const SizedBox(width: 16),
                      _legendItem('In service', const Color(0xFF0284C7)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Floor Plan Frame
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EFE6),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        // MIRROR WALL Top Bar
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const Text(
                            'MIRROR WALL',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Dynamic Persistent Chair Grid
                        BlocBuilder<PartnerSeatsCubit, PartnerSeatsState>(
                          builder: (context, seatsState) {
                            final map = seatsState is PartnerSeatsLoadedState
                                ? seatsState.seatStatuses
                                : <int, String>{};

                            return GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.2,
                              ),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: totalSeats,
                              itemBuilder: (context, index) {
                                final seatNum = index + 1;
                                final currentStatus =
                                    map[seatNum] ?? 'Available';

                                Color statusColor = const Color(0xFF16A34A);
                                String subtext = 'Ready for customer';
                                if (currentStatus == 'Booked') {
                                  statusColor = const Color(0xFFD97706);
                                  subtext = 'Booked';
                                } else if (currentStatus == 'In service') {
                                  statusColor = const Color(0xFF0284C7);
                                  subtext = 'Active styling';
                                }

                                return GestureDetector(
                                  onTap: () {
                                    context
                                        .read<PartnerSeatsCubit>()
                                        .toggleSeatStatus(seatNum,
                                            totalSeats: totalSeats);
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Seat $seatNum status updated.'),
                                        duration:
                                            const Duration(milliseconds: 800),
                                      ),
                                    );
                                  },
                                  child: _ChairCard(
                                    number: '$seatNum',
                                    status: currentStatus,
                                    subtext: subtext,
                                    color: statusColor,
                                    hasActiveBorder:
                                        currentStatus == 'In service',
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // RECEPTION Bottom Bar
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: const Text(
                            'RECEPTION & WAITING AREA',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ChairCard extends StatelessWidget {
  final String number;
  final String status;
  final String subtext;
  final Color color;
  final bool hasActiveBorder;

  const _ChairCard({
    required this.number,
    required this.status,
    required this.subtext,
    required this.color,
    this.hasActiveBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActiveBorder ? color : AppColors.borderLight,
          width: hasActiveBorder ? 2 : 1,
        ),
        boxShadow: const [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seat $number',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.darkNeutral),
              ),
              Icon(Icons.event_seat_rounded, color: color, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                status,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 12, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

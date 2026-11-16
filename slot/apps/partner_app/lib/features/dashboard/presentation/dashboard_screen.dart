import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/partner_auth_cubit.dart';
import '../cubit/partner_dashboard_cubit.dart';
import '../../seats/cubit/partner_seats_cubit.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              context.read<PartnerDashboardCubit>().fetchDashboard(),
          child: BlocBuilder<PartnerAuthCubit, PartnerAuthState>(
            builder: (context, authState) {
              final salonName = authState is PartnerAuthenticated
                  ? authState.salonName
                  : 'Salon';
              final ownerName = authState is PartnerAuthenticated
                  ? authState.ownerName
                  : 'Partner';

              return BlocBuilder<PartnerDashboardCubit, PartnerDashboardState>(
                builder: (context, state) {
                  final data = state is PartnerDashboardLoadedState
                      ? state.data
                      : <String, dynamic>{};
                  final num revenue = data['todayRevenue'] ?? 0;
                  final String comparison =
                      data['revenueComparison'] ?? 'Desk Active & Live';
                  final String bookingsCount =
                      (data['todayBookings'] ?? 0).toString();
                  final String fallbackAvailableSeats =
                      (data['availableSeats'] ?? 0).toString();
                  final String waitingCount =
                      (data['waitingCustomers'] ?? 0).toString();
                  final String fallbackInServiceCount =
                      (data['inServiceCustomers'] ?? 0).toString();
                  final int unreadNotifications =
                      (data['unreadNotifications'] as num? ?? 0).toInt();
                  final List<dynamic> bookingsList =
                      data['recentBookings'] as List<dynamic>? ?? [];

                  return BlocBuilder<PartnerSeatsCubit, PartnerSeatsState>(
                    builder: (context, seatsState) {
                      final Map<int, String> seatMap =
                          seatsState is PartnerSeatsLoadedState
                              ? seatsState.seatStatuses
                              : <int, String>{};
                      final String availableSeats =
                          seatsState is PartnerSeatsLoadedState
                              ? seatsState.availableCount.toString()
                              : fallbackAvailableSeats;
                      final String inServiceCount =
                          seatsState is PartnerSeatsLoadedState
                              ? seatsState.inServiceCount.toString()
                              : fallbackInServiceCount;

                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with Dynamic Salon Name & Owner Greeting
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${salonName.toUpperCase()} · LIVE',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMuted,
                                          letterSpacing: 1.1),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Good day, $ownerName',
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkNeutral),
                                    ),
                                  ],
                                ),
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.borderLight,
                                        ),
                                      ),
                                      child: IconButton(
                                        tooltip: 'Notifications',
                                        icon: const Icon(
                                          Icons.notifications_none_rounded,
                                          color: AppColors.darkNeutral,
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          await context.push(
                                            '/partner/notifications',
                                          );
                                          if (context.mounted) {
                                            context
                                                .read<PartnerDashboardCubit>()
                                                .fetchDashboard();
                                          }
                                        },
                                      ),
                                    ),
                                    if (unreadNotifications > 0)
                                      Positioned(
                                        top: -4,
                                        right: -4,
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.statusDestructiveText,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            unreadNotifications > 99
                                                ? '99+'
                                                : '$unreadNotifications',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // Today's Revenue Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.xl),
                              decoration: BoxDecoration(
                                color: AppColors.darkNeutral,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: const [AppShadows.cardShadow],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "TODAY'S REVENUE",
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGold,
                                            letterSpacing: 1.1),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '₹${revenue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                                        style: const TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.north_east_rounded,
                                              size: 14,
                                              color: Color(0xFF16A34A)),
                                          const SizedBox(width: 4),
                                          Text(
                                            comparison,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF16A34A),
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.bar_chart_rounded,
                                      color: AppColors.primaryGold, size: 48),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),

                            // 4 Metric Grid Cards (2x2 Layout)
                            Row(
                              children: [
                                _metricTile(
                                    bookingsCount,
                                    'Bookings',
                                    Icons.calendar_today_rounded,
                                    const Color(0xFFFEF9C3),
                                    AppColors.primaryGoldDark),
                                const SizedBox(width: AppSpacing.md),
                                _metricTile(
                                    availableSeats,
                                    'Available seats',
                                    Icons.event_seat_rounded,
                                    const Color(0xFFDCFCE7),
                                    const Color(0xFF16A34A)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                _metricTile(
                                    waitingCount,
                                    'Waiting',
                                    Icons.people_outline_rounded,
                                    const Color(0xFFFCE7F3),
                                    const Color(0xFFEC4899)),
                                const SizedBox(width: AppSpacing.md),
                                _metricTile(
                                    inServiceCount,
                                    'In service',
                                    Icons.content_cut_rounded,
                                    const Color(0xFFE0F2FE),
                                    const Color(0xFF0284C7)),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Live Floor Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Live floor',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkNeutral)),
                                GestureDetector(
                                  onTap: () => context.go('/seats'),
                                  child: const Row(
                                    children: [
                                      Text('Manage',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textMuted)),
                                      Icon(Icons.arrow_forward_ios_rounded,
                                          size: 12, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),

                            // Dynamic Live Floor Seat Cards
                            Row(
                              children: List.generate(4, (index) {
                                final seatNum = index + 1;
                                final status = seatMap[seatNum] ?? 'Available';
                                Color color = const Color(0xFF16A34A);
                                IconData icon = Icons.event_seat_rounded;
                                if (status == 'Booked') {
                                  color = const Color(0xFFD97706);
                                  icon = Icons.event_seat_rounded;
                                } else if (status == 'In service') {
                                  color = const Color(0xFF0284C7);
                                  icon = Icons.content_cut_rounded;
                                }
                                final numStr =
                                    seatNum < 10 ? '0$seatNum' : '$seatNum';
                                return _seatMini(numStr, status, color, icon);
                              }),
                            ),
                            const SizedBox(height: AppSpacing.xl),

                            // Up Next Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Up next',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkNeutral)),
                                GestureDetector(
                                  onTap: () => context.go('/bookings'),
                                  child: const Row(
                                    children: [
                                      Text('View all',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textMuted)),
                                      Icon(Icons.arrow_forward_ios_rounded,
                                          size: 12, color: AppColors.textMuted),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),

                            if (bookingsList.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: AppColors.borderLight),
                                ),
                                child: const Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.calendar_today_rounded,
                                          size: 32, color: AppColors.textMuted),
                                      SizedBox(height: 8),
                                      Text('No bookings scheduled yet today',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkNeutral)),
                                      SizedBox(height: 4),
                                      Text(
                                          'New customer bookings & walk-ins will appear here live.',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              for (var item in bookingsList)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md),
                                  child: _queueCard(
                                    (item['customerName'] ?? 'CU')
                                        .substring(0, 2)
                                        .toUpperCase(),
                                    item['customerName'] ?? 'Customer',
                                    item['serviceName'] ?? 'Styling Service',
                                    item['seatLabel'] ?? 'Seat 1',
                                    item['status'] ?? 'Confirmed',
                                    item['time'] ?? 'Today',
                                  ),
                                ),
                            ],
                            const SizedBox(height: AppSpacing.lg),

                            // Salon Desk Status Card
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: AppColors.borderLight),
                                boxShadow: const [AppShadows.cardShadow],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF9C3),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.storefront_rounded,
                                        color: AppColors.primaryGoldDark,
                                        size: 24),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('$salonName Status',
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.darkNeutral)),
                                        const SizedBox(height: 2),
                                        const Text(
                                            'Salon desk active & open for customer bookings',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textMuted)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _metricTile(
      String value, String label, IconData icon, Color bg, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [AppShadows.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNeutral)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _seatMini(String num, String status, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text('Seat $num',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNeutral)),
            const SizedBox(height: 2),
            Text(status,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _queueCard(String initials, String name, String service, String seat,
      String status, String time,
      {bool isWaiting = false}) {
    return Container(
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
            backgroundColor:
                isWaiting ? const Color(0xFFFCE7F3) : AppColors.darkNeutral,
            child: Text(initials,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isWaiting
                        ? const Color(0xFFEC4899)
                        : AppColors.primaryGold)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNeutral)),
                    Text(time,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(service,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F4),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(seat,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNeutral)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isWaiting
                            ? const Color(0xFFFCE7F3)
                            : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isWaiting
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF16A34A)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

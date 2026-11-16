import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../cubit/admin_dashboard_cubit.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoadingState) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold));
        }

        final overview = state is AdminDashboardLoadedState
            ? state.overview
            : <String, dynamic>{};
        final totalSalons = (overview['totalSalons'] ?? 0).toString();
        final totalUsers = (overview['totalUsers'] ?? 0).toString();
        final totalBookings = (overview['totalBookings'] ?? 0).toString();
        final revenue = '₹${overview['totalRevenue'] ?? 0}';
        final activeSalons = (overview['activeSalons'] ?? 0).toString();
        final pendingApprovals = (overview['pendingApprovals'] ?? 0).toString();
        final newUsers = (overview['newUsers'] ?? 0).toString();
        final cancelledBookings =
            (overview['cancelledBookings'] ?? 0).toString();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text('PLATFORM OVERVIEW',
                  style: AppTypography.sectionEyebrow),
              const SizedBox(height: 4),
              const Text('Dashboard', style: AppTypography.screenTitle),
              const SizedBox(height: AppSpacing.xl),

              // Overview Stat Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _statCard('Total Salons', totalSalons, isWide),
                      _statCard('Total Users', totalUsers, isWide),
                      _statCard('Total Bookings', totalBookings, isWide),
                      _statCard('Revenue', revenue, isWide, isGold: true),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Quick Status Counters
              Row(
                children: [
                  _badgeCount(
                      'Active Salons',
                      activeSalons,
                      AppColors.statusAvailableBg,
                      AppColors.statusAvailableText),
                  const SizedBox(width: 12),
                  _badgeCount('Pending Approvals', pendingApprovals,
                      const Color(0xFFFEF9C3), AppColors.statusBookedText),
                  const SizedBox(width: 12),
                  _badgeCount(
                      'New Users',
                      newUsers,
                      AppColors.statusInServiceBg,
                      AppColors.statusInServiceText),
                  const SizedBox(width: 12),
                  _badgeCount('Cancelled', cancelledBookings,
                      const Color(0xFFFDE8E8), AppColors.statusDestructiveText),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statCard(String title, String value, bool isWide,
      {bool isGold = false}) {
    return Container(
      width: isWide ? 220 : double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isGold ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: isGold ? Colors.white70 : AppColors.textMuted,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isGold ? Colors.white : AppColors.darkNeutral)),
        ],
      ),
    );
  }

  Widget _badgeCount(String label, String value, Color bg, Color text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: text)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.bold, color: text)),
          ],
        ),
      ),
    );
  }
}

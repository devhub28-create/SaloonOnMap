import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:api_client/api_client.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/partner_auth_cubit.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int _selectedFilter = 1; // 0: Day, 1: Week, 2: Month
  bool _isLoading = true;
  Map<String, dynamic>? _reportsData;
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() => _isLoading = true);
    final periodStr = _selectedFilter == 0
        ? 'Day'
        : _selectedFilter == 2
            ? 'Month'
            : 'Week';
    try {
      final authState = context.read<PartnerAuthCubit>().state;
      final salonId =
          authState is PartnerAuthenticated ? authState.salonId : null;
      final res = await _apiClient.getPartnerReports(
          period: periodStr, salonId: salonId);
      setState(() {
        _reportsData = res;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _onFilterChanged(int index) {
    if (_selectedFilter == index) return;
    setState(() {
      _selectedFilter = index;
    });
    _fetchReports();
  }

  @override
  Widget build(BuildContext context) {
    final periodLabel = _reportsData?['periodLabel']?.toString() ??
        (_selectedFilter == 0
            ? 'DAILY REVENUE'
            : _selectedFilter == 2
                ? 'MONTHLY REVENUE'
                : 'WEEKLY REVENUE');
    final totalRevenueNum =
        double.tryParse(_reportsData?['totalRevenue']?.toString() ?? '0') ??
            0.0;
    final revenueChange =
        _reportsData?['revenueChange']?.toString() ?? '0% (Baseline)';

    final rawChartList = List<dynamic>.from(_reportsData?['chartData'] ?? []);
    final double maxVal = rawChartList.fold<double>(1.0, (prev, elem) {
      final val = double.tryParse(elem['value']?.toString() ?? '0') ?? 0.0;
      return val > prev ? val : prev;
    });

    final metrics = _reportsData?['metrics'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.darkNeutral, size: 20),
          onPressed: () => context.pop(),
        ),
        title:
            const Text('Reports & Insights', style: AppTypography.screenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.darkNeutral, size: 22),
            onPressed: _fetchReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  // Filter Pills (Day, Week, Month)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EFEA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _timeTab(0, 'Day'),
                        _timeTab(1, 'Week'),
                        _timeTab(2, 'Month'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Revenue Banner Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.darkNeutral,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [AppShadows.cardShadow],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(periodLabel,
                                  style: const TextStyle(
                                      color: AppColors.primaryGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1)),
                              const SizedBox(height: 8),
                              Text('₹${totalRevenueNum.toInt()}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.north_east_rounded,
                                      size: 14, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 4),
                                  Text(revenueChange,
                                      style: const TextStyle(
                                          color: Color(0xFF16A34A),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.bar_chart_rounded,
                            color: AppColors.primaryGold, size: 44),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Dynamic Bar Chart Container
                  if (rawChartList.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: const [AppShadows.cardShadow],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: rawChartList.map((item) {
                          final dayLabel = item['day']?.toString() ?? '';
                          final val = double.tryParse(
                                  item['value']?.toString() ?? '0') ??
                              0.0;
                          final factor = maxVal > 0
                              ? (val / maxVal).clamp(0.12, 1.0)
                              : 0.5;
                          return _bar(dayLabel, factor);
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // Insights Table
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [AppShadows.cardShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('BUSINESS METRICS',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                                letterSpacing: 1.1)),
                        const SizedBox(height: 12),
                        _insightRow('Total Bookings',
                            '${metrics['totalBookings'] ?? 0}'),
                        const Divider(color: AppColors.borderLight),
                        _insightRow('Completed Visits',
                            '${metrics['completedBookings'] ?? 0}'),
                        const Divider(color: AppColors.borderLight),
                        _insightRow('Cancelled Visits',
                            '${metrics['cancelledBookings'] ?? 0}'),
                        const Divider(color: AppColors.borderLight),
                        _insightRow('Average Ticket',
                            '${metrics['averageTicket'] ?? "₹0"}'),
                        const Divider(color: AppColors.borderLight),
                        _insightRow('Most Popular Service',
                            '${metrics['mostPopularService'] ?? "No completed bookings yet"}'),
                        const Divider(color: AppColors.borderLight),
                        _insightRow('Top Combo',
                            '${metrics['topCombo'] ?? "No combo data yet"}'),
                        const Divider(color: AppColors.borderLight),
                        _insightRow('Peak Booking Time',
                            '${metrics['peakBookingTime'] ?? "No booking data yet"}'),
                        const Divider(color: AppColors.borderLight),
                        _insightRow('Repeat Customers',
                            '${metrics['repeatCustomers'] ?? "No repeat data yet"}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _timeTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onFilterChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? const [AppShadows.cardShadow] : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? AppColors.darkNeutral : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar(String day, double heightFactor) {
    return Column(
      children: [
        Container(
          height: 110 * heightFactor,
          width: 28,
          decoration: BoxDecoration(
            color: AppColors.primaryGoldDark,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Text(day,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted)),
      ],
    );
  }

  Widget _insightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNeutral)),
        ],
      ),
    );
  }
}

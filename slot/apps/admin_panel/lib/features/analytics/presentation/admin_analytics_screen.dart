import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/admin_ui.dart';
import '../cubit/admin_analytics_cubit.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  int _days = 30;
  void _load(int days) {
    setState(() => _days = days);
    context.read<AdminAnalyticsCubit>().fetchAnalytics(days: days);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminAnalyticsCubit, AdminAnalyticsState>(
          builder: (context, state) {
        final loaded = state is AdminAnalyticsLoaded ? state.data : null;
        return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              AdminPageHeader(
                eyebrow: 'Commercial operations',
                title: 'Platform analytics',
                description:
                    'Track completed revenue, booking quality, and salon performance across the marketplace.',
                actions: [
                  SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 7, label: Text('7D')),
                        ButtonSegment(value: 30, label: Text('30D')),
                        ButtonSegment(value: 90, label: Text('90D'))
                      ],
                      selected: {
                        _days
                      },
                      onSelectionChanged: state is AdminAnalyticsLoading
                          ? null
                          : (value) => _load(value.first))
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (state is AdminAnalyticsLoading ||
                  state is AdminAnalyticsInitial)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator()))
              else if (state is AdminAnalyticsError)
                AdminStatePanel.error(
                  title: 'Analytics unavailable',
                  message: state.message,
                  onAction: () => _load(_days),
                )
              else if (loaded != null)
                ..._content(context, loaded),
            ]);
      });

  List<Widget> _content(BuildContext context, Map<String, dynamic> data) {
    final summary = Map<String, dynamic>.from(data['summary'] as Map? ?? {});
    final daily = (data['daily'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final salons = (data['topSalons'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final payments = (data['paymentStatuses'] as List<dynamic>? ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final maxRevenue = daily.fold<double>(
        0,
        (max, item) => (item['revenue'] as num? ?? 0).toDouble() > max
            ? (item['revenue'] as num).toDouble()
            : max);
    return [
      Wrap(spacing: 12, runSpacing: 12, children: [
        _metric(context, 'Completed revenue',
            '₹${summary['completedRevenue'] ?? 0}', Icons.currency_rupee),
        _metric(context, 'Average ticket', '₹${summary['averageTicket'] ?? 0}',
            Icons.receipt_long),
        _metric(context, 'Completed', '${summary['completedBookings'] ?? 0}',
            Icons.check_circle_outline),
        _metric(context, 'Cancellation rate',
            '${summary['cancellationRate'] ?? 0}%', Icons.cancel_outlined),
      ]),
      const SizedBox(height: AppSpacing.xl),
      Text('Daily completed revenue',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: daily.isEmpty
                  ? const Text('No bookings in this period.')
                  : Column(
                      children: daily.map((item) {
                      final revenue = (item['revenue'] as num? ?? 0).toDouble();
                      return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            SizedBox(
                                width: 92,
                                child: Text(item['date']?.toString() ?? '')),
                            Expanded(
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                        value: maxRevenue == 0
                                            ? 0
                                            : revenue / maxRevenue,
                                        minHeight: 14,
                                        color: AppColors.primaryGold,
                                        backgroundColor:
                                            Colors.grey.shade200))),
                            const SizedBox(width: 12),
                            SizedBox(
                                width: 90,
                                child: Text('₹${revenue.toStringAsFixed(0)}',
                                    textAlign: TextAlign.end)),
                          ]));
                    }).toList()))),
      const SizedBox(height: AppSpacing.xl),
      Text('Top salons by completed revenue',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      if (salons.isEmpty)
        const Text('No completed salon bookings in this period.')
      else
        ...salons.map((salon) => Card(
            child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(salon['salonName']?.toString() ?? 'Salon'),
                subtitle: Text(
                    '${salon['bookings']} bookings · ${salon['cancelledBookings']} cancelled'),
                trailing: Text('₹${salon['revenue']}',
                    style: Theme.of(context).textTheme.titleMedium)))),
      const SizedBox(height: AppSpacing.xl),
      Text('Payment status visibility',
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 6),
      const Text(
          'The current checkout is pay-at-salon. These are booking payment labels, not settled bank transactions.'),
      const SizedBox(height: 12),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: payments
              .map((item) =>
                  Chip(label: Text('${item['status']} · ${item['count']}')))
              .toList()),
    ];
  }

  Widget _metric(
          BuildContext context, String label, String value, IconData icon) =>
      SizedBox(
          width: 230,
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, color: AppColors.primaryGold),
                        const SizedBox(height: 12),
                        Text(value,
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text(label)
                      ]))));
}

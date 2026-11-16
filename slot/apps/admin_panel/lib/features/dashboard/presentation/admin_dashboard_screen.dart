import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/admin_ui.dart';
import '../cubit/admin_dashboard_cubit.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
      builder: (context, state) {
        if (state is AdminDashboardLoadingState ||
            state is AdminDashboardInitialState) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGold),
          );
        }
        if (state is AdminDashboardErrorState) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AdminStatePanel.error(
              title: 'Dashboard unavailable',
              message: state.message,
              onAction: () =>
                  context.read<AdminDashboardCubit>().fetchDashboard(),
            ),
          );
        }

        final overview = state is AdminDashboardLoadedState
            ? state.overview
            : <String, dynamic>{};
        final metrics = [
          _Metric(
              'Total salons',
              '${overview['totalSalons'] ?? 0}',
              'Manage partner locations',
              Icons.storefront_rounded,
              '/salons',
              const Color(0xFF8B5CF6)),
          _Metric(
              'Platform users',
              '${overview['totalUsers'] ?? 0}',
              '${overview['newUsers'] ?? 0} joined recently',
              Icons.group_rounded,
              '/users',
              const Color(0xFF2563EB)),
          _Metric(
              'Total bookings',
              '${overview['totalBookings'] ?? 0}',
              '${overview['cancelledBookings'] ?? 0} cancelled',
              Icons.calendar_month_rounded,
              '/bookings',
              const Color(0xFF0F9F6E)),
          _Metric(
              'Open support',
              '${overview['openSupportTickets'] ?? 0}',
              'Tickets needing attention',
              Icons.support_agent_rounded,
              '/support',
              const Color(0xFFE87916)),
          _Metric(
              'Completed revenue',
              '₹${overview['totalRevenue'] ?? 0}',
              'View platform performance',
              Icons.trending_up_rounded,
              '/analytics',
              AppColors.primaryGoldDark,
              dark: true),
        ];
        final status = _StatusOverview(
          activeSalons: '${overview['activeSalons'] ?? 0}',
          pendingApprovals: '${overview['pendingApprovals'] ?? 0}',
          cancelledBookings: '${overview['cancelledBookings'] ?? 0}',
          openSupport: '${overview['openSupportTickets'] ?? 0}',
        );

        return RefreshIndicator(
          onRefresh: () => context.read<AdminDashboardCubit>().fetchDashboard(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(
                AppBreakpoints.isMobile(context) ? AppSpacing.lg : 28),
            children: [
              AdminPageHeader(
                eyebrow: 'Platform overview',
                title: 'Good to see you, Admin',
                description:
                    'Monitor marketplace activity, resolve operational issues, and keep every SLOT experience running smoothly.',
                actions: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.read<AdminDashboardCubit>().fetchDashboard(),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh data'),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              LayoutBuilder(builder: (context, constraints) {
                final columns = constraints.maxWidth >= 1180
                    ? 5
                    : constraints.maxWidth >= 760
                        ? 3
                        : constraints.maxWidth >= 480
                            ? 2
                            : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 14) / columns;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: metrics
                      .map((metric) => SizedBox(
                          width: width, child: _MetricCard(metric: metric)))
                      .toList(),
                );
              }),
              const SizedBox(height: 28),
              LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth < 850) {
                  return Column(children: [
                    status,
                    const SizedBox(height: 16),
                    const _QuickActions(),
                  ]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: status),
                    const SizedBox(width: 16),
                    const Expanded(flex: 2, child: _QuickActions()),
                  ],
                );
              }),
              const SizedBox(height: 28),
            ],
          ),
        );
      },
    );
  }
}

class _Metric {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final String route;
  final Color accent;
  final bool dark;
  const _Metric(
      this.label, this.value, this.helper, this.icon, this.route, this.accent,
      {this.dark = false});
}

class _MetricCard extends StatefulWidget {
  final _Metric metric;
  const _MetricCard({required this.metric});
  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;
    final foreground = metric.dark ? Colors.white : AppColors.darkNeutral;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(metric.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 170),
          transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: metric.dark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: _hovered
                  ? metric.accent.withValues(alpha: .45)
                  : AppColors.borderLight,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: metric.accent.withValues(alpha: .12),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [AppShadows.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color:
                        metric.accent.withValues(alpha: metric.dark ? .22 : .1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(metric.icon, color: metric.accent, size: 20),
                ),
                const Spacer(),
                Icon(Icons.arrow_outward_rounded,
                    size: 18,
                    color: metric.dark ? Colors.white54 : AppColors.textMuted),
              ]),
              const SizedBox(height: 20),
              Text(metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: foreground,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.7)),
              const SizedBox(height: 4),
              Text(metric.label,
                  style: TextStyle(
                      color: foreground, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(metric.helper,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: metric.dark ? Colors.white54 : AppColors.textMuted,
                      fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusOverview extends StatelessWidget {
  final String activeSalons;
  final String pendingApprovals;
  final String cancelledBookings;
  final String openSupport;
  const _StatusOverview({
    required this.activeSalons,
    required this.pendingApprovals,
    required this.cancelledBookings,
    required this.openSupport,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const AdminSectionHeader(
              title: 'Operational pulse',
              description: 'Live priorities across the platform'),
          const SizedBox(height: 20),
          Wrap(spacing: 10, runSpacing: 10, children: [
            _StatusItem('Active salons', activeSalons,
                AppColors.statusAvailableText, Icons.check_circle_rounded),
            _StatusItem('Pending approval', pendingApprovals,
                AppColors.statusBookedText, Icons.pending_actions_rounded),
            _StatusItem('Cancelled', cancelledBookings,
                AppColors.statusDestructiveText, Icons.event_busy_rounded),
            _StatusItem('Open support', openSupport,
                AppColors.statusInServiceText, Icons.forum_outlined),
          ]),
        ]),
      );
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatusItem(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 145),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(14)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 17, fontWeight: FontWeight.w800)),
            Text(label,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
        ]),
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(AppRadius.card)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Quick actions',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Jump into common admin workflows',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 18),
          _action(context, 'Review salon applications', Icons.verified_outlined,
              '/salons'),
          _action(context, 'Resolve support tickets',
              Icons.support_agent_rounded, '/support'),
          _action(context, 'Send a campaign', Icons.campaign_outlined,
              '/notifications'),
        ]),
      );

  Widget _action(
          BuildContext context, String label, IconData icon, String route) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => context.go(route),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Row(children: [
                Icon(icon, color: AppColors.primaryGold, size: 19),
                const SizedBox(width: 11),
                Expanded(
                    child: Text(label,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600))),
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white38, size: 18),
              ]),
            ),
          ),
        ),
      );
}

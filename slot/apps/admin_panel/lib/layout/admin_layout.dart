import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/cubit/admin_auth_cubit.dart';
import '../features/system_health/cubit/admin_system_health_cubit.dart';
import '../core/auth/admin_permissions.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  final List<_NavEntry> _navItems = const [
    _NavEntry('Dashboard', Icons.grid_view_rounded, '/', 'Overview'),
    _NavEntry('Analytics', Icons.insights_rounded, '/analytics', 'Overview'),
    _NavEntry('Salons', Icons.storefront_rounded, '/salons', 'Operations'),
    _NavEntry(
        'Bookings', Icons.calendar_month_rounded, '/bookings', 'Operations'),
    _NavEntry('Users', Icons.group_outlined, '/users', 'Operations'),
    _NavEntry(
        'Support Desk', Icons.support_agent_rounded, '/support', 'Operations'),
    _NavEntry('Offers', Icons.local_offer_outlined, '/offers', 'Engagement'),
    _NavEntry('Reviews', Icons.reviews_outlined, '/reviews', 'Engagement'),
    _NavEntry('Notifications', Icons.campaign_outlined, '/notifications',
        'Engagement'),
    _NavEntry('AI Operations', Icons.auto_awesome_outlined, '/ai-operations',
        'Governance'),
    _NavEntry('System Health', Icons.monitor_heart_outlined, '/system-health',
        'Governance'),
    _NavEntry(
        'Audit Logs', Icons.receipt_long_outlined, '/audit-logs', 'Governance'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);
    final currentPath = GoRouterState.of(context).uri.path;
    final currentTitle = _navItems
            .where((item) => item.route == currentPath)
            .map((item) => item.title)
            .firstOrNull ??
        'Admin Panel';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.darkNeutral,
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(currentTitle),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: _ConnectionPill(dark: true),
                ),
              ],
            ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContent()),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 264,
              color: AppColors.darkNeutral,
              child: _buildSidebarContent(),
            ),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildTopBar(currentTitle),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    final authState = context.watch<AdminAuthCubit>().state;
    final role = authState is AdminAuthenticated ? authState.role : '';
    final email = authState is AdminAuthenticated ? authState.email : '';
    final currentPath = GoRouterState.of(context).uri.path;
    final visibleItems = _navItems
        .where((item) => AdminPermissions.canViewRoute(role, item.route))
        .toList();
    final sections = visibleItems.map((item) => item.section).toSet();

    return Container(
      color: AppColors.darkNeutral,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Header
          const Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryGold,
                child: Icon(Icons.content_cut_rounded,
                    size: 18, color: AppColors.darkNeutral),
              ),
              SizedBox(width: 12),
              Text(
                'SLOT Admin',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Text(
                      section.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF78716C),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.25,
                      ),
                    ),
                  ),
                  for (final item
                      in visibleItems.where((item) => item.section == section))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Material(
                        color: currentPath == item.route
                            ? AppColors.primaryGold
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          dense: true,
                          minLeadingWidth: 22,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hoverColor: currentPath == item.route
                              ? AppColors.primaryGoldDark
                                  .withValues(alpha: 0.12)
                              : const Color(0xFF292421),
                          leading: Icon(
                            item.icon,
                            color: currentPath == item.route
                                ? AppColors.darkNeutral
                                : const Color(0xFFA8A29E),
                            size: 19,
                          ),
                          title: Text(
                            item.title,
                            style: TextStyle(
                              color: currentPath == item.route
                                  ? AppColors.darkNeutral
                                  : Colors.white70,
                              fontWeight: currentPath == item.route
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          trailing: currentPath == item.route
                              ? const Icon(Icons.chevron_right_rounded,
                                  size: 18)
                              : null,
                          onTap: () {
                            if (!AppBreakpoints.isDesktop(context)) {
                              Navigator.of(context).pop();
                            }
                            context.go(item.route);
                          },
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Log Out button at bottom of sidebar
          const Divider(color: Color(0xFF44403C), height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 2),
                Text(role.replaceAll('_', ' '),
                    style: const TextStyle(
                        color: AppColors.primaryGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            dense: true,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: const Color(0xFF451A1A),
            leading: const Icon(Icons.logout_rounded,
                color: Colors.redAccent, size: 20),
            title: const Text(
              'Sign Out Admin',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign out of Admin Portal?'),
                  content: const Text(
                      'You will need your admin credentials to log back in.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.read<AdminAuthCubit>().logout();
                        context.go('/login');
                      },
                      child: const Text('Sign Out',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(String currentTitle) {
    final authState = context.watch<AdminAuthCubit>().state;
    final email = authState is AdminAuthenticated ? authState.email : '';
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            currentTitle,
            style: const TextStyle(
              color: AppColors.darkNeutral,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right_rounded,
              size: 16, color: AppColors.textMuted),
          const SizedBox(width: 10),
          const Text(
            'SLOT Platform',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const Spacer(),
          const _ConnectionPill(),
          const SizedBox(width: 16),
          Container(width: 1, height: 28, color: AppColors.borderLight),
          const SizedBox(width: 16),
          Tooltip(
            message: email,
            child: const CircleAvatar(
              radius: 17,
              backgroundColor: Color(0xFFFFF1BF),
              child: Icon(Icons.admin_panel_settings_outlined,
                  size: 19, color: AppColors.primaryGoldDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavEntry {
  final String title;
  final IconData icon;
  final String route;
  final String section;
  const _NavEntry(this.title, this.icon, this.route, this.section);
}

class _ConnectionPill extends StatelessWidget {
  final bool dark;
  const _ConnectionPill({this.dark = false});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminSystemHealthCubit, AdminSystemHealthState>(
        builder: (context, state) {
          var label =
              state is AdminSystemHealthLoading ? 'Checking' : 'Signed in';
          var color = AppColors.textMuted;
          if (state is AdminSystemHealthLoaded) {
            final healthy = state.data['status'] == 'HEALTHY';
            label = healthy ? 'Healthy' : 'Degraded';
            color = healthy
                ? AppColors.statusAvailableText
                : Colors.orange.shade700;
          } else if (state is AdminSystemHealthError) {
            label = 'Offline';
            color = AppColors.statusDestructiveText;
          }

          return Tooltip(
            message: 'Platform connection: $label',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: dark ? Colors.white10 : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 7,
                    height: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: dark ? Colors.white : color,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/cubit/admin_auth_cubit.dart';

class AdminLayout extends StatefulWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;

  final List<_NavEntry> _navItems = const [
    _NavEntry('Dashboard', Icons.dashboard_outlined, '/'),
    _NavEntry('Salons', Icons.storefront_rounded, '/salons'),
    _NavEntry('Users', Icons.people_alt_outlined, '/users'),
    _NavEntry('Bookings', Icons.calendar_today_rounded, '/bookings'),
    _NavEntry('Audit Logs', Icons.receipt_long_outlined, '/audit-logs'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.darkNeutral,
              foregroundColor: Colors.white,
              title: const Text('SLOT - Admin Panel'),
            ),
      drawer: isDesktop ? null : Drawer(child: _buildSidebarContent()),
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 240,
              color: AppColors.darkNeutral,
              child: _buildSidebarContent(),
            ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
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
          const SizedBox(height: 32),
          const Text('PLATFORM MANAGEMENT',
              style: TextStyle(
                  color: Color(0xFF78716C),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = index == _selectedIndex;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    tileColor:
                        isSelected ? AppColors.primaryGold : Colors.transparent,
                    leading: Icon(item.icon,
                        color: isSelected
                            ? AppColors.darkNeutral
                            : const Color(0xFFA8A29E),
                        size: 20),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color:
                            isSelected ? AppColors.darkNeutral : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      context.go(item.route);
                    },
                  ),
                );
              },
            ),
          ),

          // Log Out button at bottom of sidebar
          const Divider(color: Color(0xFF44403C), height: 32),
          ListTile(
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
                      'You will need super admin credentials to log back in.'),
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
}

class _NavEntry {
  final String title;
  final IconData icon;
  final String route;
  const _NavEntry(this.title, this.icon, this.route);
}

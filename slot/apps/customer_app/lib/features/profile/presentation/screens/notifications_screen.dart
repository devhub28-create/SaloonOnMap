import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/cubit/auth_cubit.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result =
          await context.read<AuthCubit>().apiClient.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = result
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await context.read<AuthCubit>().apiClient.markAllNotificationsRead();
    if (!mounted) return;
    setState(() {
      for (final item in _notifications) {
        item['is_read'] = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Notifications', style: AppTypography.screenTitle),
        actions: [
          TextButton(
            onPressed: _notifications.isEmpty ? null : _markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('No notifications yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    final read = item['is_read'] == true;
                    final created = DateTime.tryParse(
                      item['created_at']?.toString() ?? '',
                    )?.toLocal();
                    return ListTile(
                      leading: Icon(
                        read
                            ? Icons.notifications_none_rounded
                            : Icons.notifications_active_rounded,
                        color: AppColors.primaryGoldDark,
                      ),
                      title: Text(
                        item['title']?.toString() ?? '',
                        style: TextStyle(
                          fontWeight: read ? FontWeight.w500 : FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(item['body']?.toString() ?? ''),
                      trailing: Text(
                        created == null
                            ? ''
                            : '${created.day}/${created.month}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

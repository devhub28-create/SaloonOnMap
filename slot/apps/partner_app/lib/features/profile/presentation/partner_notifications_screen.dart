import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/partner_api_service.dart';

class PartnerNotificationsScreen extends StatefulWidget {
  const PartnerNotificationsScreen({super.key});

  @override
  State<PartnerNotificationsScreen> createState() =>
      _PartnerNotificationsScreenState();
}

class _PartnerNotificationsScreenState
    extends State<PartnerNotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await PartnerApiService.instance.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = result
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load notifications. Pull down to retry.';
      });
    }
  }

  Future<void> _markAllRead() async {
    try {
      await PartnerApiService.instance.markAllNotificationsRead();
      if (!mounted) return;
      setState(() {
        for (final item in _notifications) {
          item['is_read'] = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not mark notifications as read.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _notifications.any((item) => item['is_read'] != true);
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
            onPressed: hasUnread ? _markAllRead : null,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: Center(child: Text(_error!)),
          ),
        ],
      );
    }
    if (_notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 320,
            child: Center(child: Text('No notifications yet.')),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = _notifications[index];
        final read = item['is_read'] == true;
        final created =
            DateTime.tryParse(item['created_at']?.toString() ?? '')?.toLocal();
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
            created == null ? '' : '${created.day}/${created.month}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        );
      },
    );
  }
}

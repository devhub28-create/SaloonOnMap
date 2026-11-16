import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/admin_ui.dart';
import '../cubit/admin_notifications_cubit.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});
  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _userId = TextEditingController();
  final _deepLink = TextEditingController();
  String _audience = 'CUSTOMERS';

  @override
  void initState() {
    super.initState();
    _title.addListener(_refreshPreview);
    _body.addListener(_refreshPreview);
    _deepLink.addListener(_refreshPreview);
  }

  void _refreshPreview() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _userId.dispose();
    _deepLink.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().length < 2 ||
        _body.text.trim().length < 2 ||
        (_audience == 'USER' && _userId.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Complete the required campaign fields.')));
      return;
    }
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Send notification campaign?'),
                content: Text(
                    'This will create an in-app notification for ${_audience.toLowerCase()} and attempt push delivery.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Send campaign'))
                ]));
    if (confirmed != true || !mounted) return;
    final ok = await context.read<AdminNotificationsCubit>().send({
      'audience': _audience,
      'title': _title.text.trim(),
      'body': _body.text.trim(),
      if (_audience == 'USER') 'userId': _userId.text.trim(),
      if (_deepLink.text.trim().isNotEmpty) 'deepLink': _deepLink.text.trim(),
    });
    if (ok && mounted) {
      _title.clear();
      _body.clear();
      _userId.clear();
      _deepLink.clear();
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminNotificationsCubit, AdminNotificationsState>(
          builder: (context, state) {
        final loaded = state is AdminNotificationsLoaded ? state : null;
        return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              const AdminPageHeader(
                eyebrow: 'Customer & partner engagement',
                title: 'Notification campaigns',
                description:
                    'Send targeted, persistent in-app messages with optional deep links.',
              ),
              const SizedBox(height: AppSpacing.xl),
              if (loaded?.lastResult != null)
                Card(
                    color: Colors.green.shade50,
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                            'Campaign sent to ${loaded!.lastResult!['recipientCount']} recipients; ${loaded.lastResult!['deliveredCount']} push deliveries confirmed.'))),
              LayoutBuilder(builder: (context, constraints) {
                final composer = _campaignComposer(
                    context, state is AdminNotificationsLoading);
                final preview = _campaignPreview(context);
                if (constraints.maxWidth < 900) {
                  return Column(children: [
                    composer,
                    const SizedBox(height: 16),
                    preview,
                  ]);
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: composer),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: preview),
                  ],
                );
              }),
              const SizedBox(height: AppSpacing.xl),
              Row(children: [
                Expanded(
                    child: Text('Recent campaigns',
                        style: Theme.of(context).textTheme.titleLarge)),
                IconButton(
                    onPressed: state is AdminNotificationsLoading
                        ? null
                        : () => context
                            .read<AdminNotificationsCubit>()
                            .fetchCampaigns(),
                    icon: const Icon(Icons.refresh))
              ]),
              if (state is AdminNotificationsLoading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator()))
              else if (state is AdminNotificationsError)
                AdminStatePanel.error(
                    title: 'Campaign history unavailable',
                    message: state.message,
                    onAction: () => context
                        .read<AdminNotificationsCubit>()
                        .fetchCampaigns())
              else if (loaded == null || loaded.campaigns.isEmpty)
                const AdminStatePanel.empty(
                    title: 'No campaigns sent',
                    message:
                        'Your sent campaigns and delivery counts will appear here.')
              else
                ...loaded.campaigns.map((campaign) => Card(
                    child: ListTile(
                        leading: const Icon(Icons.campaign_outlined),
                        title: Text(campaign['title']?.toString() ?? ''),
                        subtitle: Text(
                            '${campaign['audience'] ?? ''} · ${campaign['recipientCount'] ?? 0} recipients\n${campaign['body'] ?? ''}'),
                        isThreeLine: true))),
            ]);
      });

  Widget _campaignComposer(BuildContext context, bool loading) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Compose campaign',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Messages are saved in-app before push is attempted.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _audience,
                decoration: const InputDecoration(labelText: 'Audience'),
                items: const [
                  DropdownMenuItem(
                      value: 'CUSTOMERS', child: Text('All customers')),
                  DropdownMenuItem(
                      value: 'PARTNERS', child: Text('All partners')),
                  DropdownMenuItem(
                      value: 'ALL', child: Text('Customers and partners')),
                  DropdownMenuItem(value: 'USER', child: Text('One user')),
                ],
                onChanged: loading
                    ? null
                    : (value) =>
                        setState(() => _audience = value ?? 'CUSTOMERS'),
              ),
              if (_audience == 'USER') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _userId,
                  decoration: const InputDecoration(labelText: 'User ID'),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                maxLength: 120,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _body,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'Message'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _deepLink,
                decoration: const InputDecoration(
                    labelText: 'App deep link (optional)',
                    hintText: '/bookings or /offers'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: loading ? null : _send,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded),
                label: Text(loading ? 'Sending campaign…' : 'Review and send'),
              ),
            ],
          ),
        ),
      );

  Widget _campaignPreview(BuildContext context) {
    final title =
        _title.text.trim().isEmpty ? 'Your campaign title' : _title.text.trim();
    final body = _body.text.trim().isEmpty
        ? 'Your message preview will update as you type.'
        : _body.text.trim();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.visibility_outlined,
                color: AppColors.primaryGold, size: 19),
            SizedBox(width: 8),
            Text('Live preview',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 5),
          Text(_audience.replaceAll('_', ' ').toLowerCase(),
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: const Color(0xFFFFF2C2),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.content_cut_rounded,
                    color: AppColors.primaryGoldDark, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkNeutral)),
                      const SizedBox(height: 5),
                      Text(body,
                          style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              height: 1.4)),
                      if (_deepLink.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Open ${_deepLink.text.trim()} →',
                            style: const TextStyle(
                                color: AppColors.primaryGoldDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ],
                    ]),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

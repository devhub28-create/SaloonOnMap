import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../../../core/auth/admin_permissions.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../auth/cubit/admin_auth_cubit.dart';
import '../cubit/admin_salons_cubit.dart';

class AdminSalonsScreen extends StatefulWidget {
  const AdminSalonsScreen({super.key});

  @override
  State<AdminSalonsScreen> createState() => _AdminSalonsScreenState();
}

class _AdminSalonsScreenState extends State<AdminSalonsScreen> {
  final _searchController = TextEditingController();
  String _status = 'ALL';
  int _page = 1;

  static const _statuses = [
    'ALL',
    'PENDING_APPROVAL',
    'CHANGES_REQUESTED',
    'ACTIVE',
    'SUSPENDED',
    'REJECTED',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load({int? page}) {
    _page = page ?? 1;
    context.read<AdminSalonsCubit>().fetchSalons(
          search: _searchController.text,
          status: _status,
          page: _page,
        );
  }

  Future<void> _review(Map<String, dynamic> salon, String action) async {
    final requiresReason =
        {'REJECT', 'REQUEST_CHANGES', 'SUSPEND'}.contains(action);
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_actionLabel(action)} ${salon['name'] ?? 'salon'}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_actionDescription(action)),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText:
                    requiresReason ? 'Reason (required)' : 'Note (optional)',
                hintText: 'This is recorded in the audit trail.',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (requiresReason && reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason.')),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: Text(_actionLabel(action)),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true || !mounted) return;

    final success = await context.read<AdminSalonsCubit>().reviewSalon(
          salon['id'].toString(),
          action,
          reason: reason.isEmpty ? null : reason,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '${salon['name'] ?? 'Salon'} updated successfully.'
            : 'Could not update the salon.'),
        backgroundColor: success
            ? AppColors.statusAvailableText
            : AppColors.statusDestructiveText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AdminAuthCubit>().state;
    final role = authState is AdminAuthenticated ? authState.role : '';
    final canManage = AdminPermissions.canManageSalons(role);

    return BlocBuilder<AdminSalonsCubit, AdminSalonsState>(
      builder: (context, state) {
        final loaded = state is AdminSalonsLoadedState ? state : null;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            AdminPageHeader(
              eyebrow: 'Partner network',
              title: 'Salon management',
              description:
                  'Review onboarding, monitor partner status, and keep salon availability accurate for customers.',
              actions: [
                IconButton.filledTonal(
                  onPressed: state is AdminSalonsLoadingState
                      ? null
                      : () => _load(page: _page),
                  tooltip: 'Refresh salons',
                  icon: const Icon(Icons.refresh_rounded),
                )
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildFilters(),
            const SizedBox(height: AppSpacing.lg),
            if (state is AdminSalonsLoadingState)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryGold)),
              )
            else if (state is AdminSalonsErrorState)
              AdminStatePanel.error(
                  title: 'Salons unavailable',
                  message: state.message,
                  onAction: _load)
            else if (loaded == null || loaded.salons.isEmpty)
              const _EmptySalons()
            else ...[
              Text(
                '${loaded.total} salon${loaded.total == 1 ? '' : 's'} found',
                style: const TextStyle(
                    color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.md),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth >= 1050
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth >= 680
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: loaded.salons
                        .map((salon) => SizedBox(
                              width: width,
                              child: _SalonCard(
                                salon: salon,
                                canManage: canManage,
                                onAction: (action) => _review(salon, action),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              _buildPagination(loaded),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _load(),
            decoration: InputDecoration(
              hintText: 'Search name, city, area or address',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: _load,
                tooltip: 'Search',
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: InputDecoration(
              labelText: 'Approval status',
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _statuses
                .map((status) => DropdownMenuItem(
                    value: status, child: Text(_statusLabel(status))))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _status = value);
              _load();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(AdminSalonsLoadedState state) {
    final hasPrevious = state.page > 1;
    final hasNext = state.page * state.limit < state.total;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Page ${state.page}',
            style: const TextStyle(color: AppColors.textMuted)),
        const SizedBox(width: 12),
        IconButton.outlined(
          onPressed: hasPrevious ? () => _load(page: state.page - 1) : null,
          tooltip: 'Previous page',
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          onPressed: hasNext ? () => _load(page: state.page + 1) : null,
          tooltip: 'Next page',
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _SalonCard extends StatelessWidget {
  final Map<String, dynamic> salon;
  final bool canManage;
  final ValueChanged<String> onAction;

  const _SalonCard({
    required this.salon,
    required this.canManage,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final status = salon['approval_status']?.toString() ??
        (salon['is_active'] == true ? 'ACTIVE' : 'PENDING_APPROVAL');
    final actions = _actionsForStatus(status);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.statusInServiceBg,
                  child: Text(
                    (salon['name']?.toString().isNotEmpty == true
                            ? salon['name'].toString()[0]
                            : 'S')
                        .toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.darkNeutral,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(salon['name']?.toString() ?? 'Salon',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 3),
                      Text(
                        [salon['area'], salon['city']]
                            .where(
                                (value) => value?.toString().isNotEmpty == true)
                            .join(', '),
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(salon['address']?.toString() ?? 'Address unavailable',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _Meta(
                    icon: Icons.people_outline,
                    value: salon['target_gender']?.toString() ?? 'UNISEX'),
                _Meta(
                    icon: Icons.schedule_rounded,
                    value:
                        '${salon['opening_time'] ?? '--:--'}–${salon['closing_time'] ?? '--:--'}'),
                _Meta(
                    icon: Icons.star_outline_rounded,
                    value:
                        '${salon['rating'] ?? 0} (${salon['review_count'] ?? 0})'),
              ],
            ),
            if (canManage && actions.isNotEmpty) ...[
              const Divider(height: 32),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actions
                    .map((action) => OutlinedButton(
                          onPressed: () => onAction(action),
                          child: Text(_actionLabel(action)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  final IconData icon;
  final String value;

  const _Meta({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(value,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      );
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      'ACTIVE' => (AppColors.statusAvailableBg, AppColors.statusAvailableText),
      'SUSPENDED' || 'REJECTED' => (
          const Color(0xFFFDE8E8),
          AppColors.statusDestructiveText
        ),
      'CHANGES_REQUESTED' => (
          AppColors.statusInServiceBg,
          AppColors.statusInServiceText
        ),
      _ => (const Color(0xFFFEF9C3), AppColors.statusBookedText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: colors.$1, borderRadius: BorderRadius.circular(999)),
      child: Text(_statusLabel(status),
          style: TextStyle(
              color: colors.$2, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _EmptySalons extends StatelessWidget {
  const _EmptySalons();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.storefront_outlined,
                    size: 40, color: AppColors.textMuted),
                SizedBox(height: AppSpacing.md),
                Text('No salons match these filters.'),
              ],
            ),
          ),
        ),
      );
}

List<String> _actionsForStatus(String status) => switch (status) {
      'PENDING_APPROVAL' || 'CHANGES_REQUESTED' => [
          'APPROVE',
          'REQUEST_CHANGES',
          'REJECT'
        ],
      'ACTIVE' || 'APPROVED' => ['SUSPEND'],
      'SUSPENDED' => ['RESTORE'],
      'REJECTED' => ['APPROVE'],
      _ => const [],
    };

String _statusLabel(String status) => switch (status) {
      'ALL' => 'All statuses',
      'PENDING_APPROVAL' => 'Pending',
      'CHANGES_REQUESTED' => 'Changes requested',
      'ACTIVE' => 'Active',
      'APPROVED' => 'Approved',
      'SUSPENDED' => 'Suspended',
      'REJECTED' => 'Rejected',
      _ => status.replaceAll('_', ' '),
    };

String _actionLabel(String action) => switch (action) {
      'APPROVE' => 'Approve',
      'REJECT' => 'Reject',
      'REQUEST_CHANGES' => 'Request changes',
      'SUSPEND' => 'Suspend',
      'RESTORE' => 'Restore',
      _ => action,
    };

String _actionDescription(String action) => switch (action) {
      'APPROVE' =>
        'The salon will become visible to customers and the partner will gain operational access.',
      'REJECT' =>
        'The application will be rejected and the partner will remain unable to operate the salon.',
      'REQUEST_CHANGES' =>
        'The partner must correct their salon information before it can be approved.',
      'SUSPEND' =>
        'The salon will be hidden from customers and partner access will be disabled immediately.',
      'RESTORE' =>
        'The salon will become visible to customers and partner access will be restored.',
      _ => 'This action will be recorded in the audit trail.',
    };

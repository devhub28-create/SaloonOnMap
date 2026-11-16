import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../../../core/auth/admin_permissions.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../auth/cubit/admin_auth_cubit.dart';
import '../cubit/admin_bookings_cubit.dart';

class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  final _search = TextEditingController();
  String _status = 'ALL';
  int _page = 1;

  static const _statuses = [
    'ALL',
    'CONFIRMED',
    'WAITING',
    'IN_SERVICE',
    'DONE',
    'CANCELLED'
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load({int? page}) {
    _page = page ?? 1;
    context.read<AdminBookingsCubit>().fetchBookings(
          search: _search.text,
          status: _status,
          page: _page,
        );
  }

  Future<void> _changeStatus(
      Map<String, dynamic> booking, String target) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Change booking to ${_label(target)}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${booking['referenceCode'] ?? ''} · '
                '${booking['customerName'] ?? 'Customer'}'),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: reason,
              maxLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Reason (required)',
                hintText:
                    'Recorded in booking history and the admin audit log.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (reason.text.trim().isEmpty) return;
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Confirm change'),
          ),
        ],
      ),
    );
    final note = reason.text.trim();
    reason.dispose();
    if (confirmed != true || !mounted) return;
    await context
        .read<AdminBookingsCubit>()
        .updateStatus(booking['id'].toString(), target, note);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AdminAuthCubit>().state;
    final role = authState is AdminAuthenticated ? authState.role : '';
    final canManage = AdminPermissions.canManageBookings(role);
    return BlocBuilder<AdminBookingsCubit, AdminBookingsState>(
      builder: (context, state) {
        final loaded = state is AdminBookingsLoaded ? state : null;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            AdminPageHeader(
              eyebrow: 'Live operations',
              title: 'Booking management',
              description:
                  'Track the booking lifecycle across salons and intervene with an auditable status change when needed.',
              actions: [
                IconButton.filledTonal(
                  onPressed: state is AdminBookingsLoading
                      ? null
                      : () => _load(page: _page),
                  tooltip: 'Refresh bookings',
                  icon: const Icon(Icons.refresh_rounded),
                )
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 680;
              final search = TextField(
                controller: _search,
                onSubmitted: (_) => _load(),
                decoration: InputDecoration(
                  labelText: 'Search reference, customer, phone or salon',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    onPressed: _load,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                  border: const OutlineInputBorder(),
                ),
              );
              final filter = DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: _statuses
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(_label(value)),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _status = value);
                  _load();
                },
              );
              if (compact) {
                return Column(children: [
                  search,
                  const SizedBox(height: 12),
                  filter,
                ]);
              }
              return Row(children: [
                Expanded(flex: 3, child: search),
                const SizedBox(width: 12),
                Expanded(child: filter),
              ]);
            }),
            const SizedBox(height: AppSpacing.lg),
            if (state is AdminBookingsLoading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryGold)),
              )
            else if (state is AdminBookingsError)
              AdminStatePanel.error(
                  title: 'Bookings unavailable',
                  message: state.message,
                  onAction: _load)
            else if (loaded == null || loaded.bookings.isEmpty)
              const AdminStatePanel.empty(
                title: 'No bookings found',
                message: 'Try a different status or search term.',
              )
            else ...[
              Text('${loaded.total} booking${loaded.total == 1 ? '' : 's'}'),
              const SizedBox(height: AppSpacing.md),
              ...loaded.bookings.map((booking) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _BookingCard(
                      booking: booking,
                      canManage: canManage,
                      onStatus: (status) => _changeStatus(booking, status),
                    ),
                  )),
              _Pagination(
                page: loaded.page,
                hasNext: loaded.page * loaded.limit < loaded.total,
                onPage: (page) => _load(page: page),
              ),
            ],
          ],
        );
      },
    );
  }

  static String _label(String value) => value
      .split('_')
      .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool canManage;
  final ValueChanged<String> onStatus;

  const _BookingCard({
    required this.booking,
    required this.canManage,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final status = booking['status']?.toString() ?? '';
    final start =
        DateTime.tryParse(booking['startAt']?.toString() ?? '')?.toLocal();
    final date = start == null
        ? 'Time unavailable'
        : '${start.day}/${start.month}/${start.year} · '
            '${start.hour.toString().padLeft(2, '0')}:'
            '${start.minute.toString().padLeft(2, '0')}';
    final actions = _allowedTargets(status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Wrap(
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${booking['referenceCode'] ?? ''} · '
                    '${booking['customerName'] ?? 'Customer'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text('${booking['salonName'] ?? 'Unknown salon'} · $date'),
                  const SizedBox(height: 4),
                  Text(booking['serviceName']?.toString().isNotEmpty == true
                      ? booking['serviceName'].toString()
                      : 'Service not recorded'),
                  const SizedBox(height: 4),
                  Text('₹${booking['totalAmount'] ?? 0} · '
                      '${booking['paymentStatus'] ?? 'Payment status unavailable'}'),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(label: Text(_AdminBookingsScreenState._label(status))),
                if (canManage && actions.isNotEmpty)
                  PopupMenuButton<String>(
                    tooltip: 'Change booking status',
                    onSelected: onStatus,
                    itemBuilder: (_) => actions
                        .map((value) => PopupMenuItem(
                              value: value,
                              child: Text('Move to '
                                  '${_AdminBookingsScreenState._label(value)}'),
                            ))
                        .toList(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('Update status'),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down_rounded),
                      ]),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static List<String> _allowedTargets(String status) {
    switch (status) {
      case 'CONFIRMED':
        return ['WAITING', 'IN_SERVICE', 'DONE', 'CANCELLED'];
      case 'WAITING':
        return ['IN_SERVICE', 'DONE', 'CANCELLED'];
      case 'IN_SERVICE':
        return ['DONE', 'CANCELLED'];
      default:
        return const [];
    }
  }
}

class _Pagination extends StatelessWidget {
  final int page;
  final bool hasNext;
  final ValueChanged<int> onPage;

  const _Pagination({
    required this.page,
    required this.hasNext,
    required this.onPage,
  });

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: page > 1 ? () => onPage(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('Page $page'),
          IconButton(
            onPressed: hasNext ? () => onPage(page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      );
}

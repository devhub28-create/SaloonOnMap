import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/auth/admin_permissions.dart';
import '../../../core/widgets/admin_ui.dart';
import '../../auth/cubit/admin_auth_cubit.dart';
import '../cubit/admin_reviews_cubit.dart';

class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});
  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  final _search = TextEditingController();
  String _status = 'ALL';
  int _page = 1;
  static const _statuses = ['ALL', 'PUBLISHED', 'FLAGGED', 'HIDDEN'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load({int? page}) {
    _page = page ?? 1;
    context
        .read<AdminReviewsCubit>()
        .fetchReviews(search: _search.text, status: _status, page: _page);
  }

  Future<void> _moderate(Map<String, dynamic> review, String target) async {
    final reason = TextEditingController();
    final requiresReason = target != 'PUBLISHED';
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
                title: Text('${_label(target)} this review?'),
                content: TextField(
                    controller: reason,
                    maxLines: 3,
                    decoration: InputDecoration(
                        labelText: requiresReason
                            ? 'Reason (required)'
                            : 'Note (optional)',
                        border: const OutlineInputBorder())),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () {
                        if (requiresReason && reason.text.trim().isEmpty) {
                          return;
                        }
                        Navigator.pop(dialogContext, true);
                      },
                      child: Text(_label(target))),
                ]));
    final note = reason.text.trim();
    reason.dispose();
    if (confirmed != true || !mounted) {
      return;
    }
    await context
        .read<AdminReviewsCubit>()
        .moderate(review['id'].toString(), target, reason: note);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthCubit>().state;
    final canModerate = AdminPermissions.canModerateReviews(
        auth is AdminAuthenticated ? auth.role : '');
    return BlocBuilder<AdminReviewsCubit, AdminReviewsState>(
        builder: (context, state) {
      final loaded = state is AdminReviewsLoaded ? state : null;
      return ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
        AdminPageHeader(
          eyebrow: 'Trust & safety',
          title: 'Review moderation',
          description:
              'Protect marketplace quality while preserving authentic customer feedback.',
          actions: [
            IconButton.filledTonal(
                onPressed: state is AdminReviewsLoading
                    ? null
                    : () => _load(page: _page),
                tooltip: 'Refresh reviews',
                icon: const Icon(Icons.refresh_rounded))
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(builder: (context, constraints) {
          final search = TextField(
              controller: _search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                  labelText: 'Search customer, salon, booking or comment',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                      onPressed: _load,
                      icon: const Icon(Icons.arrow_forward))));
          final filter = DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                  labelText: 'Moderation state', border: OutlineInputBorder()),
              items: _statuses
                  .map(
                      (s) => DropdownMenuItem(value: s, child: Text(_label(s))))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                  _load();
                }
              });
          return constraints.maxWidth < 680
              ? Column(children: [search, const SizedBox(height: 12), filter])
              : Row(children: [
                  Expanded(flex: 3, child: search),
                  const SizedBox(width: 12),
                  Expanded(child: filter)
                ]);
        }),
        const SizedBox(height: AppSpacing.lg),
        if (state is AdminReviewsLoading)
          const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primaryGold)))
        else if (state is AdminReviewsError)
          AdminStatePanel.error(
              title: 'Reviews unavailable',
              message: state.message,
              onAction: _load)
        else if (loaded == null || loaded.reviews.isEmpty)
          const AdminStatePanel.empty(
              title: 'No reviews found',
              message: 'Try a different moderation state or search term.')
        else ...[
          Text('${loaded.total} review${loaded.total == 1 ? '' : 's'}'),
          const SizedBox(height: 12),
          ...loaded.reviews.map((review) => _ReviewCard(
              review: review, canModerate: canModerate, onModerate: _moderate)),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
                onPressed:
                    loaded.page > 1 ? () => _load(page: loaded.page - 1) : null,
                icon: const Icon(Icons.chevron_left)),
            Text('Page ${loaded.page}'),
            IconButton(
                onPressed: loaded.page * loaded.limit < loaded.total
                    ? () => _load(page: loaded.page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right)),
          ]),
        ],
      ]);
    });
  }

  static String _label(String value) => value
      .split('_')
      .map((part) => '${part[0]}${part.substring(1).toLowerCase()}')
      .join(' ');
}

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final bool canModerate;
  final Future<void> Function(Map<String, dynamic>, String) onModerate;
  const _ReviewCard(
      {required this.review,
      required this.canModerate,
      required this.onModerate});
  @override
  Widget build(BuildContext context) {
    final status = review['moderation_status']?.toString() ?? 'PUBLISHED';
    final salon = review['salon'] as Map?;
    final booking = review['booking'] as Map?;
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(
                        '${review['customer_name'] ?? 'Customer'} · ${salon?['name'] ?? 'Salon'}',
                        style: Theme.of(context).textTheme.titleMedium)),
                Chip(label: Text(_AdminReviewsScreenState._label(status))),
              ]),
              Text(
                  '${'★' * ((review['rating'] as num?)?.toInt() ?? 0)} · ${booking?['reference_code'] ?? ''}'),
              const SizedBox(height: 8),
              Text(review['comment']?.toString().isNotEmpty == true
                  ? review['comment'].toString()
                  : 'No written comment'),
              if (review['moderation_reason']?.toString().isNotEmpty ==
                  true) ...[
                const SizedBox(height: 8),
                Text('Moderation note: ${review['moderation_reason']}'),
              ],
              if (canModerate) ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: [
                  if (status != 'PUBLISHED')
                    OutlinedButton(
                        onPressed: () => onModerate(review, 'PUBLISHED'),
                        child: const Text('Publish')),
                  if (status != 'FLAGGED')
                    OutlinedButton(
                        onPressed: () => onModerate(review, 'FLAGGED'),
                        child: const Text('Flag')),
                  if (status != 'HIDDEN')
                    FilledButton(
                        onPressed: () => onModerate(review, 'HIDDEN'),
                        child: const Text('Hide')),
                ]),
              ],
            ])));
  }
}

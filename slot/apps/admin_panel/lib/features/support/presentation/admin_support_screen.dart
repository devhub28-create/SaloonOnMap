import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/admin_ui.dart';
import '../cubit/admin_support_cubit.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});
  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final _search = TextEditingController();
  String _status = 'ALL';
  String _priority = 'ALL';
  int _page = 1;
  static const statuses = [
    'ALL',
    'OPEN',
    'IN_PROGRESS',
    'WAITING_FOR_USER',
    'RESOLVED',
    'CLOSED'
  ];
  static const priorities = ['ALL', 'URGENT', 'HIGH', 'MEDIUM', 'LOW'];
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load({int? page}) {
    _page = page ?? 1;
    context.read<AdminSupportCubit>().fetch(
        search: _search.text,
        status: _status,
        priority: _priority,
        page: _page);
  }

  Future<void> _reply(Map<String, dynamic> ticket) async {
    final controller = TextEditingController();
    bool internal = false;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                    title: Text('Reply to ${ticket['subject']}'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: controller,
                          maxLines: 5,
                          decoration: const InputDecoration(
                              labelText: 'Message',
                              border: OutlineInputBorder())),
                      CheckboxListTile(
                          value: internal,
                          onChanged: (v) =>
                              setDialogState(() => internal = v ?? false),
                          title: const Text(
                              'Internal note (hidden from requester)'),
                          contentPadding: EdgeInsets.zero),
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(
                              context, controller.text.trim().length >= 2),
                          child: const Text('Send'))
                    ])));
    final message = controller.text.trim();
    controller.dispose();
    if (confirmed == true && mounted) {
      await context
          .read<AdminSupportCubit>()
          .reply(ticket['id'].toString(), message, internal: internal);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminSupportCubit, AdminSupportState>(
          builder: (context, state) {
        final loaded = state is AdminSupportLoaded ? state : null;
        return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              AdminPageHeader(
                eyebrow: 'Customer & partner care',
                title: 'Support desk',
                description:
                    'Triage requests, collaborate with internal notes, and keep customers and salons informed.',
                actions: [
                  IconButton.filledTonal(
                      onPressed: state is AdminSupportLoading
                          ? null
                          : () => _load(page: _page),
                      tooltip: 'Refresh support queue',
                      icon: const Icon(Icons.refresh))
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(builder: (context, constraints) {
                final fields = [
                  Expanded(
                      flex: 3,
                      child: TextField(
                          controller: _search,
                          onSubmitted: (_) => _load(),
                          decoration: const InputDecoration(
                              labelText:
                                  'Search subject, requester, phone or booking',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder()))),
                  Expanded(
                      child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder()),
                          items: statuses
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.replaceAll('_', ' '))))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _status = v ?? 'ALL');
                            _load();
                          })),
                  Expanded(
                      child: DropdownButtonFormField<String>(
                          initialValue: _priority,
                          decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder()),
                          items: priorities
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) {
                            setState(() => _priority = v ?? 'ALL');
                            _load();
                          }))
                ];
                return constraints.maxWidth < 800
                    ? Column(
                        children: fields
                            .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: SizedBox(
                                    width: double.infinity, child: e.child)))
                            .toList())
                    : Row(children: [
                        fields[0],
                        const SizedBox(width: 10),
                        fields[1],
                        const SizedBox(width: 10),
                        fields[2]
                      ]);
              }),
              const SizedBox(height: 16),
              if (state is AdminSupportLoading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator()))
              else if (state is AdminSupportError)
                AdminStatePanel.error(
                    title: 'Support queue unavailable',
                    message: state.message,
                    onAction: _load)
              else if (loaded == null || loaded.tickets.isEmpty)
                const AdminStatePanel.empty(
                    title: 'No support tickets found',
                    message:
                        'The queue is clear, or no tickets match the current filters.')
              else ...[
                Text('${loaded.total} tickets'),
                const SizedBox(height: 10),
                ...loaded.tickets.map((ticket) => _TicketCard(
                    ticket: ticket,
                    onReply: () => _reply(ticket),
                    onStatus: (value) => context
                        .read<AdminSupportCubit>()
                        .setStatus(ticket['id'].toString(), value))),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  IconButton(
                      onPressed: loaded.page > 1
                          ? () => _load(page: loaded.page - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left)),
                  Text('Page ${loaded.page}'),
                  IconButton(
                      onPressed: loaded.page * loaded.limit < loaded.total
                          ? () => _load(page: loaded.page + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right))
                ]),
              ],
            ]);
      });
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;
  final VoidCallback onReply;
  final ValueChanged<String> onStatus;
  const _TicketCard(
      {required this.ticket, required this.onReply, required this.onStatus});
  @override
  Widget build(BuildContext context) {
    final requester = ticket['requester'] as Map?;
    final salon = ticket['salon'] as Map?;
    final messages = ticket['messages'] as List<dynamic>? ?? const [];
    return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ExpansionTile(
            leading: CircleAvatar(
                child: Text(
                    ticket['priority']?.toString().substring(0, 1) ?? 'M')),
            title: Text(ticket['subject']?.toString() ?? ''),
            subtitle: Text(
                '${requester?['name'] ?? requester?['phone'] ?? 'Requester'} · ${salon?['name'] ?? ticket['requester_role']} · ${ticket['status']}'),
            trailing: PopupMenuButton<String>(
                onSelected: onStatus,
                itemBuilder: (_) => _AdminSupportScreenState.statuses
                    .skip(1)
                    .map((s) => PopupMenuItem(
                        value: s, child: Text(s.replaceAll('_', ' '))))
                    .toList()),
            children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...messages.map((raw) {
                          final item = Map<String, dynamic>.from(raw as Map);
                          return Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              color: item['internal_note'] == true
                                  ? Colors.amber.shade50
                                  : Colors.grey.shade100,
                              child: Text(
                                  '${item['sender_role']}${item['internal_note'] == true ? ' · INTERNAL' : ''}\n${item['message']}'));
                        }),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                            onPressed: onReply,
                            icon: const Icon(Icons.reply),
                            label: const Text('Reply or add note')),
                      ]))
            ]));
  }
}

import 'dart:convert';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/admin_ui.dart';
import '../cubit/admin_audit_logs_cubit.dart';

class AdminAuditLogsScreen extends StatefulWidget {
  const AdminAuditLogsScreen({super.key});
  @override
  State<AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<AdminAuditLogsScreen> {
  final _search = TextEditingController();
  String _action = 'ALL';
  String _entityType = 'ALL';
  int _page = 1;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _load({int? page}) {
    _page = page ?? 1;
    context.read<AdminAuditLogsCubit>().fetchLogs(
        search: _search.text,
        action: _action,
        entityType: _entityType,
        page: _page);
  }

  void _details(Map<String, dynamic> log) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: Text(log['action']?.toString() ?? 'Audit event'),
              content: SizedBox(
                  width: 620,
                  child: SingleChildScrollView(
                      child: SelectableText(
                          const JsonEncoder.withIndent('  ').convert({
                    'eventId': log['id'],
                    'timestamp': log['created_at'],
                    'actorId': log['actor_id'],
                    'actorRole': log['actor_role'],
                    'entityType': log['entity_type'],
                    'entityId': log['entity_id'],
                    'requestId': log['request_id'],
                    'ipAddress': log['ip_address'],
                    'before': log['before_value'],
                    'after': log['after_value'],
                  })))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ]));
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminAuditLogsCubit, AdminAuditLogsState>(
          builder: (context, state) {
        final loaded = state is AdminAuditLogsLoaded ? state : null;
        return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              AdminPageHeader(
                eyebrow: 'System audit trail',
                title: 'Audit logs',
                description:
                    'Inspect sensitive platform changes with actor, entity, request, and before/after context.',
                actions: [
                  IconButton.filledTonal(
                      onPressed: state is AdminAuditLogsLoading
                          ? null
                          : () => _load(page: _page),
                      tooltip: 'Refresh audit logs',
                      icon: const Icon(Icons.refresh))
                ],
              ),
              const SizedBox(height: 20),
              LayoutBuilder(builder: (context, constraints) {
                final search = TextField(
                    controller: _search,
                    onSubmitted: (_) => _load(),
                    decoration: InputDecoration(
                        labelText: 'Search action, actor, entity or request ID',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                            onPressed: _load,
                            icon: const Icon(Icons.arrow_forward)),
                        border: const OutlineInputBorder()));
                final actions = <String>{'ALL', ...?loaded?.actions}.toList();
                final entities =
                    <String>{'ALL', ...?loaded?.entityTypes}.toList();
                if (!actions.contains(_action)) _action = 'ALL';
                if (!entities.contains(_entityType)) _entityType = 'ALL';
                final action = DropdownButtonFormField<String>(
                    initialValue: _action,
                    decoration: const InputDecoration(
                        labelText: 'Action', border: OutlineInputBorder()),
                    items: actions
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _action = v ?? 'ALL');
                      _load();
                    });
                final entity = DropdownButtonFormField<String>(
                    initialValue: _entityType,
                    decoration: const InputDecoration(
                        labelText: 'Entity', border: OutlineInputBorder()),
                    items: entities
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) {
                      setState(() => _entityType = v ?? 'ALL');
                      _load();
                    });
                return constraints.maxWidth < 800
                    ? Column(children: [
                        search,
                        const SizedBox(height: 10),
                        action,
                        const SizedBox(height: 10),
                        entity
                      ])
                    : Row(children: [
                        Expanded(flex: 3, child: search),
                        const SizedBox(width: 10),
                        Expanded(child: action),
                        const SizedBox(width: 10),
                        Expanded(child: entity)
                      ]);
              }),
              const SizedBox(height: 16),
              if (state is AdminAuditLogsLoading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(48),
                        child: CircularProgressIndicator()))
              else if (state is AdminAuditLogsError)
                AdminStatePanel.error(
                    title: 'Audit logs unavailable',
                    message: state.message,
                    onAction: _load)
              else if (loaded == null || loaded.logs.isEmpty)
                const AdminStatePanel.empty(
                    title: 'No audit events found',
                    message: 'Try a different action, entity, or search term.')
              else ...[
                ...loaded.logs.map((log) {
                  final time =
                      DateTime.tryParse(log['created_at']?.toString() ?? '')
                          ?.toLocal();
                  return Card(
                      child: ListTile(
                          onTap: () => _details(log),
                          leading: const Icon(Icons.policy_outlined),
                          title: Text(log['action']?.toString() ?? 'EVENT'),
                          subtitle: Text(
                              '${log['actor_role'] ?? 'SYSTEM'} · ${log['entity_type'] ?? ''} · ${log['entity_id'] ?? ''}'),
                          trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(time?.toString().substring(0, 16) ?? ''),
                                const Text('View details',
                                    style: TextStyle(fontSize: 11))
                              ])));
                }),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  IconButton(
                      onPressed: loaded.page > 1
                          ? () => _load(page: loaded.page - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left)),
                  Text('${loaded.total} events · Page ${loaded.page}'),
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

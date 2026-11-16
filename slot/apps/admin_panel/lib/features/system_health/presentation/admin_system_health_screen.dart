import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/admin_ui.dart';
import '../cubit/admin_system_health_cubit.dart';

class AdminSystemHealthScreen extends StatelessWidget {
  const AdminSystemHealthScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminSystemHealthCubit, AdminSystemHealthState>(
          builder: (context, state) {
        if (state is AdminSystemHealthLoading ||
            state is AdminSystemHealthInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminSystemHealthError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AdminStatePanel.error(
              title: 'Health status unavailable',
              message: state.message,
              onAction: () => context.read<AdminSystemHealthCubit>().fetch(),
            ),
          );
        }
        final data = (state as AdminSystemHealthLoaded).data;
        final dependencies =
            Map<String, dynamic>.from(data['dependencies'] as Map? ?? {});
        final database =
            Map<String, dynamic>.from(dependencies['database'] as Map? ?? {});
        final signals =
            Map<String, dynamic>.from(data['signals'] as Map? ?? {});
        final release =
            Map<String, dynamic>.from(data['release'] as Map? ?? {});
        final healthy = data['status'] == 'HEALTHY';
        return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              AdminPageHeader(
                eyebrow: 'Platform reliability',
                title: 'System health',
                description:
                    'Monitor infrastructure readiness and operational warning signals.',
                actions: [
                  IconButton.filledTonal(
                      onPressed: () =>
                          context.read<AdminSystemHealthCubit>().fetch(),
                      tooltip: 'Refresh health check',
                      icon: const Icon(Icons.refresh))
                ],
              ),
              const SizedBox(height: 20),
              Card(
                  color: healthy ? Colors.green.shade50 : Colors.orange.shade50,
                  child: ListTile(
                      leading: Icon(
                          healthy
                              ? Icons.check_circle
                              : Icons.warning_amber_rounded,
                          color: healthy ? Colors.green : Colors.orange),
                      title: Text('Platform ${data['status']}'),
                      subtitle: Text(
                          'Checked ${data['checkedAt']} · Uptime ${data['uptimeSeconds']} seconds'))),
              const SizedBox(height: 16),
              Wrap(spacing: 12, runSpacing: 12, children: [
                _statusCard(
                    context,
                    'Database',
                    database['healthy'] == true ? 'Healthy' : 'Unavailable',
                    '${database['latencyMs'] ?? 0} ms',
                    database['healthy'] == true),
                _statusCard(
                    context,
                    'Migrations',
                    database['pendingMigrations'] == true
                        ? 'Pending'
                        : 'Current',
                    database['pendingMigrations'] == true
                        ? 'Deployment action required'
                        : 'Schema is current',
                    database['pendingMigrations'] != true),
                _statusCard(
                    context,
                    'Redis',
                    dependencies['redisConfigured'] == true
                        ? 'Configured'
                        : 'In-memory fallback',
                    dependencies['redisConfigured'] == true
                        ? 'OTP shared storage enabled'
                        : 'Not suitable for multi-instance production',
                    dependencies['redisConfigured'] == true),
                _statusCard(
                    context,
                    'AI inference',
                    dependencies['aiInferenceConfigured'] == true
                        ? 'Configured'
                        : 'Not configured',
                    'Use AI Operations for live health',
                    dependencies['aiInferenceConfigured'] == true),
              ]),
              const SizedBox(height: 24),
              Text('Operational signals',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: signals.entries
                      .map((entry) => SizedBox(
                          width: 220,
                          child: Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(_label(entry.key)),
                                        const SizedBox(height: 6),
                                        Text('${entry.value}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium)
                                      ])))))
                      .toList()),
              const SizedBox(height: 24),
              Text('Release', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Card(
                  child: ListTile(
                      leading: const Icon(Icons.cloud_done_outlined),
                      title: Text(
                          '${release['version']} · ${release['environment']}'),
                      subtitle: Text('Commit ${release['commit']}'))),
            ]);
      });
  static Widget _statusCard(BuildContext context, String title, String status,
          String detail, bool good) =>
      SizedBox(
          width: 250,
          child: Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                            good
                                ? Icons.check_circle_outline
                                : Icons.error_outline,
                            color: good ? Colors.green : Colors.orange),
                        const SizedBox(height: 10),
                        Text(title),
                        Text(status,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(detail)
                      ]))));
  static String _label(String value) => value
      .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
      .trim();
}

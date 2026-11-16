import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/admin_ui.dart';
import '../cubit/admin_ai_operations_cubit.dart';

class AdminAiOperationsScreen extends StatelessWidget {
  const AdminAiOperationsScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AdminAiOperationsCubit, AdminAiOperationsState>(
          builder: (context, state) {
        if (state is AdminAiOperationsLoading ||
            state is AdminAiOperationsInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is AdminAiOperationsError) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: AdminStatePanel.error(
              title: 'AI operations unavailable',
              message: state.message,
              onAction: () =>
                  context.read<AdminAiOperationsCubit>().fetchOperations(),
            ),
          );
        }
        final data = (state as AdminAiOperationsLoaded).data;
        final health =
            Map<String, dynamic>.from(data['inferenceHealth'] as Map? ?? {});
        final counts = Map<String, dynamic>.from(data['counts'] as Map? ?? {});
        final jobs = (data['recentJobs'] as List<dynamic>? ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        return ListView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            children: [
              AdminPageHeader(
                eyebrow: 'AI style studio',
                title: 'AI operations',
                description:
                    'Monitor inference availability, generation throughput, and customer job failures.',
                actions: [
                  IconButton.filledTonal(
                      onPressed: () => context
                          .read<AdminAiOperationsCubit>()
                          .fetchOperations(),
                      tooltip: 'Refresh AI operations',
                      icon: const Icon(Icons.refresh))
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Card(
                  color: health['available'] == true
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  child: ListTile(
                      leading: Icon(
                          health['available'] == true
                              ? Icons.check_circle
                              : Icons.error,
                          color: health['available'] == true
                              ? Colors.green
                              : Colors.red),
                      title: Text(health['available'] == true
                          ? 'Inference service available'
                          : 'Inference service unavailable'),
                      subtitle: health['available'] == true
                          ? const Text(
                              'Customer generation requests can be processed.')
                          : Text(health['error']?.toString() ??
                              'Health check failed.'))),
              const SizedBox(height: 16),
              Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: counts.entries
                      .map((entry) => SizedBox(
                          width: 180,
                          child: Card(
                              child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(entry.key.replaceAll('_', ' ')),
                                        const SizedBox(height: 6),
                                        Text('${entry.value}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium)
                                      ])))))
                      .toList()),
              const SizedBox(height: AppSpacing.xl),
              Text('Recent customer jobs',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (jobs.isEmpty)
                const AdminStatePanel.empty(
                    title: 'No generation jobs',
                    message: 'Customer AI style jobs will appear here.')
              else
                ...jobs.map((job) => Card(
                    child: ListTile(
                        leading: const Icon(Icons.auto_awesome),
                        title:
                            Text('${job['customerName']} · ${job['status']}'),
                        subtitle: Text(
                            '${job['progressStage'] ?? ''} · ${job['completedVariations'] ?? 0}/${job['variationsCount'] ?? 0} variations${job['errorMessage'] == null ? '' : '\n${job['errorMessage']}'}')))),
            ]);
      });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../cubit/admin_audit_logs_cubit.dart';

class AdminAuditLogsScreen extends StatelessWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminAuditLogsCubit, AdminAuditLogsState>(
      builder: (context, state) {
        if (state is AdminAuditLogsLoading || state is AdminAuditLogsInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold));
        }
        if (state is AdminAuditLogsError) {
          return Center(child: Text(state.message));
        }
        final logs = state is AdminAuditLogsLoaded
            ? state.logs
            : <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const Text('SYSTEM AUDIT TRAIL',
                style: AppTypography.sectionEyebrow),
            const SizedBox(height: 4),
            const Text('Audit Logs', style: AppTypography.screenTitle),
            const SizedBox(height: AppSpacing.xl),
            if (logs.isEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No audit events recorded.')))
            else
              ...logs.map((log) {
                final timestamp =
                    DateTime.tryParse(log['created_at']?.toString() ?? '')
                        ?.toLocal();
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                  title: Text(log['action']?.toString() ?? 'EVENT',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '${log['actor_role'] ?? 'SYSTEM'} · ${log['entity_type'] ?? ''} ${log['entity_id'] ?? ''}'),
                  trailing: Text(timestamp?.toString().substring(0, 16) ?? '',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textMuted)),
                );
              }),
          ],
        );
      },
    );
  }
}

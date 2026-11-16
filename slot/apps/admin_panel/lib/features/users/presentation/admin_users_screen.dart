import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../cubit/admin_users_cubit.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminUsersCubit, AdminUsersState>(
      builder: (context, state) {
        if (state is AdminUsersLoading || state is AdminUsersInitial) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold));
        }
        if (state is AdminUsersError) return Center(child: Text(state.message));
        final users =
            state is AdminUsersLoaded ? state.users : <Map<String, dynamic>>[];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PLATFORM USERS & ROLES',
                  style: AppTypography.sectionEyebrow),
              const SizedBox(height: 4),
              const Text('User Management', style: AppTypography.screenTitle),
              const SizedBox(height: AppSpacing.xl),
              if (users.isEmpty)
                const Center(child: Text('No users found.'))
              else
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.borderLight)),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Contact')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('State')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: users.map((user) {
                      final active = user['is_active'] == true;
                      final email = user['email']?.toString() ?? '';
                      return DataRow(cells: [
                        DataCell(Text(user['name']?.toString() ?? 'User')),
                        DataCell(Text(email.isNotEmpty
                            ? email
                            : user['phone']?.toString() ?? '')),
                        DataCell(Text(user['role']?.toString() ?? '')),
                        DataCell(Text(active ? 'Active' : 'Blocked')),
                        DataCell(OutlinedButton(
                          onPressed: () => context
                              .read<AdminUsersCubit>()
                              .setActive(user['id'].toString(), !active),
                          child: Text(active ? 'Block' : 'Unblock'),
                        )),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

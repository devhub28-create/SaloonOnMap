import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../cubit/admin_salons_cubit.dart';

class AdminSalonsScreen extends StatelessWidget {
  const AdminSalonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminSalonsCubit, AdminSalonsState>(
      builder: (context, state) {
        if (state is AdminSalonsLoadingState) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold));
        }

        final pendingSalons =
            state is AdminSalonsLoadedState ? state.pendingSalons : [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SALON ONBOARDING & APPROVALS',
                  style: AppTypography.sectionEyebrow),
              const SizedBox(height: 4),
              const Text('Salon Management', style: AppTypography.screenTitle),
              const SizedBox(height: AppSpacing.xl),

              // Table Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: pendingSalons.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                            child: Text('No salons currently pending approval.',
                                style: TextStyle(color: AppColors.textMuted))),
                      )
                    : DataTable(
                        columns: const [
                          DataColumn(
                              label: Text('Salon Name',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Location',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Status',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(
                              label: Text('Actions',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: pendingSalons.map((s) {
                          final salonId = s['id'] ?? '';
                          final name = s['name'] ?? 'Salon';
                          final address = s['address'] ?? 'Indiranagar';
                          final isActive = s['is_active'] ?? false;
                          final status =
                              isActive ? 'Approved' : 'Pending Approval';

                          return DataRow(
                            cells: [
                              DataCell(Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                              DataCell(Text(address)),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.statusAvailableBg
                                        : const Color(0xFFFEF9C3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? AppColors.statusAvailableText
                                          : AppColors.statusBookedText,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.check_circle_outline,
                                          color: AppColors.statusAvailableText),
                                      tooltip: 'Approve',
                                      onPressed: () {
                                        context
                                            .read<AdminSalonsCubit>()
                                            .reviewSalon(salonId, 'APPROVE');
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined,
                                          color: Colors.red),
                                      tooltip: 'Reject',
                                      onPressed: () {
                                        context
                                            .read<AdminSalonsCubit>()
                                            .reviewSalon(salonId, 'REJECT');
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
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

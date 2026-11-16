import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../cubit/partner_team_cubit.dart';

class StaffMemberModel {
  final String id;
  final String initials;
  final String name;
  final String role;
  String status;
  final int jobCountToday;

  StaffMemberModel({
    required this.id,
    required this.initials,
    required this.name,
    required this.role,
    this.status = 'Available',
    this.jobCountToday = 0,
  });
}

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  void _showAddStaffModal(BuildContext context) {
    final nameController = TextEditingController();
    final roleController = TextEditingController(text: 'Stylist');
    String selectedStatus = 'Available';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Staff Member', style: AppTypography.screenTitle),
              const SizedBox(height: 16),
              const Text('STAFF FULL NAME',
                  style: AppTypography.sectionEyebrow),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                decoration: InputDecoration(
                  hintText: 'e.g. Rahul Verma',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('ROLE & SPECIALTY',
                  style: AppTypography.sectionEyebrow),
              const SizedBox(height: 6),
              TextField(
                controller: roleController,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                decoration: InputDecoration(
                  hintText: 'e.g. Master Stylist / Barber',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              SlotPrimaryButton(
                text: 'Add to Salon Shift Team',
                onPressed: () async {
                  final name = nameController.text.trim();
                  final role = roleController.text.trim();

                  if (name.isEmpty || role.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter staff name and role.')),
                    );
                    return;
                  }

                  final saved = await context.read<PartnerTeamCubit>().addStaff(
                        name: name,
                        role: role,
                        status: selectedStatus,
                      );

                  if (!saved) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Staff member could not be saved. Check your connection and try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (!modalContext.mounted) return;
                  Navigator.pop(modalContext);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name added to salon team!')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartnerTeamCubit, PartnerTeamState>(
      builder: (context, state) {
        final team =
            state is PartnerTeamLoadedState ? state.team : <StaffMemberModel>[];
        final onShiftCount = team
            .where((s) => s.status != 'Off Shift' && s.status != 'OFF_SHIFT')
            .length;
        final availableCount = team
            .where((s) => s.status == 'Available' || s.status == 'AVAILABLE')
            .length;
        final jobsToday =
            team.fold<int>(0, (sum, member) => sum + member.jobCountToday);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.darkNeutral, size: 20),
              onPressed: () => context.pop(),
            ),
            title: const Text('Team & schedules',
                style: AppTypography.screenTitle),
            actions: [
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.darkNeutral, size: 24),
                onPressed: () => context.pop(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // 3 Stat Cards Row
                Row(
                  children: [
                    _statCard('$onShiftCount', 'On shift'),
                    const SizedBox(width: AppSpacing.md),
                    _statCard('$availableCount', 'Available'),
                    const SizedBox(width: AppSpacing.md),
                    _statCard('$jobsToday', 'Jobs today'),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Staff Member Cards
                if (team.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.badge_outlined,
                              size: 40, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('No staff members added yet',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNeutral)),
                          SizedBox(height: 4),
                          Text(
                              'Tap + Add staff member below to add your stylists and barbers.',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.textMuted),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                else
                  for (var member in team)
                    GestureDetector(
                      onTap: () async {
                        final saved = await context
                            .read<PartnerTeamCubit>()
                            .toggleStaffStatus(member.id);
                        if (!saved && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Status could not be updated. Please try again.'),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: _staffTile(
                        member.initials,
                        member.name,
                        member.role,
                        member.status,
                        (member.status == 'Available' ||
                                member.status == 'AVAILABLE')
                            ? const Color(0xFFDCFCE7)
                            : (member.status == 'In service' ||
                                    member.status == 'IN_SERVICE')
                                ? const Color(0xFFE0F2FE)
                                : const Color(0xFFF3F4F6),
                        (member.status == 'Available' ||
                                member.status == 'AVAILABLE')
                            ? const Color(0xFF166534)
                            : (member.status == 'In service' ||
                                    member.status == 'IN_SERVICE')
                                ? const Color(0xFF0284C7)
                                : AppColors.textMuted,
                        onDelete: () async {
                          final deleted = await context
                              .read<PartnerTeamCubit>()
                              .deleteStaff(member.id);
                          if (!deleted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Staff member could not be removed. Please try again.'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        },
                      ),
                    ),
                const SizedBox(height: AppSpacing.xl),

                // Add Staff Member Button
                SlotPrimaryButton(
                  text: '+ Add staff member',
                  onPressed: () => _showAddStaffModal(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFF3EFEA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNeutral)),
            const SizedBox(height: 2),
            Text(label,
                style:
                    const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _staffTile(String initials, String name, String role, String status,
      Color bg, Color textColor,
      {VoidCallback? onDelete}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [AppShadows.cardShadow],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(initials,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldDark)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNeutral)),
                const SizedBox(height: 2),
                Text(role,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 20),
              onPressed: onDelete,
            ),
          ],
        ],
      ),
    );
  }
}

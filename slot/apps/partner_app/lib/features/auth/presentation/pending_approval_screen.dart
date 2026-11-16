import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../cubit/partner_auth_cubit.dart';

class PendingApprovalScreen extends StatelessWidget {
  final PartnerPendingApproval state;

  const PendingApprovalScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pending_actions_rounded, size: 64, color: AppColors.primaryGoldDark),
                const SizedBox(height: 24),
                const Text('Approval pending', style: AppTypography.screenTitle),
                const SizedBox(height: 12),
                Text(
                  '${state.salonName} is waiting for admin approval. Booking and salon management will become available after approval.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, height: 1.5),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.read<PartnerAuthCubit>().logout(),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

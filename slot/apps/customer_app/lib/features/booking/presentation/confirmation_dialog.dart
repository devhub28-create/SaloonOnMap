import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';

class ConfirmationDialog extends StatelessWidget {
  final String referenceCode;
  final String timeStr;
  final String salonName;

  const ConfirmationDialog({
    super.key,
    required this.referenceCode,
    required this.timeStr,
    required this.salonName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.statusAvailableBg,
              child: Icon(Icons.check_rounded,
                  size: 40, color: AppColors.statusAvailableText),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('BOOKING CONFIRMED',
                style: AppTypography.sectionEyebrow),
            const SizedBox(height: 6),
            const Text(
              'Your chair is saved.',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNeutral),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '$salonName is expecting you at $timeStr.',
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Reference Code Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFECE6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                referenceCode,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColors.darkNeutral,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            SlotPrimaryButton(
              text: 'Done',
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/my-bookings');
              },
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_tokens.dart';

class SlotSeatCard extends StatelessWidget {
  final int seatNumber;
  final String statusLabel; // AVAILABLE, BOOKED, IN_SERVICE, RESERVED, CLEANING
  final String? customerName;
  final String? timeInfo;
  final bool isSelected;
  final VoidCallback? onTap;

  const SlotSeatCard({
    super.key,
    required this.seatNumber,
    required this.statusLabel,
    this.customerName,
    this.timeInfo,
    this.isSelected = false,
    this.onTap,
  });

  Color get _statusColor {
    switch (statusLabel.toUpperCase()) {
      case 'AVAILABLE':
        return AppColors.statusAvailableText;
      case 'BOOKED':
      case 'RESERVED':
        return AppColors.statusBookedText;
      case 'IN_SERVICE':
        return AppColors.statusInServiceText;
      case 'CLEANING':
        return AppColors.statusCleaningText;
      default:
        return AppColors.darkNeutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected ? AppColors.primaryGold : _statusColor.withOpacity(0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: const [AppShadows.cardShadow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                '$seatNumber',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            Icon(
              Icons.chair_alt_rounded,
              size: 32,
              color: _statusColor,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _statusColor,
              ),
            ),
            if (customerName != null) ...[
              const SizedBox(height: 2),
              Text(
                '$customerName ${timeInfo != null ? "· $timeInfo" : ""}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

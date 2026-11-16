import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_tokens.dart';

class SlotBookingCard extends StatelessWidget {
  final String title;
  final String services;
  final String time;
  final String seat;
  final String status;
  final VoidCallback? onTap;

  const SlotBookingCard({
    super.key,
    required this.title,
    required this.services,
    required this.time,
    required this.seat,
    required this.status,
    this.onTap,
  });

  Color _statusBgColor(String statusStr) {
    final s = statusStr.toUpperCase();
    if (s == 'CONFIRMED') return AppColors.statusAvailableBg;
    if (s == 'CANCELLED') return const Color(0xFFFEE2E2);
    if (s == 'COMPLETED' || s == 'DONE') return const Color(0xFFE0E7FF);
    return AppColors.statusBookedBg;
  }

  Color _statusTextColor(String statusStr) {
    final s = statusStr.toUpperCase();
    if (s == 'CONFIRMED') return AppColors.statusAvailableText;
    if (s == 'CANCELLED') return AppColors.statusDestructiveText;
    if (s == 'COMPLETED' || s == 'DONE') return const Color(0xFF3730A3);
    return AppColors.statusBookedText;
  }

  @override
  Widget build(BuildContext context) {
    final avatarInitial = title.isNotEmpty ? title.substring(0, title.length > 2 ? 2 : title.length).toUpperCase() : 'M';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [AppShadows.cardShadow],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFDE8E8),
            radius: 22,
            child: Text(
              avatarInitial,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.darkNeutral,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: AppTypography.cardTitle,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.darkNeutral,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  services,
                  style: AppTypography.bodyText,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          seat,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _statusBgColor(status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusTextColor(status),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

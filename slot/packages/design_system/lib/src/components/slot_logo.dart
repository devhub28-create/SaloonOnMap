import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';

/// Centralized Brand Logo Widget for the SLOT Platform.
/// Renders the luxury gold & obsidian brand emblem with image asset support
/// and crisp vector fallback.
class SlotLogo extends StatelessWidget {
  final double size;
  final String? badgeText;
  final bool showLabel;
  final VoidCallback? onTap;

  const SlotLogo({
    super.key,
    this.size = 80,
    this.badgeText,
    this.showLabel = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(size * 0.28);

    Widget logoImage = Image.asset(
      'assets/images/slot_logo.jpg',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to second asset variant or vector emblem
        return Image.asset(
          'assets/images/slot_logo_mark.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildVectorFallback(),
        );
      },
    );

    Widget badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.darkNeutral,
        borderRadius: borderRadius,
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: logoImage,
    );

    if (badgeText != null && badgeText!.isNotEmpty) {
      badge = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          badge,
          Positioned(
            bottom: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primaryGoldDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                badgeText!.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (showLabel) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(onTap: onTap, child: badge),
          const SizedBox(height: 12),
          const Text(
            'SLOT',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 4.0,
              color: AppColors.darkNeutral,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: badge,
    );
  }

  Widget _buildVectorFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF232B38),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.content_cut_rounded,
          color: AppColors.primaryGold,
          size: size * 0.48,
        ),
      ),
    );
  }
}

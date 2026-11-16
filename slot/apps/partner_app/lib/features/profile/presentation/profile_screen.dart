import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:api_client/api_client.dart';

import '../../auth/cubit/partner_auth_cubit.dart';

class PartnerProfileScreen extends StatefulWidget {
  const PartnerProfileScreen({super.key});

  @override
  State<PartnerProfileScreen> createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  late Future<Map<String, dynamic>> _salonProfile;

  @override
  void initState() {
    super.initState();
    _refreshSalonProfile();
  }

  void _refreshSalonProfile() {
    _salonProfile =
        context.read<PartnerAuthCubit>().apiClient.getPartnerSalon();
  }

  Future<void> _openSalonSettings() async {
    await context.push('/partner/salon-details');
    if (!mounted) return;
    setState(_refreshSalonProfile);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartnerAuthCubit, PartnerAuthState>(
      builder: (context, authState) {
        final salonName =
            authState is PartnerAuthenticated ? authState.salonName : 'Salon';
        final ownerName =
            authState is PartnerAuthenticated ? authState.ownerName : 'Partner';
        final coverImage =
            authState is PartnerAuthenticated ? authState.coverImage : '';

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'SALON ACCOUNT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(salonName, style: AppTypography.screenTitle),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [AppShadows.cardShadow],
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.darkNeutral,
                    size: 20,
                  ),
                  onPressed: _openSalonSettings,
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Salon Header Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: const [AppShadows.cardShadow],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: Image.network(
                          ApiConfig.formatImageUrl(coverImage),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: const Color(0xFFD6C8B8),
                            child: const Center(
                              child: Icon(
                                Icons.storefront_rounded,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              salonName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNeutral,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Owner: $ownerName · Active Partner Desk',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            FutureBuilder<Map<String, dynamic>>(
                              future: _salonProfile,
                              builder: (context, snapshot) {
                                final salon = snapshot.data;
                                final rating =
                                    (salon?['rating'] as num?)?.toDouble();
                                final reviewCount =
                                    (salon?['review_count'] as num?)?.toInt() ??
                                        0;
                                final isActive =
                                    salon?['is_active'] as bool? ?? true;
                                final status = isActive ? 'Active' : 'Paused';
                                final ratingLabel = reviewCount > 0 &&
                                        rating != null
                                    ? '${rating.toStringAsFixed(1)} · $reviewCount ${reviewCount == 1 ? 'review' : 'reviews'}'
                                    : 'New salon';
                                return Row(
                                  children: [
                                    Icon(
                                      reviewCount > 0
                                          ? Icons.star_rounded
                                          : Icons.storefront_rounded,
                                      size: 16,
                                      color: AppColors.primaryGoldDark,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        snapshot.hasError
                                            ? 'Salon profile available'
                                            : '$ratingLabel · $status profile',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGoldDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Options Tiles List
                _optionTile(
                  context,
                  Icons.people_outline_rounded,
                  'Staff & schedules',
                  onTap: () => context.push('/partner/team'),
                ),
                _optionTile(
                  context,
                  Icons.bar_chart_rounded,
                  'Reports & insights',
                  onTap: () => context.push('/partner/reports'),
                ),
                _optionTile(
                  context,
                  Icons.content_cut_rounded,
                  'Services & pricing',
                  onTap: () => context.go('/services'),
                ),
                _optionTile(
                  context,
                  Icons.storefront_rounded,
                  'Salon details & hours',
                  onTap: _openSalonSettings,
                ),
                _optionTile(
                  context,
                  Icons.support_agent_rounded,
                  'Help & support',
                  onTap: () => context.push('/partner/support'),
                ),
                const SizedBox(height: AppSpacing.md),
                _optionTile(
                  context,
                  Icons.logout_rounded,
                  'Log out',
                  iconColor: Colors.red,
                  tileBgColor: const Color(0xFFFEE2E2),
                  textColor: Colors.red,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Log out of Salon Desk?'),
                        content: const Text(
                          'You will need to sign in again to access live bookings and seats.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              context.read<PartnerAuthCubit>().logout();
                              context.go('/login');
                            },
                            child: const Text(
                              'Log out',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _optionTile(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
    Color? iconColor,
    Color? tileBgColor,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tileBgColor ?? const Color(0xFFFEF9C3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.primaryGoldDark,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: textColor ?? AppColors.darkNeutral,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: AppColors.textMuted,
        ),
        onTap: onTap,
      ),
    );
  }
}

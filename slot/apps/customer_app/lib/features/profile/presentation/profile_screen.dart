import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticatedState
        ? authState.user
        : <String, dynamic>{};
    final userName = user['name'] ?? 'Customer';
    final userPhone = user['phone'] ?? '+91 98765 43210';
    final userInitials = userName.isNotEmpty
        ? userName.split(' ').map((e) => e[0]).take(2).join('').toUpperCase()
        : 'C';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ACCOUNT', style: AppTypography.sectionEyebrow),
            SizedBox(height: 2),
            Text('Your profile', style: AppTypography.screenTitle),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: AppColors.darkNeutral, size: 20),
              onPressed: () => context.push('/profile/settings'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Dark User Profile Header Card (Matches Profile 1.png / media_1791346835602.png)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.darkNeutral,
                borderRadius: BorderRadius.circular(AppRadius.card),
                boxShadow: const [AppShadows.cardShadow],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        userInitials,
                        style: const TextStyle(
                            color: AppColors.darkNeutral,
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 2),
                        Text(
                            authState is AuthAuthenticatedState
                                ? userPhone
                                : 'Sign in to sync your bookings',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            if (authState is AuthAuthenticatedState) {
                              context.push('/profile/edit');
                            } else {
                              context.push('/login');
                            }
                          },
                          child: Text(
                            authState is AuthAuthenticatedState
                                ? 'Edit profile'
                                : 'Sign In / Register →',
                            style: const TextStyle(
                                color: AppColors.primaryGold,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            _optionTile(context, Icons.calendar_today_rounded, 'My bookings',
                onTap: () => context.push('/my-bookings')),
            _optionTile(context, Icons.auto_awesome, 'AI Style Studio (Virtual Looks)',
                onTap: () => context.push('/ai-style-studio')),
            _optionTile(context, Icons.style_outlined, 'My Saved AI Looks',
                onTap: () => context.push('/saved-ai-looks')),
            _optionTile(
                context, Icons.favorite_border_rounded, 'Favorite salons',
                onTap: () => context.push('/profile/favorites')),
            _optionTile(context, Icons.card_giftcard_rounded, 'Invite friends',
                onTap: () => context.push('/profile/invite')),
            _optionTile(
                context, Icons.confirmation_number_outlined, 'Offers & coupons',
                onTap: () => context.push('/offers')),
            _optionTile(
                context, Icons.notifications_none_rounded, 'Notifications',
                onTap: () => context.push('/profile/notifications')),
            _optionTile(context, Icons.payment_rounded, 'Payment methods',
                onTap: () => context.push('/profile/payment-methods')),
            _optionTile(
                context, Icons.chat_bubble_outline_rounded, 'Help & support',
                onTap: () => context.push('/profile/help')),
            _optionTile(context, Icons.shield_outlined, 'Privacy & terms',
                onTap: () => context.push('/profile/privacy')),
            const SizedBox(height: AppSpacing.lg),

            // Logout or Login/Signup Action Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.xl),
              child: authState is AuthAuthenticatedState
                  ? ElevatedButton(
                      onPressed: () {
                        context.read<AuthCubit>().logout();
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFEE2E2),
                        foregroundColor: const Color(0xFFDC2626),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Log out',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkNeutral,
                        foregroundColor: AppColors.primaryGold,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Sign In or Create Account →',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SlotBottomNavBar(
        currentIndex: 4,
        onTap: (index) {
          if (index == 0) context.go('/');
          if (index == 1) context.go('/explore');
          if (index == 2) context.go('/my-bookings');
          if (index == 3) context.go('/offers');
        },
        items: const [
          SlotNavItem(icon: Icons.home_rounded, label: 'Home'),
          SlotNavItem(icon: Icons.explore_outlined, label: 'Explore'),
          SlotNavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
          SlotNavItem(
              icon: Icons.confirmation_number_outlined, label: 'Offers'),
          SlotNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _optionTile(BuildContext context, IconData icon, String title,
      {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9C3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryGoldDark, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.darkNeutral)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded,
            size: 14, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}

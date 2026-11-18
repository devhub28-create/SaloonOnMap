import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../auth/cubit/auth_cubit.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  String? _code;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    try {
      final profile =
          await context.read<AuthCubit>().apiClient.getCustomerProfile();
      if (mounted) setState(() => _code = profile['referralCode']?.toString());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final code = _code;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Invite Friends', style: AppTypography.screenTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.card_giftcard_rounded,
                size: 56,
                color: AppColors.primaryGoldDark,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Invite friends to SLOT',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Share your personal referral code.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              SelectableText(
                code ?? 'Loading...',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: code == null
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Referral code copied.'),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy referral code'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: code == null
                    ? null
                    : () => Share.share(
                          'Book trusted salons near you with SalonOnMap. Use my referral code $code when you join.',
                          subject: 'Join me on SalonOnMap',
                        ),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share invite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

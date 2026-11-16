import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';

class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkNeutral, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Privacy & Terms', style: AppTypography.screenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildPolicyCard(
            '1. Terms of Service',
            'By using the SLOT platform, you agree to comply with our seat reservation standards, 5-minute hold policies, and user conduct guidelines. Salon bookings are guaranteed once confirmed.',
          ),
          _buildPolicyCard(
            '2. Privacy & Data Protection',
            'We value your personal privacy. Phone numbers, customer names, location coordinates, and appointment histories are encrypted at rest using AES-256 and never shared with third-party advertisers.',
          ),
          _buildPolicyCard(
            '3. Location & GPS Policy',
            'Precise GPS coordinates are requested strictly to calculate nearby salons and estimated travel distances. You can revoke location access anytime via system settings.',
          ),
          _buildPolicyCard(
            '4. Cancellation & Refund Terms',
            'Bookings cancelled at least 30 minutes prior to the scheduled slot time are eligible for full instant refunds to your SLOT Wallet or original payment method.',
          ),
          const SizedBox(height: AppSpacing.xl),
          const Center(
            child: Text(
              'SLOT Platform v1.0.4 (Build 42)\n© 2026 SLOT Technologies Pvt. Ltd.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkNeutral)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
        ],
      ),
    );
  }
}

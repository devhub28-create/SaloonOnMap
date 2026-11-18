import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:api_client/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final websiteBase = ApiConfig.baseUrl.replaceFirst(
      RegExp(r'/api/v1/?$'),
      '',
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.darkNeutral,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('Privacy & Terms', style: AppTypography.screenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _buildPolicyCard(
            '1. Terms of Service',
            'SalonOnMap connects customers with independent salons. Confirmed bookings are subject to the salon’s displayed availability, cancellation policy, and service terms.',
          ),
          _buildPolicyCard(
            '2. Privacy & Data Protection',
            'We use account, location, and booking information to provide the service. Data is sent over HTTPS and may be shared with the booked salon and essential service providers. We do not sell personal data.',
          ),
          _buildPolicyCard(
            '3. Location & GPS Policy',
            'Precise GPS coordinates are requested strictly to calculate nearby salons and estimated travel distances. You can revoke location access anytime via system settings.',
          ),
          _buildPolicyCard(
            '4. Payments & Cancellations',
            'Current bookings are paid directly at the salon. Cancellation and rescheduling rules are shown for each booking; SalonOnMap does not currently operate a wallet or promise automatic refunds.',
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Read full privacy policy'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => launchUrl(
              Uri.parse('$websiteBase/privacy'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: const Text('Read full terms of service'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => launchUrl(
              Uri.parse('$websiteBase/terms'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.statusDestructiveText,
            ),
            title: const Text('Request account deletion'),
            subtitle: const Text('Opens the verified deletion request page'),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => launchUrl(
              Uri.parse('$websiteBase/delete-account'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Center(
            child: Text(
              'SalonOnMap\n© 2026 SalonOnMap. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.4,
              ),
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.darkNeutral,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
        title: const Text('Help & Support', style: AppTypography.screenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text('24/7 CUSTOMER SUPPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1)),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              _buildContactCard(context, Icons.headset_mic_rounded, 'Call Support', '1800-SLOT-APP'),
              const SizedBox(width: AppSpacing.md),
              _buildContactCard(context, Icons.mail_outline_rounded, 'Email Support', 'support@slot.com'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const Text('FREQUENTLY ASKED QUESTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1)),
          const SizedBox(height: AppSpacing.md),

          _buildFaqTile('How does the 5-minute seat hold protection work?', 'When you select a chair and proceed to review, SLOT locks your seat for 5 minutes. No other customer can book that chair while your timer is running.'),
          _buildFaqTile('Can I cancel or reschedule my booking?', 'Yes! You can cancel or reschedule any upcoming booking free of charge up to 30 minutes before your slot time directly from the My Bookings screen.'),
          _buildFaqTile('What happens if the salon is running late?', 'SLOT partners are required to adhere strictly to scheduled seats. If your chair is delayed past 10 minutes, you receive instant 20% wallet compensation.'),
          _buildFaqTile('How do I apply offer codes & discounts?', 'Enter your promo code on the Review Booking screen or tap "Apply Coupon" from the Offers tab before confirming your appointment.'),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, IconData icon, String title, String subtitle) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connecting to $title ($subtitle)...')),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [AppShadows.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryGoldDark, size: 22),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkNeutral)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkNeutral)),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(answer, style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UiStatesScreen extends StatefulWidget {
  const UiStatesScreen({super.key});

  @override
  State<UiStatesScreen> createState() => _UiStatesScreenState();
}

class _UiStatesScreenState extends State<UiStatesScreen> {
  String _selectedTheme = 'Men & Unisex';
  String _selectedLanguage = 'English (US)';

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
        title: const Text('UI States & Modes', style: AppTypography.screenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text('THEME MODE & PREVIEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1)),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              _buildThemeCard('Men & Unisex', 'Dark charcoal header with gold accents', AppColors.darkNeutral, AppColors.primaryGold),
              const SizedBox(width: AppSpacing.md),
              _buildThemeCard('Women Soft Rose', 'Soft rose header with pink accents', const Color(0xFFFDF2F8), const Color(0xFFEC4899)),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          const Text('APPLICATION LANGUAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1)),
          const SizedBox(height: AppSpacing.md),

          _buildLanguageTile('English (US)'),
          _buildLanguageTile('Hindi (हिन्दी)'),
          _buildLanguageTile('Marathi (मराठी)'),

          const SizedBox(height: AppSpacing.xl),

          const Text('DEVELOPER & DEMO ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1)),
          const SizedBox(height: AppSpacing.md),

          _buildActionTile('Reset Onboarding State', 'View introductory 3-step walkthrough again', Icons.restore_rounded, () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('has_completed_onboarding', false);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Onboarding reset! Navigating to onboarding...')),
              );
              context.go('/onboarding');
            }
          }),
          _buildActionTile('Trigger 5-Min Hold Timeout', 'Simulate expired seat hold dialog', Icons.timer_off_outlined, () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Seat hold timeout simulation triggered.')),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildThemeCard(String title, String subtitle, Color bgColor, Color accentColor) {
    final isSelected = _selectedTheme == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTheme = title);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Theme switched to $title')),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppColors.primaryGoldDark : AppColors.borderLight, width: isSelected ? 2 : 1),
            boxShadow: const [AppShadows.cardShadow],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.darkNeutral)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(String language) {
    final isSelected = _selectedLanguage == language;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? AppColors.primaryGoldDark : AppColors.borderLight),
      ),
      child: ListTile(
        title: Text(language, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkNeutral)),
        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGoldDark, size: 20) : null,
        onTap: () => setState(() => _selectedLanguage = language),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.darkNeutral, size: 22),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkNeutral)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/cubit/auth_cubit.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final user = authState is AuthAuthenticatedState
        ? authState.user
        : <String, dynamic>{};
    _nameController = TextEditingController(text: user['name'] ?? '');
    _phoneController = TextEditingController(text: user['phone'] ?? '');
    _emailController = TextEditingController(text: user['email'] ?? '');
    _cityController = TextEditingController(text: user['city'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      await context.read<AuthCubit>().updateProfile({
        'name': _nameController.text,
        'email': _emailController.text,
        'preferredGender': _selectedGender,
      });
      if (!mounted) return;
      final state = context.read<AuthCubit>().state;
      if (state is AuthNetworkErrorState) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.message)));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile details updated successfully!'),
          backgroundColor: AppColors.primaryGoldDark,
          duration: Duration(seconds: 2),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Edit Profile', style: AppTypography.screenTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.md),
              // Avatar Stack with Edit Icon
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [AppShadows.cardShadow],
                    ),
                    child: const Center(
                      child: Text(
                        'AT',
                        style: TextStyle(
                          color: AppColors.darkNeutral,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.darkNeutral,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: AppColors.primaryGold,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Inputs
              _buildTextField(
                'Full Name',
                _nameController,
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                'Phone Number',
                _phoneController,
                Icons.phone_outlined,
                readOnly: true,
                suffixText: 'VERIFIED',
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                'Email Address',
                _emailController,
                Icons.email_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField(
                'City & Location',
                _cityController,
                Icons.location_on_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Gender Selector
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gender Preference',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.darkNeutral,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Female', 'Male', 'Non-binary'].map((gender) {
                      final isSelected = _selectedGender == gender;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedGender = gender),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.darkNeutral
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.darkNeutral
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                gender,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.primaryGold
                                      : AppColors.darkNeutral,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Save Button
              SlotPrimaryButton(text: 'Save Changes', onPressed: _saveProfile),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool readOnly = false,
    String? suffixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.darkNeutral,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.darkNeutral,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
            suffixIcon: suffixText != null
                ? Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      suffixText,
                      style: const TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            filled: true,
            fillColor: readOnly ? const Color(0xFFF3F4F6) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primaryGoldDark,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

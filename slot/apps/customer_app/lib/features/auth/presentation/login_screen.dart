import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';

import '../cubit/auth_cubit.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUpMode = false;
  bool _otpSent = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _submitPhone() {
    final phone = _phoneController.text.replaceAll(RegExp(r'[\s\-]'), '');
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_isSignUpMode && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name for registration.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    context.read<AuthCubit>().requestOtp(phone);
  }

  void _submitOtp(String code) {
    context.read<AuthCubit>().verifyOtp(
          code.trim(),
          name: _isSignUpMode ? _nameController.text.trim() : null,
          email: _isSignUpMode ? _emailController.text.trim() : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpRequestedState) {
            setState(() {
              _otpSent = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent to your mobile number.'),
                backgroundColor: AppColors.primaryGoldDark,
                duration: Duration(seconds: 3),
              ),
            );
          } else if (state is AuthAuthenticatedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Welcome back, ${state.user['name'] ?? 'Customer'}!',
                ),
                backgroundColor: Colors.green.shade800,
              ),
            );
            context.go('/');
          } else if (state is AuthValidationErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthInvalidOtpState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthNetworkErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthRateLimitedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is AuthExpiredOtpState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading =
              state is AuthRequestingOtpState || state is AuthVerifyingOtpState;

          return SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.lg,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight > (AppSpacing.lg * 2)
                              ? constraints.maxHeight - (AppSpacing.lg * 2)
                              : 0,
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Brand Logo
                              const SlotLogo(size: 80),
                              const SizedBox(height: 36),

                              // Segmented Switcher: [ Login ] | [ Sign Up ]
                              if (!_otpSent) ...[
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isSignUpMode = false;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: !_isSignUpMode
                                                  ? AppColors.darkNeutral
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: !_isSignUpMode
                                                  ? [
                                                      const BoxShadow(
                                                        color: Color(
                                                          0x1F000000,
                                                        ),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Login',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: !_isSignUpMode
                                                      ? AppColors.primaryGold
                                                      : AppColors.textMuted,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _isSignUpMode = true;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _isSignUpMode
                                                  ? AppColors.darkNeutral
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: _isSignUpMode
                                                  ? [
                                                      const BoxShadow(
                                                        color: Color(
                                                          0x1F000000,
                                                        ),
                                                        blurRadius: 4,
                                                        offset: Offset(0, 2),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Sign Up',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: _isSignUpMode
                                                      ? AppColors.primaryGold
                                                      : AppColors.textMuted,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Eyebrow & Title
                                Text(
                                  _isSignUpMode ? 'NEW CUSTOMER' : 'SIGN IN',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isSignUpMode
                                      ? 'Effortless appointments\nat top salons.'
                                      : 'Your next great look\nstarts here.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkNeutral,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // If Sign Up: Full Name & Optional Email
                                if (_isSignUpMode) ...[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Full Name *',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkNeutral,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppColors.borderLight,
                                          ),
                                          boxShadow: const [
                                            AppShadows.cardShadow,
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _nameController,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.darkNeutral,
                                            fontSize: 15,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'e.g. Rahul Sharma',
                                            prefixIcon: Icon(
                                              Icons.person_outline_rounded,
                                              color: AppColors.textMuted,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Email Address (Optional)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkNeutral,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: AppColors.borderLight,
                                          ),
                                          boxShadow: const [
                                            AppShadows.cardShadow,
                                          ],
                                        ),
                                        child: TextField(
                                          controller: _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.darkNeutral,
                                            fontSize: 15,
                                          ),
                                          decoration: const InputDecoration(
                                            hintText: 'e.g. rahul@example.com',
                                            prefixIcon: Icon(
                                              Icons.email_outlined,
                                              color: AppColors.textMuted,
                                            ),
                                            border: InputBorder.none,
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ],

                                // Mobile Number Field
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mobile number *',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkNeutral,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.borderLight,
                                        ),
                                        boxShadow: const [
                                          AppShadows.cardShadow,
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Text(
                                              '+91',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: AppColors.darkNeutral,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 24,
                                            width: 1,
                                            color: AppColors.borderLight,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: _phoneController,
                                              keyboardType: TextInputType.phone,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.darkNeutral,
                                                fontSize: 15,
                                              ),
                                              decoration: const InputDecoration(
                                                hintText: '98765 43210',
                                                border: InputBorder.none,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                  vertical: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Request a one-time passcode before signing in.
                                SlotPrimaryButton(
                                  text: isLoading
                                      ? 'Sending OTP...'
                                      : (_isSignUpMode
                                          ? 'Send OTP & Continue →'
                                          : 'Send OTP →'),
                                  onPressed: isLoading ? null : _submitPhone,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'By continuing, you agree to our Terms & Privacy Policy.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ] else ...[
                                // OTP Verification Step
                                Text(
                                  'ENTER 6-DIGIT OTP SENT TO +91 ${_phoneController.text.replaceAll(RegExp(r'[\s\-]'), '')}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.borderLight,
                                    ),
                                    boxShadow: const [AppShadows.cardShadow],
                                  ),
                                  child: TextField(
                                    controller: _otpController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                      letterSpacing: 8,
                                      color: AppColors.darkNeutral,
                                    ),
                                    decoration: const InputDecoration(
                                      counterText: '',
                                      hintText: '••••••',
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                SlotPrimaryButton(
                                  text: isLoading
                                      ? 'Verifying OTP...'
                                      : 'Verify & Continue →',
                                  onPressed: isLoading
                                      ? null
                                      : () => _submitOtp(_otpController.text),
                                ),
                                const SizedBox(height: 16),

                                TextButton.icon(
                                  onPressed: isLoading ? null : _submitPhone,
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Resend OTP'),
                                ),

                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _otpSent = false;
                                    });
                                  },
                                  child: const Text(
                                    '← Change Mobile Number or Mode',
                                    style: TextStyle(
                                      color: AppColors.darkNeutral,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:api_client/api_client.dart';

import '../cubit/partner_auth_cubit.dart';

class PartnerLoginScreen extends StatefulWidget {
  const PartnerLoginScreen({super.key});

  @override
  State<PartnerLoginScreen> createState() => _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends State<PartnerLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    final authCubit = context.read<PartnerAuthCubit>();
    authCubit.login(
      phoneOrEmail: _phoneController.text,
      password: _passwordController.text,
    );
  }

  Future<void> _showPasswordRecovery() async {
    final apiClient = context.read<PartnerAuthCubit>().apiClient;
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PasswordResetSheet(
        apiClient: apiClient,
        initialIdentifier: _phoneController.text,
      ),
    );
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message), backgroundColor: const Color(0xFF16A34A)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<PartnerAuthCubit, PartnerAuthState>(
        listener: (context, state) {
          if (state is PartnerAuthenticated) {
            context.go('/');
          } else if (state is PartnerAuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusDestructiveText,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PartnerAuthLoading;

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
                              // Centered Brand Logo Badge
                              const SlotLogo(size: 80, badgeText: 'PARTNER'),
                              const SizedBox(height: 36),
                              // Header Title
                              const Text(
                                'PARTNER DESK',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 3.0,
                                  color: AppColors.primaryGoldDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Salon Desk Portal',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNeutral,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Manage bookings, seats, services & live shifts',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxl),

                              // Phone / Email Field
                              TextField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkNeutral,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number / Email',
                                  prefixIcon: const Icon(
                                    Icons.phone_android_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryGoldDark,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),

                              // Password Field
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.darkNeutral,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Password / PIN',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppColors.textMuted,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textMuted,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.borderLight,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.primaryGoldDark,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),

                              // Forgot Password link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showPasswordRecovery,
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGoldDark,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),

                              // Primary Login Button
                              SlotPrimaryButton(
                                text: isLoading
                                    ? 'Authenticating Desk...'
                                    : 'Sign In to Salon Desk →',
                                onPressed: isLoading ? null : _submitLogin,
                              ),
                              const SizedBox(height: AppSpacing.xxl),

                              // Registration footer
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Want to list your salon?",
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push('/register'),
                                    child: const Text(
                                      'Register Salon',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkNeutral,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

class _PasswordResetSheet extends StatefulWidget {
  final ApiClient apiClient;
  final String initialIdentifier;

  const _PasswordResetSheet({
    required this.apiClient,
    required this.initialIdentifier,
  });

  @override
  State<_PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<_PasswordResetSheet> {
  late final TextEditingController _identifier;
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _identifier = TextEditingController(text: widget.initialIdentifier);
  }

  @override
  void dispose() {
    _identifier.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  String _message(Object error) {
    if (error is DioException && error.response?.data is Map) {
      final value = error.response?.data['message'];
      if (value is List) return value.join(' ');
      if (value != null) return value.toString();
    }
    return 'Could not complete the request. Please try again.';
  }

  Future<void> _requestCode() async {
    if (_identifier.text.trim().length < 3) {
      setState(() => _error = 'Enter your registered phone number or email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.apiClient.requestPartnerPasswordReset(_identifier.text);
      if (mounted) setState(() => _codeSent = true);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) {
      setState(() => _error = 'Enter the complete 6-digit verification code.');
      return;
    }
    if (_password.text.length < 10) {
      setState(
          () => _error = 'New password must contain at least 10 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await widget.apiClient.resetPartnerPassword(
        phoneOrEmail: _identifier.text,
        code: _code.text,
        newPassword: _password.text,
      );
      if (mounted) Navigator.of(context).pop(message);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Reset partner password',
                  style: AppTypography.screenTitle),
              const SizedBox(height: 8),
              const Text(
                'We will send a verification code to the phone registered with your salon.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _identifier,
                enabled: !_codeSent && !_busy,
                decoration: const InputDecoration(
                  labelText: 'Registered phone or email',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_codeSent) ...[
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: '6-digit verification code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    helperText: 'At least 10 characters',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.statusDestructiveText)),
              ],
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed:
                    _busy ? null : (_codeSent ? _resetPassword : _requestCode),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_codeSent
                        ? 'Update password'
                        : 'Send verification code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

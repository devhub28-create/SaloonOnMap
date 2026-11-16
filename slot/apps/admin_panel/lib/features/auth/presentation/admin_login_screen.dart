import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../cubit/admin_auth_cubit.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() {
    final authCubit = context.read<AdminAuthCubit>();
    authCubit.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkCard,
      body: BlocConsumer<AdminAuthCubit, AdminAuthState>(
        listener: (context, state) {
          if (state is AdminAuthenticated) {
            context.go('/');
          } else if (state is AdminAuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusDestructiveText,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AdminAuthLoading;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.darkNeutral,
                  borderRadius: BorderRadius.circular(24),
                  border:
                      Border.all(color: const Color(0x4DC89300), width: 1.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x80000000),
                      blurRadius: 32,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Logo
                    const SlotLogo(
                      size: 80,
                      badgeText: 'ADMIN',
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'SLOT PLATFORM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.0,
                        color: AppColors.primaryGoldDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Super Admin Portal',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x26C89300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '🔒 RESTRICTED SYSTEM ACCESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Admin Email',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.email_outlined,
                            color: AppColors.primaryGold),
                        filled: true,
                        fillColor: AppColors.darkCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0x1AFFFFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0x1AFFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primaryGold, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Password Field
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Security Password',
                        labelStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(Icons.lock_outline_rounded,
                            color: AppColors.primaryGold),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: AppColors.darkCard,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0x1AFFFFFF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: Color(0x1AFFFFFF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primaryGold, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Authenticate Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGoldDark,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : _submitLogin,
                        child: Text(
                          isLoading
                              ? 'Authenticating Access...'
                              : 'Authenticate Admin Portal →',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGold,
                        side: const BorderSide(color: Color(0x4DC89300)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        setState(() {
                          _emailController.text = 'admin@slot.com';
                          _passwordController.text = 'Admin@123';
                        });
                      },
                      icon: const Icon(Icons.key_rounded, size: 16),
                      label: const Text('Auto-Fill Demo Admin (admin@slot.com)'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

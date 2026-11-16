import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop()),
        title: const Text('Payment Methods', style: AppTypography.screenTitle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.borderLight)),
          child: const Row(
            children: [
              Icon(Icons.storefront_rounded, color: AppColors.primaryGoldDark),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pay at salon',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text(
                        'Pay by cash, UPI, or card directly after your service.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded,
                  color: AppColors.statusAvailableText),
            ],
          ),
        ),
      ),
    );
  }
}

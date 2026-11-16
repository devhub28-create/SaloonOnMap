import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  List<Map<String, dynamic>> _offers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result =
          await context.read<AuthCubit>().apiClient.getCustomerOffers();
      if (!mounted) return;
      setState(() {
        _offers = result
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Offers for you', style: AppTypography.screenTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _offers.isEmpty
              ? const Center(child: Text('No active offers right now.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _offers.length,
                  itemBuilder: (context, index) {
                    final offer = _offers[index];
                    final type = offer['discount_type']?.toString();
                    final value = offer['discount_value'] ?? 0;
                    final discount =
                        type == 'PERCENTAGE' ? '$value% off' : '₹$value off';
                    final validUntil = DateTime.tryParse(
                            offer['valid_until']?.toString() ?? '')
                        ?.toLocal();
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.borderLight)),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer_outlined,
                              color: AppColors.primaryGoldDark),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(offer['name']?.toString() ?? discount,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '$discount · Minimum ₹${offer['min_booking_amount'] ?? 0}'),
                                if (validUntil != null)
                                  Text(
                                      'Valid until ${validUntil.day}/${validUntil.month}/${validUntil.year}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final code = offer['code']?.toString() ?? '';
                              await Clipboard.setData(
                                  ClipboardData(text: code));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$code copied')));
                              }
                            },
                            child: Text(offer['code']?.toString() ?? 'COPY'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: SlotBottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) context.go('/');
          if (index == 1) context.go('/explore');
          if (index == 2) context.go('/my-bookings');
          if (index == 4) context.go('/profile');
        },
        items: const [
          SlotNavItem(icon: Icons.home_rounded, label: 'Home'),
          SlotNavItem(icon: Icons.explore_outlined, label: 'Explore'),
          SlotNavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
          SlotNavItem(
              icon: Icons.confirmation_number_outlined, label: 'Offers'),
          SlotNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

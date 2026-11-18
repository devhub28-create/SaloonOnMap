import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/cubit/auth_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, bool> _values = {
    'booking_reminders': true,
    'hold_alerts': true,
    'promotions': true,
  };
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apiClient = context.read<AuthCubit>().apiClient;
    final prefs = await SharedPreferences.getInstance();
    final cached = <String, bool>{};
    for (final key in _values.keys) {
      cached[key] = prefs.getBool(key) ?? _values[key]!;
    }
    try {
      final profile = await apiClient.getCustomerProfile();
      final remote = profile['notificationPreferences'];
      if (remote is Map) {
        cached['booking_reminders'] = remote['bookingReminders'] != false;
        cached['hold_alerts'] = remote['holdAlerts'] != false;
        cached['promotions'] = remote['promotions'] != false;
      }
      for (final entry in cached.entries) {
        await prefs.setBool(entry.key, entry.value);
      }
    } catch (_) {
      _error = 'Showing saved preferences. Connect to update them.';
    }
    if (!mounted) return;
    setState(() {
      for (final key in _values.keys) {
        _values[key] = cached[key]!;
      }
      _isLoading = false;
    });
  }

  Future<void> _set(String key, bool value) async {
    final previous = _values[key]!;
    setState(() {
      _values[key] = value;
      _error = null;
    });
    final payloadKey = switch (key) {
      'booking_reminders' => 'bookingReminders',
      'hold_alerts' => 'holdAlerts',
      _ => 'promotions',
    };
    try {
      await context.read<AuthCubit>().apiClient.updateCustomerProfile({
        payloadKey: value,
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _values[key] = previous;
        _error = 'Could not save this preference. Please try again.';
      });
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Settings', style: AppTypography.screenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.statusDestructiveText),
              ),
            ),
          _tile(
            'booking_reminders',
            'Booking reminders',
            'Upcoming appointment alerts',
          ),
          _tile(
            'hold_alerts',
            'Seat hold alerts',
            'Warnings before a hold expires',
          ),
          _tile(
            'promotions',
            'Promos and discounts',
            'Offer and coupon notifications',
          ),
        ],
      ),
    );
  }

  Widget _tile(String key, String title, String subtitle) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      value: _values[key]!,
      onChanged: _isLoading ? null : (value) => _set(key, value),
    );
  }
}

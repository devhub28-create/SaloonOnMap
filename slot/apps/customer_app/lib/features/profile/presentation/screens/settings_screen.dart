import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    'whatsapp_receipts': false,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (final key in _values.keys) {
        _values[key] = prefs.getBool(key) ?? _values[key]!;
      }
    });
  }

  Future<void> _set(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (mounted) setState(() => _values[key] = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop()),
        title: const Text('Settings', style: AppTypography.screenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _tile('booking_reminders', 'Booking reminders',
              'Upcoming appointment alerts'),
          _tile('hold_alerts', 'Seat hold alerts',
              'Warnings before a hold expires'),
          _tile('promotions', 'Promos and discounts',
              'Offer and coupon notifications'),
          _tile('whatsapp_receipts', 'WhatsApp receipts',
              'Booking receipts sent to WhatsApp'),
        ],
      ),
    );
  }

  Widget _tile(String key, String title, String subtitle) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      value: _values[key]!,
      onChanged: (value) => _set(key, value),
    );
  }
}

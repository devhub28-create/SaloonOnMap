import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/customer_api_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'BOOKING';
  bool _loading = true;
  bool _sending = false;
  List<Map<String, dynamic>> _tickets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await CustomerApiService.instance.getMySupportTickets();
      if (mounted) {
        setState(() {
          _tickets = items
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_subject.text.trim().length < 3 || _message.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a subject and describe the issue.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await CustomerApiService.instance.createSupportTicket({
        'category': _category,
        'subject': _subject.text.trim(),
        'message': _message.text.trim(),
      });
      _subject.clear();
      _message.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support ticket created.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => context.pop(),
      ),
      title: const Text('Help & Support', style: AppTypography.screenTitle),
    ),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text('CONTACT SUPPORT', style: AppTypography.sectionEyebrow),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Issue category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'BOOKING', child: Text('Booking')),
                    DropdownMenuItem(
                      value: 'SALON',
                      child: Text('Salon experience'),
                    ),
                    DropdownMenuItem(value: 'PAYMENT', child: Text('Payment')),
                    DropdownMenuItem(value: 'ACCOUNT', child: Text('Account')),
                    DropdownMenuItem(
                      value: 'AI_STYLE',
                      child: Text('AI Style Studio'),
                    ),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => _category = value ?? 'OTHER'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subject,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _message,
                  maxLines: 5,
                  maxLength: 3000,
                  decoration: const InputDecoration(
                    labelText: 'How can we help?',
                    border: OutlineInputBorder(),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: const Icon(Icons.support_agent),
                  label: Text(_sending ? 'Sending…' : 'Create support ticket'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const Text('MY TICKETS', style: AppTypography.sectionEyebrow),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_tickets.isEmpty)
          const Text('No support tickets yet.')
        else
          ..._tickets.map(
            (ticket) => Card(
              child: ExpansionTile(
                leading: const Icon(Icons.confirmation_number_outlined),
                title: Text(ticket['subject']?.toString() ?? ''),
                subtitle: Text('${ticket['status']} · ${ticket['category']}'),
                children: [
                  for (final raw
                      in (ticket['messages'] as List<dynamic>? ?? const []))
                    Builder(
                      builder: (_) {
                        final item = Map<String, dynamic>.from(raw as Map);
                        return ListTile(
                          title: Text(item['sender_role']?.toString() ?? ''),
                          subtitle: Text(item['message']?.toString() ?? ''),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        const Text('QUICK HELP', style: AppTypography.sectionEyebrow),
        const ExpansionTile(
          title: Text('How does the seat hold work?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Your selected chair is held temporarily while you complete booking.',
              ),
            ),
          ],
        ),
        const ExpansionTile(
          title: Text('Can I cancel a booking?'),
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Upcoming bookings can be cancelled until 30 minutes before the scheduled start.',
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

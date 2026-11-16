import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/partner_api_service.dart';

class PartnerSupportScreen extends StatefulWidget {
  const PartnerSupportScreen({super.key});
  @override
  State<PartnerSupportScreen> createState() => _PartnerSupportScreenState();
}

class _PartnerSupportScreenState extends State<PartnerSupportScreen> {
  final _subject = TextEditingController();
  final _message = TextEditingController();
  String _category = 'SALON_OPERATIONS';
  bool _sending = false;
  bool _loading = true;
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
      final items = await PartnerApiService.instance.getMySupportTickets();
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
      return;
    }
    setState(() => _sending = true);
    try {
      await PartnerApiService.instance.createSupportTicket({
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new),
      ),
      title: const Text('Partner Support', style: AppTypography.screenTitle),
    ),
    body: ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text('SALON SUPPORT', style: AppTypography.sectionEyebrow),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'SALON_OPERATIONS',
                      child: Text('Salon operations'),
                    ),
                    DropdownMenuItem(
                      value: 'BOOKING',
                      child: Text('Booking issue'),
                    ),
                    DropdownMenuItem(
                      value: 'ACCOUNT',
                      child: Text('Account or approval'),
                    ),
                    DropdownMenuItem(
                      value: 'TECHNICAL',
                      child: Text('Technical issue'),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _category = v ?? 'SALON_OPERATIONS'),
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
                    labelText: 'Describe the issue',
                    border: OutlineInputBorder(),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: const Icon(Icons.support_agent),
                  label: Text(_sending ? 'Sending…' : 'Create ticket'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('MY TICKETS', style: AppTypography.sectionEyebrow),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_tickets.isEmpty)
          const Text('No support tickets yet.')
        else
          ..._tickets.map(
            (ticket) => Card(
              child: ListTile(
                leading: const Icon(Icons.confirmation_number_outlined),
                title: Text(ticket['subject']?.toString() ?? ''),
                subtitle: Text('${ticket['status']} · ${ticket['category']}'),
              ),
            ),
          ),
      ],
    ),
  );
}

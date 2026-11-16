import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/admin_ui.dart';
import 'package:design_system/design_system.dart';
import '../cubit/admin_offers_cubit.dart';

class AdminOffersScreen extends StatelessWidget {
  const AdminOffersScreen({super.key});

  Future<void> _showCreateOffer(BuildContext context) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<AdminOffersCubit>(),
        child: const _CreateOfferDialog(),
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offer published to the customer app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminOffersCubit, AdminOffersState>(
      builder: (context, state) {
        final offers = state is AdminOffersLoaded
            ? state.offers
            : <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            AdminPageHeader(
              eyebrow: 'Customer acquisition',
              title: 'Offers & promotions',
              description:
                  'Create customer-facing incentives, control availability, and monitor active platform promotions.',
              actions: [
                OutlinedButton.icon(
                  onPressed: state is AdminOffersLoading
                      ? null
                      : () => context.read<AdminOffersCubit>().fetchOffers(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
                FilledButton.icon(
                  onPressed: () => _showCreateOffer(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create offer'),
                )
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            if (state is AdminOffersLoading || state is AdminOffersInitial)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryGold)),
              )
            else if (state is AdminOffersError)
              AdminStatePanel.error(
                title: 'Offers unavailable',
                message: state.message,
                onAction: () => context.read<AdminOffersCubit>().fetchOffers(),
              )
            else if (offers.isEmpty)
              AdminStatePanel.empty(
                title: 'No offers yet',
                message:
                    'Create your first promotion to make it available in the customer app.',
                actionLabel: 'Create offer',
                onAction: () => _showCreateOffer(context),
              )
            else
              LayoutBuilder(builder: (context, constraints) {
                final width = constraints.maxWidth >= 1000
                    ? (constraints.maxWidth - 32) / 3
                    : constraints.maxWidth >= 640
                        ? (constraints.maxWidth - 16) / 2
                        : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: offers
                      .map((offer) => SizedBox(
                            width: width,
                            child: _OfferCard(offer: offer),
                          ))
                      .toList(),
                );
              }),
          ],
        );
      },
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;

  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final active = offer['is_active'] == true;
    final start =
        DateTime.tryParse(offer['valid_from']?.toString() ?? '')?.toLocal();
    final end =
        DateTime.tryParse(offer['valid_until']?.toString() ?? '')?.toLocal();
    final now = DateTime.now();
    final expired = end != null && end.isBefore(now);
    final upcoming = start != null && start.isAfter(now);
    final type = offer['discount_type']?.toString();
    final value = offer['discount_value'] ?? 0;
    final discount = type == 'PERCENTAGE' ? '$value% off' : '₹$value off';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.statusInServiceBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_offer_outlined,
                      color: AppColors.primaryGoldDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(offer['name']?.toString() ?? 'Offer',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(offer['code']?.toString() ?? '',
                          style: const TextStyle(
                              color: AppColors.primaryGoldDark,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1)),
                    ],
                  ),
                ),
                _OfferStatus(
                    label: expired
                        ? 'Expired'
                        : upcoming
                            ? 'Scheduled'
                            : active
                                ? 'Live'
                                : 'Paused',
                    active: active && !expired && !upcoming),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(discount,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${offer['scope'] ?? 'PLATFORM'} · Minimum ₹${offer['min_booking_amount'] ?? 0}',
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '${_date(start)} – ${_date(end)} · ${offer['current_usage_count'] ?? 0}/${offer['global_usage_limit'] ?? 0} used',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const Divider(height: 28),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(active ? 'Published' : 'Paused',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Controls customer-app visibility'),
              value: active,
              onChanged: expired
                  ? null
                  : (value) => context
                      .read<AdminOffersCubit>()
                      .setActive(offer['id'].toString(), value),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferStatus extends StatelessWidget {
  final String label;
  final bool active;

  const _OfferStatus({required this.label, required this.active});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.statusAvailableBg : const Color(0xFFF5F5F4),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: active
                    ? AppColors.statusAvailableText
                    : AppColors.textMuted)),
      );
}

class _CreateOfferDialog extends StatefulWidget {
  const _CreateOfferDialog();

  @override
  State<_CreateOfferDialog> createState() => _CreateOfferDialogState();
}

class _CreateOfferDialogState extends State<_CreateOfferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _discount = TextEditingController();
  final _minimum = TextEditingController(text: '0');
  String _discountType = 'PERCENTAGE';
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _discount.dispose();
    _minimum.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final current = start ? _start : _end;
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _start = selected;
        if (_end.isBefore(_start)) {
          _end = _start.add(const Duration(days: 30));
        }
      } else {
        _end = selected;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date.')),
      );
      return;
    }
    setState(() => _saving = true);
    final success = await context.read<AdminOffersCubit>().createOffer({
      'code': _code.text.trim().toUpperCase(),
      'name': _name.text.trim(),
      'discountType': _discountType,
      'discountValue': double.parse(_discount.text),
      'scope': 'PLATFORM',
      'minBookingAmount': double.tryParse(_minimum.text) ?? 0,
      'validFrom': DateTime(_start.year, _start.month, _start.day)
          .toUtc()
          .toIso8601String(),
      'validUntil': DateTime(_end.year, _end.month, _end.day, 23, 59, 59)
          .toUtc()
          .toIso8601String(),
      'globalUsageLimit': 1000,
      'perUserLimit': 1,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create customer offer'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Offer name', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                      labelText: 'Promo code', border: OutlineInputBorder()),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _discountType,
                        decoration: const InputDecoration(
                            labelText: 'Discount type',
                            border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(
                              value: 'PERCENTAGE', child: Text('Percentage')),
                          DropdownMenuItem(
                              value: 'FIXED', child: Text('Fixed amount')),
                        ],
                        onChanged: (value) =>
                            setState(() => _discountType = value!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _discount,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Discount value',
                            border: OutlineInputBorder()),
                        validator: (value) {
                          final number = double.tryParse(value ?? '');
                          if (number == null || number <= 0) {
                            return 'Enter a valid value';
                          }
                          if (_discountType == 'PERCENTAGE' && number > 100) {
                            return 'Maximum is 100';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minimum,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Minimum booking amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text('Starts ${_date(_start)}'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: OutlinedButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text('Ends ${_date(_end)}'),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.publish_rounded),
          label: const Text('Publish offer'),
        ),
      ],
    );
  }
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;

String _date(DateTime? value) => value == null
    ? '—'
    : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import '../cubit/partner_services_cubit.dart';

class ServiceModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final int durationMinutes;
  bool isAvailable;

  ServiceModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.durationMinutes,
    this.isAvailable = true,
  });
}

class ComboModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String discountTag;

  ComboModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.discountTag,
  });
}

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  int _selectedTab = 0; // 0: Services, 1: Combos

  void _showAddServiceModal(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController(text: '30');
    final categoryController = TextEditingController(text: 'Hair');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Salon Service', style: AppTypography.screenTitle),
              const SizedBox(height: 16),
              const Text('SERVICE NAME', style: AppTypography.sectionEyebrow),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                decoration: InputDecoration(
                  hintText: 'e.g. Royal Beard Trim',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PRICE (₹)', style: AppTypography.sectionEyebrow),
                        const SizedBox(height: 6),
                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                          decoration: InputDecoration(
                            hintText: '350',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DURATION (MINS)', style: AppTypography.sectionEyebrow),
                        const SizedBox(height: 6),
                        TextField(
                          controller: durationController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                          decoration: InputDecoration(
                            hintText: '30',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SlotPrimaryButton(
                text: 'Save Service to Menu',
                onPressed: () {
                  final name = nameController.text.trim();
                  final price = double.tryParse(priceController.text.trim());

                  if (name.isEmpty || price == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter service name and valid price.')),
                    );
                    return;
                  }

                  context.read<PartnerServicesCubit>().addService(
                        name: name,
                        category: categoryController.text.trim().isEmpty ? 'Hair' : categoryController.text.trim(),
                        price: price,
                        durationMinutes: int.tryParse(durationController.text.trim()) ?? 30,
                      );

                  Navigator.pop(modalContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name added to menu.')),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddComboModal(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final discountController = TextEditingController(text: 'SAVE 20%');
    final Set<String> selectedServiceIds = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final state = context.watch<PartnerServicesCubit>().state;
            final servicesList = state is PartnerServicesLoadedState ? state.services : <ServiceModel>[];

            final selectedServices = servicesList.where((s) => selectedServiceIds.contains(s.id)).toList();
            final autoDescription = selectedServices.map((s) => s.name).join(' + ');
            final originalTotalPrice = selectedServices.fold(0.0, (sum, s) => sum + s.price);

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Create Power Combo Offer', style: AppTypography.screenTitle),
                    const SizedBox(height: 16),
                    const Text('COMBO NAME', style: AppTypography.sectionEyebrow),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                      decoration: InputDecoration(
                        hintText: 'e.g. Executive Grooming Package',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Predefined Service Checkbox Selector
                    const Text('SELECT INCLUDED SERVICES', style: AppTypography.sectionEyebrow),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: servicesList.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.borderLight),
                        itemBuilder: (context, index) {
                          final service = servicesList[index];
                          final isSelected = selectedServiceIds.contains(service.id);
                          return CheckboxListTile(
                            activeColor: AppColors.primaryGoldDark,
                            title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkNeutral)),
                            subtitle: Text('₹${service.price.toInt()} · ${service.durationMinutes} mins', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            value: isSelected,
                            onChanged: (bool? checked) {
                              setModalState(() {
                                if (checked == true) {
                                  selectedServiceIds.add(service.id);
                                } else {
                                  selectedServiceIds.remove(service.id);
                                }

                                final newSel = servicesList.where((s) => selectedServiceIds.contains(s.id)).toList();
                                final newTotal = newSel.fold(0.0, (sum, s) => sum + s.price);
                                if (newTotal > 0) {
                                  final discounted = (newTotal * 0.8).roundToDouble();
                                  priceController.text = discounted.toInt().toString();
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (selectedServices.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Includes: $autoDescription',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.darkNeutral),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Original Sum: ₹${originalTotalPrice.toInt()}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('OFFER PRICE (₹)', style: AppTypography.sectionEyebrow),
                              const SizedBox(height: 6),
                              TextField(
                                controller: priceController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                                decoration: InputDecoration(
                                  hintText: '699',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DISCOUNT TAG', style: AppTypography.sectionEyebrow),
                              const SizedBox(height: 6),
                              TextField(
                                controller: discountController,
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                                decoration: InputDecoration(
                                  hintText: 'SAVE 20%',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SlotPrimaryButton(
                      text: 'Publish Combo Offer',
                      onPressed: () {
                        final name = nameController.text.trim();
                        final price = double.tryParse(priceController.text.trim());

                        if (name.isEmpty || price == null || selectedServiceIds.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select at least 1 service, enter combo name and valid offer price.')),
                          );
                          return;
                        }

                        context.read<PartnerServicesCubit>().addCombo(
                              name: name,
                              description: autoDescription,
                              price: price,
                              discountTag: discountController.text.trim().toUpperCase(),
                            );

                        Navigator.pop(modalContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$name combo published!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PartnerServicesCubit, PartnerServicesState>(
      builder: (context, state) {
        final services = state is PartnerServicesLoadedState ? state.services : <ServiceModel>[];
        final combos = state is PartnerServicesLoadedState ? state.combos : <ComboModel>[];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('MENU MANAGEMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.1)),
                SizedBox(height: 2),
                Text('Services & Combos', style: AppTypography.screenTitle),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [AppShadows.cardShadow],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, color: AppColors.darkNeutral, size: 22),
                  onPressed: () {
                    if (_selectedTab == 0) {
                      _showAddServiceModal(context);
                    } else {
                      _showAddComboModal(context);
                    }
                  },
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tabs: Services vs Combos
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Column(
                          children: [
                            Text(
                              'Services (${services.length})',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _selectedTab == 0 ? AppColors.darkNeutral : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 2,
                              color: _selectedTab == 0 ? AppColors.primaryGoldDark : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Column(
                          children: [
                            Text(
                              'Power Combos (${combos.length})',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _selectedTab == 1 ? AppColors.darkNeutral : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: 2,
                              color: _selectedTab == 1 ? AppColors.primaryGoldDark : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                if (_selectedTab == 0) ...[
                  if (services.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.content_cut_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text('No Services Added Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNeutral)),
                            const SizedBox(height: 4),
                            const Text('Tap the + button in the top right to add your salon service & price.', style: TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  else
                    for (var service in services)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: const [AppShadows.cardShadow],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(service.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.darkNeutral)),
                                const SizedBox(height: 2),
                                Text('₹${service.price.toInt()} · ${service.durationMinutes} mins', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                              ],
                            ),
                            Switch(
                              value: service.isAvailable,
                              activeTrackColor: AppColors.primaryGoldDark,
                              onChanged: (val) {
                                context.read<PartnerServicesCubit>().toggleServiceAvailability(service.id);
                              },
                            ),
                          ],
                        ),
                      ),
                ] else ...[
                  // Power Combos List
                  if (combos.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            const Text('No Power Combos Created Yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNeutral)),
                            const SizedBox(height: 4),
                            const Text('Tap the + button in the top right to bundle services into a combo offer.', style: TextStyle(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    )
                  else
                    for (var combo in combos)
                      Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.darkNeutral,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [AppShadows.cardShadow],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    combo.discountTag,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.darkNeutral),
                                  ),
                                ),
                                Row(
                                  children: [
                                    if (combo.originalPrice != null &&
                                        combo.originalPrice! > combo.price) ...[
                                      Text(
                                        '₹${combo.originalPrice!.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white54,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: Colors.white70,
                                          decorationThickness: 1.8,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      '₹${combo.price.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(combo.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(combo.description, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                      ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

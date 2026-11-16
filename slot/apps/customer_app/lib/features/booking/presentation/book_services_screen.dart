import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../cubit/booking_cubit.dart';

class BookServicesScreen extends StatefulWidget {
  const BookServicesScreen({super.key});

  @override
  State<BookServicesScreen> createState() => _BookServicesScreenState();
}

class _BookServicesScreenState extends State<BookServicesScreen> {
  List<Map<String, dynamic>> _availableCatalog = [];
  final Map<String, bool> _selectedMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    if (mounted) {
      final selected = context.read<BookingCubit>().selectedServices;
      setState(() {
        _availableCatalog = selected.map(Map<String, dynamic>.from).toList();
        for (final service in _availableCatalog) {
          _selectedMap[service['id'].toString()] = true;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = _availableCatalog
        .where((item) => _selectedMap[item['id']?.toString()] == true)
        .toList();
    final totalDuration = selectedItems.fold<int>(
        0,
        (sum, item) =>
            sum +
            (int.tryParse(item['duration_minutes']?.toString() ?? '0') ??
                (item['duration_minutes'] is num
                    ? (item['duration_minutes'] as num).toInt()
                    : 0)));
    final totalPrice = selectedItems.fold<int>(
        0,
        (sum, item) =>
            sum +
            (double.tryParse(item['price']?.toString() ?? '0')?.toInt() ??
                (item['price'] is num
                    ? (item['price'] as num).toInt()
                    : 0)));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Book your chair', style: AppTypography.screenTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step Progress Indicator (1 active)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stepDot(1, active: true),
                _stepLine(),
                _stepDot(2, active: false),
                _stepLine(),
                _stepDot(3, active: false),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Services Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SELECTED SERVICES',
                      style: AppTypography.sectionEyebrow),
                  const SizedBox(height: AppSpacing.md),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ..._availableCatalog.map((item) {
                      final id = item['id'].toString();
                      final name = item['name'].toString();
                      final duration = formatDuration(item['duration_minutes']);
                      final price = '₹${item['price']}';
                      return Column(
                        children: [
                          _selectableItem(id, name, duration, price),
                          const Divider(),
                        ],
                      );
                    }),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${formatDuration(totalDuration)} total duration',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMuted)),
                      Text('₹$totalPrice',
                          style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNeutral)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: SlotPrimaryButton(
          text: 'Choose date & time →',
          onPressed: () {
            if (selectedItems.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Select at least one service.')));
              return;
            }
            context.read<BookingCubit>().selectedServices = selectedItems;
            context.push('/book-seat');
          },
        ),
      ),
    );
  }

  Widget _selectableItem(
      String id, String name, String duration, String price) {
    final isSelected = _selectedMap[id] ?? false;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedMap[id] = !isSelected;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.add_circle_outline_rounded,
              color:
                  isSelected ? AppColors.primaryGoldDark : AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14)),
                  Text(duration,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            Text(price,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _stepDot(int number, {bool active = false}) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: active ? AppColors.primaryGold : const Color(0xFFEFECE6),
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: active ? AppColors.darkNeutral : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _stepLine() {
    return Container(
      width: 40,
      height: 2,
      color: const Color(0xFFEFECE6),
    );
  }
}

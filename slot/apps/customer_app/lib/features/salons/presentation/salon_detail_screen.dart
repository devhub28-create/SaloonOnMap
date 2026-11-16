import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../booking/cubit/booking_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:api_client/api_client.dart';

class SalonDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? salonData;
  const SalonDetailScreen({super.key, this.salonData});

  @override
  State<SalonDetailScreen> createState() => _SalonDetailScreenState();
}

class _SalonDetailScreenState extends State<SalonDetailScreen> {
  Map<String, dynamic>? _salon;
  List<dynamic> _services = [];
  List<dynamic> _combos = [];
  List<dynamic> _reviewsList = [];
  bool _isLoading = true;
  String? _error;
  bool _isFavorite = false;
  final Set<String> _selectedItemIds = {};
  int _activeCategoryIndex = 0; // 0: All, 1: Combos, 2: Services

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final apiClient = context.read<AuthCubit>().apiClient;
      final nestedSalon = widget.salonData?['salon'];
      final salonId = widget.salonData?['salonId'] ??
          widget.salonData?['id'] ??
          (nestedSalon is Map ? nestedSalon['id'] : null);
      if (salonId == null || salonId.toString().isEmpty) {
        throw StateError('No salon was selected.');
      }
      final data = await apiClient.getSalonDetails(salonId.toString());
      if (mounted) {
        final preselectedId = widget.salonData?['selectedServiceId']?.toString();
        setState(() {
          _salon = Map<String, dynamic>.from(data['salon'] as Map? ?? data);
          _services = List<dynamic>.from(data['services'] ?? const []);
          _combos = List<dynamic>.from(data['combos'] ?? const []);
          _reviewsList = List<dynamic>.from(data['reviews'] ?? const []);
          if (preselectedId != null && preselectedId.isNotEmpty) {
            _selectedItemIds.add(preselectedId);
          }
          _isLoading = false;
        });
        final prefs = await SharedPreferences.getInstance();
        final favorites = prefs.getStringList('favorite_salon_ids') ?? const [];
        if (mounted) {
          setState(() => _isFavorite = favorites.contains(salonId.toString()));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  double _calculateTotalPrice() {
    double total = 0.0;
    for (final s in _services) {
      final id = s['id']?.toString() ?? '';
      if (_selectedItemIds.contains(id)) {
        total += double.tryParse(s['price']?.toString() ?? '0') ?? 0.0;
      }
    }
    for (final c in _combos) {
      final id = c['id']?.toString() ?? '';
      if (_selectedItemIds.contains(id)) {
        total += double.tryParse(c['price']?.toString() ?? '0') ?? 0.0;
      }
    }
    return total;
  }

  List<Map<String, dynamic>> _getNormalizedSelectedItems() {
    final list = <Map<String, dynamic>>[];
    for (final s in _services) {
      final id = s['id']?.toString() ?? '';
      if (_selectedItemIds.contains(id)) {
        final catalog =
            s['service'] is Map ? s['service'] as Map : const {};
        final priceVal = double.tryParse(s['price']?.toString() ?? '0')?.toInt() ??
            (s['price'] is num ? (s['price'] as num).toInt() : 0);
        final durVal = int.tryParse(s['duration_minutes']?.toString() ?? '30') ?? 30;
        list.add({
          'id': id,
          'name': catalog['name'] ?? s['name'] ?? 'Service',
          'price': priceVal,
          'duration_minutes': durVal,
        });
      }
    }
    for (final c in _combos) {
      final id = c['id']?.toString() ?? '';
      if (_selectedItemIds.contains(id)) {
        final priceVal = double.tryParse(c['price']?.toString() ?? '0')?.toInt() ??
            (c['price'] is num ? (c['price'] as num).toInt() : 0);
        final durVal = int.tryParse(c['duration_minutes']?.toString() ?? '45') ?? 45;
        list.add({
          'id': id,
          'name': 'Combo: ${c['name'] ?? 'Package'}',
          'price': priceVal,
          'duration_minutes': durVal,
        });
      }
    }
    return list;
  }

  void _proceedToBooking({List<Map<String, dynamic>>? specificItems}) {
    final salonId = _salon?['id']?.toString();
    final name = _salon?['name'] ?? 'Salon';
    final itemsToBook = specificItems ?? _getNormalizedSelectedItems();

    if (salonId == null || itemsToBook.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one service or combo.')),
      );
      return;
    }

    context
        .read<BookingCubit>()
        .selectSalon(salonId, name.toString(), itemsToBook);
    context.push('/book-services');
  }

  @override
  Widget build(BuildContext context) {
    final name = _salon?['name'] ?? 'Salon';
    final address = [_salon?['address'], _salon?['city']]
        .where((value) => value != null && value.toString().isNotEmpty)
        .join(', ');
    final rating = (_salon?['rating'] ?? 0).toString();
    final reviews = (_salon?['review_count'] ?? 0).toString();
    final closingTime = _salon?['closing_time'] ?? '';

    final showCombos =
        _activeCategoryIndex == 0 || _activeCategoryIndex == 1;
    final showServices =
        _activeCategoryIndex == 0 || _activeCategoryIndex == 2;

    final selectedCount = _selectedItemIds.length;
    final totalPrice = _calculateTotalPrice();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.background,
            actions: [
              IconButton(
                icon: Icon(
                  _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _isFavorite ? Colors.red : AppColors.darkNeutral,
                ),
                onPressed: () async {
                  final salonId = _salon?['id']?.toString();
                  if (salonId == null) return;
                  final prefs = await SharedPreferences.getInstance();
                  final favorites =
                      (prefs.getStringList('favorite_salon_ids') ?? const [])
                          .toSet();
                  if (_isFavorite) {
                    favorites.remove(salonId);
                  } else {
                    favorites.add(salonId);
                  }
                  await prefs.setStringList(
                      'favorite_salon_ids', favorites.toList());
                  if (!context.mounted) return;
                  setState(() => _isFavorite = !_isFavorite);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(_isFavorite
                            ? '$name added to Favorites.'
                            : '$name removed from Favorites.')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                ApiConfig.formatImageUrl(_salon?['cover_image']?.toString()),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallbackCover(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.screenTitle),
                  const SizedBox(height: 4),
                  Text(address, style: AppTypography.bodyText),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: AppColors.primaryGoldDark),
                      const SizedBox(width: 4),
                      Text('$rating ($reviews reviews)',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_rounded,
                          size: 14, color: AppColors.statusAvailableText),
                      const SizedBox(width: 4),
                      Text('Open until $closingTime',
                          style: const TextStyle(
                              color: AppColors.statusAvailableText,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Quick Action Buttons (Share, Call, Directions)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(Icons.share_outlined, 'Share', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Sharing $name ($address)...')),
                        );
                      }),
                      _actionButton(Icons.call_outlined, 'Call', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Opening dialer for +91 98765 43210...')),
                        );
                      }),
                      _actionButton(Icons.directions_outlined, 'Directions',
                          () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Opening Maps for $address...')),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Filter / Category Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip(
                          index: 0,
                          label: 'All (${_combos.length + _services.length})',
                        ),
                        const SizedBox(width: 8),
                        if (_combos.isNotEmpty) ...[
                          _buildCategoryChip(
                            index: 1,
                            label: 'Combos & Deals (${_combos.length})',
                            icon: Icons.local_offer_rounded,
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildCategoryChip(
                          index: 2,
                          label: 'Services (${_services.length})',
                          icon: Icons.content_cut_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_error != null)
                    Text(_error!,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.statusDestructiveText))
                  else ...[
                    // 1. COMBOS SECTION
                    if (showCombos && _combos.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.local_offer_rounded,
                              size: 18, color: AppColors.primaryGoldDark),
                          const SizedBox(width: 8),
                          const Text(
                            'Combos & Value Packages',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNeutral,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'VALUE PACKS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGoldDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ..._combos.map((combo) => _buildComboCard(combo)),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // 2. INDIVIDUAL SERVICES SECTION
                    if (showServices) ...[
                      Row(
                        children: [
                          const Icon(Icons.spa_rounded,
                              size: 18, color: AppColors.darkNeutral),
                          const SizedBox(width: 8),
                          Text(
                            _activeCategoryIndex == 2
                                ? 'Individual Services'
                                : 'Available Services',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNeutral,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_services.isEmpty)
                        const Text(
                          'No individual services available for this salon.',
                          style: TextStyle(color: AppColors.textMuted),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final svc = _services[index];
                            final id = svc['id']?.toString() ?? '';
                            final service = svc['service'] is Map
                                ? svc['service'] as Map
                                : const {};
                            final svcName = (service['name'] ??
                                    svc['name'] ??
                                    'Service')
                                .toString();
                            final dur = formatDuration(svc['duration_minutes']);
                            final price = '₹${svc['price'] ?? 0}';
                            final isAdded = _selectedItemIds.contains(id);

                            return _serviceTile(
                              id,
                              svcName,
                              dur,
                              price,
                              isAdded: isAdded,
                              onToggle: () {
                                setState(() {
                                  if (isAdded) {
                                    _selectedItemIds.remove(id);
                                  } else {
                                    _selectedItemIds.add(id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                    ],

                    if (_combos.isEmpty && _services.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'This salon has no services or packages listed right now.',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ),
                  ],

                  // 3. REVIEWS & RATINGS SECTION
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 20, color: AppColors.primaryGoldDark),
                          const SizedBox(width: 8),
                          Text(
                            'Customer Reviews (${_reviewsList.length})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNeutral,
                            ),
                          ),
                        ],
                      ),
                      if (_reviewsList.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 14, color: AppColors.primaryGoldDark),
                              const SizedBox(width: 2),
                              Text(
                                rating,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNeutral,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_reviewsList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 28, color: AppColors.textMuted),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No reviews yet. Be the first to leave a review after your visit!',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._reviewsList.map((r) => _buildReviewCard(r)),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
          border: Border(top: BorderSide(color: AppColors.borderLight)),
        ),
        child: SlotPrimaryButton(
          text: selectedCount > 0
              ? 'Book a seat ($selectedCount selected • ₹${totalPrice.toInt()})'
              : 'Book a seat',
          onPressed: () => _proceedToBooking(),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required int index,
    required String label,
    IconData? icon,
  }) {
    final isSelected = _activeCategoryIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeCategoryIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.darkNeutral : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.darkNeutral : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.primaryGold : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.darkNeutral,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(dynamic r) {
    final customerName = (r['customer_name'] ?? 'Customer').toString();
    final ratingNum = (r['rating'] is num ? (r['rating'] as num).toInt() : 5);
    final comment = (r['comment'] ?? '').toString();
    final tags =
        r['tags'] is List ? List<dynamic>.from(r['tags']) : <dynamic>[];
    final dateStr = r['created_at'] != null &&
            DateTime.tryParse(r['created_at'].toString()) != null
        ? '${DateTime.tryParse(r['created_at'].toString())!.day}/${DateTime.tryParse(r['created_at'].toString())!.month}/${DateTime.tryParse(r['created_at'].toString())!.year}'
        : 'Recent visit';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [AppShadows.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                customerName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.darkNeutral,
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              return Icon(
                i < ratingNum ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 16,
                color: AppColors.primaryGoldDark,
              );
            }),
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.darkNeutral),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tag.toString(),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComboCard(Map<String, dynamic> combo) {
    final id = combo['id']?.toString() ?? '';
    final name = combo['name']?.toString() ?? 'Combo Package';
    final desc = combo['description']?.toString() ?? '';
    final duration = formatDuration(combo['duration_minutes']);
    final price = double.tryParse(combo['price']?.toString() ?? '0') ?? 0.0;
    final rawOrig = double.tryParse(
        (combo['original_price'] ?? combo['originalPrice'])?.toString() ?? '0');
    final origPrice = (rawOrig != null && rawOrig > price)
        ? rawOrig
        : (price * 1.25).roundToDouble();
    final isBestseller = combo['is_bestseller'] == true;
    final isAdded = _selectedItemIds.contains(id);

    final hasDiscount = origPrice > price;
    final savings = hasDiscount ? (origPrice - price).toInt() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isAdded ? AppColors.primaryGoldDark : const Color(0xFFFDE68A),
          width: isAdded ? 2 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isBestseller) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '★ BESTSELLER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.timer_outlined,
                                  size: 11, color: AppColors.primaryGoldDark),
                              const SizedBox(width: 3),
                              Text(
                                duration,
                                style: const TextStyle(
                                  color: AppColors.primaryGoldDark,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNeutral,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isAdded) {
                      _selectedItemIds.remove(id);
                    } else {
                      _selectedItemIds.add(id);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isAdded
                        ? AppColors.primaryGoldDark
                        : const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGoldDark,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdded ? Icons.check_rounded : Icons.add_rounded,
                        size: 14,
                        color: isAdded ? Colors.white : AppColors.darkNeutral,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAdded ? 'ADDED' : 'ADD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAdded ? Colors.white : AppColors.darkNeutral,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: AppColors.primaryGoldDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      desc,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasDiscount) ...[
                Text(
                  '₹${origPrice.toInt()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: AppColors.textMuted,
                    decorationThickness: 1.8,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                '₹${price.toInt()}',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkNeutral,
                ),
              ),
              if (hasDiscount && savings > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Save ₹$savings',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: () {
                  _proceedToBooking(
                    specificItems: [
                      {
                        'id': id,
                        'name': 'Combo: $name',
                        'price': price.toInt(),
                        'duration_minutes':
                            int.tryParse(combo['duration_minutes']?.toString() ?? '45') ?? 45,
                      }
                    ],
                  );
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Book Combo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldDark,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.primaryGoldDark),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.darkNeutral),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNeutral)),
          ],
        ),
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF1A1A24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_rounded, size: 70, color: AppColors.primaryGold),
            SizedBox(height: 8),
            Text(
              'SLOT Premium Salon',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _serviceTile(String id, String name, String duration, String price,
      {required bool isAdded, required VoidCallback onToggle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isAdded ? AppColors.primaryGoldDark : AppColors.borderLight,
          width: isAdded ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(duration,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Row(
            children: [
              Text(price,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isAdded
                        ? AppColors.primaryGoldDark
                        : const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primaryGoldDark,
                    ),
                  ),
                  child: Text(
                    isAdded ? 'ADDED' : 'ADD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color:
                          isAdded ? Colors.white : AppColors.darkNeutral,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

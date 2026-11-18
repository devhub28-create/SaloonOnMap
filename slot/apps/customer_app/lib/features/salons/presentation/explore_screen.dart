import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:api_client/api_client.dart';

import '../../auth/cubit/auth_cubit.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<dynamic> _salons = [];
  bool _isLoading = true;
  String? _error;
  int _selectedFilterIndex = 0;
  String _sortBy = 'nearest';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _selectedArea = 'Indiranagar, Bengaluru';
  double? _userLat = 12.9784;
  double? _userLng = 77.6408;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _detectUserLocation(showToast: false);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _detectUserLocation({bool showToast = false}) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 4),
        );
        final lat = position.latitude;
        final lng = position.longitude;

        String locationLabel = 'Indiranagar, Bengaluru';
        try {
          final dio = Dio();
          final response = await dio
              .get(
                'https://nominatim.openstreetmap.org/reverse',
                queryParameters: {'format': 'json', 'lat': lat, 'lon': lng},
                options: Options(headers: {'User-Agent': 'SlotApp/1.0'}),
              )
              .timeout(const Duration(seconds: 3));

          if (response.data != null && response.data['address'] != null) {
            final addr = response.data['address'];
            final suburb =
                addr['suburb'] ?? addr['neighbourhood'] ?? addr['subdistrict'];
            final city =
                addr['city'] ?? addr['town'] ?? addr['county'] ?? 'Bengaluru';
            locationLabel = suburb != null ? '$suburb, $city' : city;
          }
        } catch (_) {
          if (lat >= 22.0 && lat <= 23.5 && lng >= 75.0 && lng <= 76.5) {
            locationLabel = 'Vijay Nagar, Indore';
          } else {
            locationLabel = 'Indiranagar, Bengaluru';
          }
        }

        if (mounted) {
          setState(() {
            _selectedArea = locationLabel;
            _userLat = lat;
            _userLng = lng;
          });
          if (showToast) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '📍 Location detected: $locationLabel! Salons updated by distance.',
                ),
                backgroundColor: AppColors.darkNeutral,
              ),
            );
          }
        }
        _fetchSalons();
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _selectedArea = 'Indiranagar, Bengaluru';
        _userLat = 12.9784;
        _userLng = 77.6408;
      });
      if (showToast) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Location set: Indiranagar, Bengaluru'),
            backgroundColor: AppColors.darkNeutral,
          ),
        );
      }
    }
    _fetchSalons();
  }

  Future<void> _fetchSalons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiClient = context.read<AuthCubit>().apiClient;
      final salons = await apiClient.getSalons(
        lat: _userLat,
        lng: _userLng,
        area: _selectedArea,
      );
      if (mounted) {
        setState(() {
          _salons = salons;
          _isLoading = false;
        });
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

  bool _isOpenNow(Map<dynamic, dynamic> salon) {
    final opening = _parseTime(salon['opening_time']?.toString());
    final closing = _parseTime(salon['closing_time']?.toString());
    if (opening == null || closing == null) return false;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final opensAt = opening.$1 * 60 + opening.$2;
    final closesAt = closing.$1 * 60 + closing.$2;
    return closesAt >= opensAt
        ? nowMinutes >= opensAt && nowMinutes < closesAt
        : nowMinutes >= opensAt || nowMinutes < closesAt;
  }

  (int, int)? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  String? _formatTime(String? raw) {
    final parsed = _parseTime(raw);
    if (parsed == null) return null;
    final suffix = parsed.$1 >= 12 ? 'PM' : 'AM';
    final hour = parsed.$1 % 12 == 0 ? 12 : parsed.$1 % 12;
    return '$hour:${parsed.$2.toString().padLeft(2, '0')} $suffix';
  }

  List<dynamic> get _displayedSalons {
    final search = _searchController.text.trim().toLowerCase();
    final salons = _salons.where((salon) {
      final data = salon as Map;
      final matchesSearch = search.isEmpty ||
          [data['name'], data['area'], data['city']]
              .whereType<Object>()
              .join(' ')
              .toLowerCase()
              .contains(search);
      if (!matchesSearch) return false;
      if (_selectedFilterIndex == 1) {
        return (double.tryParse((data['rating'] ?? '').toString()) ?? 0) >= 4.5;
      }
      if (_selectedFilterIndex == 2) return _isOpenNow(data);
      return true;
    }).toList();

    switch (_sortBy) {
      case 'rating':
        salons.sort(
          (a, b) =>
              (double.tryParse((b['rating'] ?? '').toString()) ?? 0).compareTo(
            double.tryParse((a['rating'] ?? '').toString()) ?? 0,
          ),
        );
      case 'name':
        salons.sort(
          (a, b) => (a['name'] ?? '').toString().compareTo(
                (b['name'] ?? '').toString(),
              ),
        );
      default:
        salons.sort(
          (a, b) => (double.tryParse((a['distanceKm'] ?? '').toString()) ??
                  double.infinity)
              .compareTo(
            double.tryParse((b['distanceKm'] ?? '').toString()) ??
                double.infinity,
          ),
        );
    }
    return salons;
  }

  String get _sortLabel => switch (_sortBy) {
        'rating' => 'Top rated',
        'name' => 'A–Z',
        _ => 'Nearest',
      };

  @override
  Widget build(BuildContext context) {
    final salonsToShow = _displayedSalons;
    final salonCount = salonsToShow.length;

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
            Text(
              'DISCOVER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 2),
            Text('Salons near you', style: AppTypography.screenTitle),
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
              icon: const Icon(
                Icons.my_location_rounded,
                color: AppColors.darkNeutral,
                size: 20,
              ),
              onPressed: () => _detectUserLocation(showToast: true),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search Bar with Filter Button (Matches media_1791349399167.png 100%)
            Container(
              padding: const EdgeInsets.only(
                left: 16,
                right: 8,
                top: 6,
                bottom: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: const [AppShadows.cardShadow],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: salonCount > 0
                            ? 'Search $salonCount salons nearby'
                            : 'Search salons, areas',
                        hintStyle: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sort salons',
                    onPressed: _showSortSheet,
                    icon: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: AppColors.darkNeutral,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 2. Horizontal Filter Pills Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(0, 'Nearby'),
                  _filterChip(1, 'Top rated'),
                  _filterChip(2, 'Open now'),
                  _sortChip(),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Interactive Map View Banner (Matches media_1791349399167.png 100%)
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3EFE6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Stylized Road Grid Map Lines
                    CustomPaint(
                      size: Size.infinite,
                      painter: _MapGridPainter(),
                    ),
                    // Map Pin Markers (Scissors Pins)
                    const Positioned(top: 40, left: 80, child: _MapPinMarker()),
                    const Positioned(
                      top: 25,
                      right: 90,
                      child: _MapPinMarker(),
                    ),
                    const Positioned(
                      bottom: 50,
                      left: 170,
                      child: _MapPinMarker(),
                    ),
                    // Bottom Floating Map Pill Badge
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [AppShadows.cardShadow],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.near_me_rounded,
                                size: 14,
                                color: AppColors.darkNeutral,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                salonCount > 0
                                    ? '$salonCount salons around you'
                                    : 'No salons nearby yet',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNeutral,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                Expanded(
                  child: Text(
                    _searchController.text.trim().isNotEmpty
                        ? 'Search results'
                        : _selectedFilterIndex == 1
                            ? 'Highly rated near you'
                            : _selectedFilterIndex == 2
                                ? 'Open now'
                                : 'Closest to you',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNeutral,
                    ),
                  ),
                ),
                Text(
                  '$salonCount ${salonCount == 1 ? 'salon' : 'salons'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // 5. Salon Cards List
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Text(
                  'Error loading salons: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (salonsToShow.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 40,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No partner salons registered yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNeutral,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Partner salons will appear here once registered.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: salonsToShow.length,
                itemBuilder: (context, index) {
                  final salon = salonsToShow[index];
                  final name = salon['name'] ?? 'Salon';
                  final area = salon['area'] ?? salon['city'] ?? 'Location';
                  final rating = (salon['rating'] ?? 5.0).toString();
                  final coverImage = salon['cover_image'];
                  final salonId = salon['id'];
                  final distanceStr = salon['formattedDistance'] ?? 'Nearby';

                  return GestureDetector(
                    onTap: () => context.push(
                      '/salon-detail',
                      extra: {'salonId': salonId, 'salon': salon},
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: const [AppShadows.cardShadow],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 90,
                              height: 90,
                              child: Image.network(
                                ApiConfig.formatImageUrl(
                                  coverImage?.toString(),
                                ),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _fallbackCover(),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkNeutral,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF9C3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: AppColors.primaryGoldDark,
                                          ),
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
                                const SizedBox(height: 2),
                                Text(
                                  '$area · $distanceStr',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _hoursLabel(salon),
                                const SizedBox(height: 8),
                                const Divider(
                                  height: 1,
                                  color: AppColors.borderLight,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _priceLabel(salon),
                                    _availabilityLabel(salon),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: SlotBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) context.go('/');
          if (index == 2) context.go('/my-bookings');
          if (index == 3) context.go('/offers');
          if (index == 4) context.go('/profile');
        },
        items: const [
          SlotNavItem(icon: Icons.home_rounded, label: 'Home'),
          SlotNavItem(icon: Icons.explore_outlined, label: 'Explore'),
          SlotNavItem(icon: Icons.calendar_today_rounded, label: 'Bookings'),
          SlotNavItem(
            icon: Icons.confirmation_number_outlined,
            label: 'Offers',
          ),
          SlotNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
        ],
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
        child: Icon(
          Icons.storefront_rounded,
          size: 36,
          color: AppColors.primaryGold,
        ),
      ),
    );
  }

  Widget _filterChip(int index, String label) {
    final active = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.darkNeutral : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.darkNeutral : AppColors.borderLight,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: active ? Colors.white : AppColors.darkNeutral,
          ),
        ),
      ),
    );
  }

  Widget _sortChip() => Semantics(
        button: true,
        label: 'Sort salons by $_sortLabel',
        child: InkWell(
          onTap: _showSortSheet,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.sort_rounded, size: 16),
                const SizedBox(width: 6),
                Text(
                  _sortLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _hoursLabel(Map<dynamic, dynamic> salon) {
    final closing = _formatTime(salon['closing_time']?.toString());
    final opening = _formatTime(salon['opening_time']?.toString());
    if (closing == null || opening == null) {
      return const Text(
        'Check hours with salon',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      );
    }
    final open = _isOpenNow(salon);
    return Text(
      open ? 'Open now · until $closing' : 'Closed · opens $opening',
      style: TextStyle(
        fontSize: 12,
        color: open ? AppColors.statusAvailableText : AppColors.textMuted,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _priceLabel(Map<dynamic, dynamic> salon) {
    final price = salon['starting_price'] ?? salon['startingPrice'];
    final numericPrice = double.tryParse(price?.toString() ?? '');
    return Text(
      numericPrice == null
          ? 'View services'
          : 'From ₹${numericPrice.toStringAsFixed(0)}',
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.darkNeutral,
      ),
    );
  }

  Widget _availabilityLabel(Map<dynamic, dynamic> salon) {
    final nextSlot = salon['next_available_time'] ?? salon['nextAvailableTime'];
    return Text(
      nextSlot == null ? 'See availability' : 'Next: $nextSlot',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFFD97706),
      ),
    );
  }

  Future<void> _showSortSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sort salons', style: AppTypography.screenTitle),
              const SizedBox(height: 8),
              const Text(
                'Choose how results are ordered.',
                style: TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              for (final option in const [
                ('nearest', 'Nearest', Icons.near_me_rounded),
                ('rating', 'Top rated', Icons.star_rounded),
                ('name', 'Name, A–Z', Icons.sort_by_alpha_rounded),
              ])
                ListTile(
                  leading: Icon(option.$3),
                  title: Text(option.$2),
                  trailing: _sortBy == option.$1
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primaryGoldDark,
                        )
                      : const Icon(Icons.circle_outlined),
                  onTap: () => Navigator.pop(context, option.$1),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) setState(() => _sortBy = selected);
  }
}

// Custom Painter for Map Grid Lines (Matches media_1791349399167.png)
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    // Diagonal main road 1
    final path1 = Path()
      ..moveTo(0, size.height * 0.8)
      ..lineTo(size.width * 0.9, 0);
    canvas.drawPath(path1, paint);

    // Diagonal main road 2
    final path2 = Path()
      ..moveTo(size.width * 0.35, 0)
      ..lineTo(size.width * 0.7, size.height);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Map Pin Marker Widget with Scissors Icon
class _MapPinMarker extends StatelessWidget {
  const _MapPinMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.darkNeutral,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [AppShadows.cardShadow],
      ),
      child: const Icon(
        Icons.content_cut_rounded,
        color: AppColors.primaryGold,
        size: 16,
      ),
    );
  }
}

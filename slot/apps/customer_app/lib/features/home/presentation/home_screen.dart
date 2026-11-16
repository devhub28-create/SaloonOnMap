import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/customer_api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:api_client/api_client.dart';
import '../../auth/cubit/auth_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedGenderIndex = 0; // 0: Men & Unisex, 1: Women
  List<dynamic> _salons = [];
  List<dynamic> _bookings = [];
  List<dynamic> _combos = [];
  List<dynamic> _popularServices = [];
  bool _isLoading = true;
  String _selectedArea = 'Indiranagar, Bengaluru';
  double? _userLat = 12.9784;
  double? _userLng = 77.6408;


  @override
  void initState() {
    super.initState();
    _detectUserLocation(showToast: false);
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

        final locationLabel = await CustomerApiService.instance.reverseGeocode(lat: lat, lng: lng);

        if (mounted) {
          setState(() {
            _selectedArea = locationLabel;
            _userLat = lat;
            _userLng = lng;
          });
          if (showToast) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('📍 Location detected: $locationLabel'),
                backgroundColor: AppColors.darkNeutral,
              ),
            );
          }
        }
        _fetchHomeData(gender: _selectedGenderIndex == 1 ? 'WOMEN' : 'MEN');
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
    _fetchHomeData(gender: _selectedGenderIndex == 1 ? 'WOMEN' : 'MEN');
  }

  Future<void> _fetchHomeData({String gender = 'MEN'}) async {
    setState(() => _isLoading = true);
    try {
      final apiClient = context.read<AuthCubit>().apiClient;
      final customerId = context.read<AuthCubit>().user?['id']?.toString();
      final homeData = await apiClient.getCustomerHome(
        gender: gender,
        lat: _userLat,
        lng: _userLng,
        area: _selectedArea,
      );
      final salons = await apiClient.getSalons(
        gender: gender,
        lat: _userLat,
        lng: _userLng,
        area: _selectedArea,
      );
      final bookings = customerId == null
          ? <dynamic>[]
          : await apiClient.getCustomerBookings(customerId: customerId);
      final combos = homeData['powerCombo'] == null
          ? <dynamic>[]
          : <dynamic>[homeData['powerCombo']];
      final popularServices = homeData['popularServices'] is List
          ? List<dynamic>.from(homeData['popularServices'])
          : <dynamic>[];
      if (mounted) {
        setState(() {
          _salons = homeData['recommendedSalons'] ?? salons;
          _bookings = bookings;
          _combos = combos;
          _popularServices = popularServices;
          if (homeData['userLocation'] != null &&
              homeData['userLocation']['area'] != null) {
            _selectedArea = homeData['userLocation']['area'].toString();
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showLocationPickerBottomSheet() {
    final areas = [
      {'name': 'Indiranagar, Bengaluru', 'lat': 12.9784, 'lng': 77.6408},
      {'name': 'Koramangala, Bengaluru', 'lat': 12.9352, 'lng': 77.6245},
      {'name': 'HSR Layout, Bengaluru', 'lat': 12.9121, 'lng': 77.6446},
      {'name': 'Vijay Nagar, Indore', 'lat': 22.7533, 'lng': 75.8937},
      {'name': 'Palasia, Indore', 'lat': 22.7244, 'lng': 75.8839},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Select Your Location',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkNeutral)),
            const SizedBox(height: 4),
            const Text('Salons will be ordered by distance from your location.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: AppSpacing.lg),
            InkWell(
              onTap: () {
                Navigator.of(ctx).pop();
                _detectUserLocation(showToast: true);
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryGoldDark),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.my_location_rounded,
                        color: AppColors.primaryGoldDark, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Detect My Location',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkNeutral)),
                          Text('Use GPS to find closest salons near you',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('POPULAR NEIGHBORHOODS',
                style: AppTypography.sectionEyebrow),
            const SizedBox(height: AppSpacing.md),
            ...areas.map((a) {
              final isSelected = _selectedArea.contains(a['name'] as String);
              return InkWell(
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _selectedArea = a['name'] as String;
                    _userLat = a['lat'] as double;
                    _userLng = a['lng'] as double;
                  });
                  _fetchHomeData(
                      gender: _selectedGenderIndex == 1 ? 'WOMEN' : 'MEN');
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFEF9C3) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGoldDark
                            : AppColors.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 18,
                              color: isSelected
                                  ? AppColors.primaryGoldDark
                                  : AppColors.textMuted),
                          const SizedBox(width: 10),
                          Text(a['name'] as String,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500)),
                        ],
                      ),
                      if (isSelected)
                        const Icon(Icons.check_rounded,
                            size: 18, color: AppColors.primaryGoldDark),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final userName = authState is AuthAuthenticatedState
        ? authState.user['name'] ?? 'Customer'
        : 'Customer';
    final userInitials =
        userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'C';
    final activeBooking = _bookings.isNotEmpty ? _bookings.first : null;
    final featuredSalon = _salons.isNotEmpty ? _salons.first : null;

    final isWomenTheme = _selectedGenderIndex == 1;
    final themeBgColor =
        isWomenTheme ? const Color(0xFFFFF7F9) : AppColors.background;
    final primaryAccentColor =
        isWomenTheme ? const Color(0xFFEC4899) : AppColors.primaryGold;
    final secondaryBadgeColor =
        isWomenTheme ? const Color(0xFFFCE7F3) : const Color(0xFFFEF9C3);

    return Scaffold(
      backgroundColor: themeBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Eyebrow, Location & Profile Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GOOD AFTERNOON',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted,
                                letterSpacing: 1.1)),
                        const SizedBox(height: 2),
                        Text('Hey, $userName',
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkNeutral)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _showLocationPickerBottomSheet,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 16, color: primaryAccentColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$_selectedArea >',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkNeutral),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Notification Bell with Red Dot
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_none_rounded,
                                  color: AppColors.darkNeutral, size: 20),
                              onPressed: () =>
                                  context.push('/profile/notifications'),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: primaryAccentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // User Initials or Login Badge
                      Builder(
                        builder: (ctx) {
                          final isAuth = ctx.watch<AuthCubit>().isAuthenticated;
                          if (!isAuth) {
                            return GestureDetector(
                              onTap: () => ctx.push('/login'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.darkNeutral,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0x4DC89300)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.login_rounded,
                                        size: 14,
                                        color: AppColors.primaryGold),
                                    SizedBox(width: 4),
                                    Text(
                                      'Login',
                                      style: TextStyle(
                                        color: AppColors.primaryGold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          return GestureDetector(
                            onTap: () => ctx.push('/profile'),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.darkNeutral,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  userInitials == 'A' ? 'AT' : userInitials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. Search Bar with Filter Button (Matches media_1791347258505.png & media_1791347258527.png)
              GestureDetector(
                onTap: () => context.push('/explore'),
                child: Container(
                  padding: const EdgeInsets.only(
                      left: 16, right: 8, top: 6, bottom: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: isWomenTheme
                            ? const Color(0xFFFBCFE8)
                            : AppColors.borderLight),
                    boxShadow: const [AppShadows.cardShadow],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded,
                          color: AppColors.textMuted, size: 22),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Search salon, service or stylist',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isWomenTheme
                              ? const Color(0xFFFCE7F3)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.tune_rounded,
                            color: isWomenTheme
                                ? const Color(0xFFEC4899)
                                : AppColors.darkNeutral,
                            size: 18),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: LinearProgressIndicator(color: primaryAccentColor),
                ),
              const SizedBox(height: AppSpacing.lg),

              // 3. Gender Segment Selector (Men & Unisex vs Women)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isWomenTheme
                      ? const Color(0xFFFCE7F3)
                      : const Color(0xFFF3EFEA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedGenderIndex = 0);
                          _fetchHomeData(gender: 'MEN');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isWomenTheme
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: !isWomenTheme
                                ? const [AppShadows.cardShadow]
                                : null,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.content_cut_rounded,
                                  size: 16, color: AppColors.darkNeutral),
                              SizedBox(width: 6),
                              Text(
                                'Men & Unisex',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.darkNeutral),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedGenderIndex = 1);
                          _fetchHomeData(gender: 'WOMEN');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isWomenTheme
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isWomenTheme
                                ? const [AppShadows.cardShadow]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome_outlined,
                                  size: 16,
                                  color: isWomenTheme
                                      ? const Color(0xFFEC4899)
                                      : AppColors.darkNeutral),
                              const SizedBox(width: 6),
                              Text(
                                'Women',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isWomenTheme
                                      ? const Color(0xFFEC4899)
                                      : AppColors.darkNeutral,
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
              const SizedBox(height: AppSpacing.lg),

              // 4. Hero Banner Card (JUST FOR YOU)
              Container(
                height: 230,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [AppShadows.cardShadow],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        isWomenTheme
                            ? 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&q=80&w=800'
                            : 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&q=80&w=800',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: AppColors.darkNeutral,
                          child: const Center(
                            child: Icon(Icons.storefront_rounded,
                                color: AppColors.primaryGold, size: 48),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.75),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryAccentColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'JUST FOR YOU',
                                style: TextStyle(
                                  color: isWomenTheme
                                      ? Colors.white
                                      : AppColors.darkNeutral,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isWomenTheme
                                  ? 'A little glow-up?'
                                  : 'Sharp cut. Zero wait.',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isWomenTheme
                                  ? 'Hair spa + styling from ₹1,199'
                                  : '20% off first chair booking',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                if (featuredSalon != null) {
                                  context.push('/salon-detail', extra: {
                                    'salonId': featuredSalon['id'],
                                    'salon': featuredSalon
                                  });
                                } else {
                                  context.push('/explore');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryAccentColor,
                                foregroundColor: isWomenTheme
                                    ? Colors.white
                                    : AppColors.darkNeutral,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Book now',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 16),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // AI Style Studio Feature Card
              _buildAiStyleStudioCard(context),
              const SizedBox(height: AppSpacing.xl),

              // 5. Popular Services Carousel (Matches media_1791347258511.png)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Popular services',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNeutral)),
                  GestureDetector(
                    onTap: () => context.push('/explore'),
                    child: const Row(
                      children: [
                        Text('See all',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted)),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (_popularServices.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _popularServices.map<Widget>((svc) {
                      final serviceObj = svc['service'] is Map
                          ? svc['service'] as Map
                          : (svc is Map ? svc : const {});
                      final title = (serviceObj['name'] ??
                              svc['name'] ??
                              'Service')
                          .toString();
                      final dur = formatDuration(svc['duration_minutes'] ?? 30);
                      final subtitle = '$dur • ⭐ 4.9';
                      final priceNum = double.tryParse(
                          svc['price']?.toString() ?? '0');
                      final priceStr = priceNum != null
                          ? '₹${priceNum.toInt()}'
                          : '₹399';
                      final imgUrl = _getServiceImageUrl(
                          title, isWomenTheme);

                      final targetSalonId = svc['salon_id'] ??
                          svc['salonId'] ??
                          (svc['salon'] is Map ? svc['salon']['id'] : null) ??
                          featuredSalon?['id'];
                      final targetSalon = (svc['salon'] is Map ? svc['salon'] : null) ??
                          _salons.cast<Map<String, dynamic>?>().firstWhere(
                            (s) => s != null && s['id'] == targetSalonId,
                            orElse: () => featuredSalon,
                          );

                      return Padding(
                        padding:
                            const EdgeInsets.only(right: AppSpacing.md),
                        child: _buildPopularServiceCard(
                          title,
                          subtitle,
                          priceStr,
                          imgUrl,
                          isWomenTheme: isWomenTheme,
                          icon: _getServiceFallbackIcon(title),
                          onTap: () {
                            if (targetSalonId != null) {
                              context.push('/salon-detail', extra: {
                                'salonId': targetSalonId,
                                'salon': targetSalon,
                                'selectedServiceId': svc['id'],
                              });
                            } else {
                              context.push('/explore');
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.spa_outlined,
                          size: 24, color: AppColors.textMuted),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No services listed yet. Partner salons will appear here.',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),

              // 6. Your next visit Card (Matches media_1791347258511.png & media_1791347258532.png)
              const Text('Your next visit',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkNeutral)),
              const SizedBox(height: AppSpacing.md),

              GestureDetector(
                onTap: () => context.push('/my-bookings'),
                child: activeBooking == null
                    ? Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: const [AppShadows.cardShadow],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: AppColors.primaryGoldDark, size: 28),
                            SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('No upcoming visits',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.darkNeutral)),
                                  SizedBox(height: 2),
                                  Text('Book your chair with zero waiting time',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textMuted)),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderLight),
                          boxShadow: const [AppShadows.cardShadow],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.darkNeutral,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    activeBooking['start_at'] != null &&
                                            DateTime.tryParse(
                                                    activeBooking['start_at']
                                                        .toString()) !=
                                                null
                                        ? DateTime.tryParse(
                                                activeBooking['start_at']
                                                    .toString())!
                                            .day
                                            .toString()
                                        : 'NOW',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20),
                                  ),
                                  Text(
                                    activeBooking['start_at'] != null &&
                                            DateTime.tryParse(
                                                    activeBooking['start_at']
                                                        .toString()) !=
                                                null
                                        ? [
                                            'JAN',
                                            'FEB',
                                            'MAR',
                                            'APR',
                                            'MAY',
                                            'JUN',
                                            'JUL',
                                            'AUG',
                                            'SEP',
                                            'OCT',
                                            'NOV',
                                            'DEC'
                                          ][DateTime.tryParse(
                                                    activeBooking['start_at']
                                                        .toString())!
                                                .month -
                                            1]
                                        : 'VISIT',
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeBooking['status'] ?? 'CONFIRMED',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF16A34A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    activeBooking['salon']?['name'] ??
                                        'Salon Visit',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkNeutral),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    activeBooking['services'] != null &&
                                            (activeBooking['services'] as List)
                                                .isNotEmpty
                                        ? (activeBooking['services'] as List)[0]
                                                ['service_name'] ??
                                            'Salon Service'
                                        : 'Styling & Grooming',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // 7. Combos worth showing up for (Renders dynamically ONLY when partner combos exist)
              if (_combos.isNotEmpty) ...[
                const Text('Combos worth showing up for',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkNeutral)),
                GestureDetector(
                  onTap: () {
                    final comboSalonId = _combos.first['salon_id'] ??
                        featuredSalon?['id'];
                    context.push('/salon-detail', extra: {
                      'salonId': comboSalonId,
                      'salon': featuredSalon
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.darkNeutral,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [AppShadows.cardShadow],
                    ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    color: primaryAccentColor, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  _combos.first['discountTag']?.toString() ??
                                      'POWER COMBO',
                                  style: TextStyle(
                                      color: primaryAccentColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                                _combos.first['name']?.toString() ??
                                    'Special Package',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(_combos.first['description']?.toString() ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 14),
                            Builder(
                              builder: (context) {
                                final combo = _combos.first;
                                final price = double.tryParse(combo['price']?.toString() ?? '0') ?? 0.0;
                                final rawOrig = double.tryParse((combo['original_price'] ?? combo['originalPrice'])?.toString() ?? '0');
                                final origPrice = (rawOrig != null && rawOrig > price) ? rawOrig : (price * 1.25).roundToDouble();
                                final hasDiscount = origPrice > price;
                                final savings = (origPrice - price).round();

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    if (hasDiscount) ...[
                                      Text(
                                        '₹${origPrice.toInt()}',
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          decoration: TextDecoration.lineThrough,
                                          decorationColor: Colors.white70,
                                          decorationThickness: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      '₹${price.toInt()}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (hasDiscount && savings > 0) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGoldDark,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'SAVE ₹$savings',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(Icons.content_cut_rounded,
                              color: primaryAccentColor, size: 28),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text('+',
                                style: TextStyle(
                                    color: primaryAccentColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ),
                          Icon(Icons.auto_awesome_rounded,
                              color: primaryAccentColor, size: 28),
                        ],
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // 8. Recommended near you Header & Salon Card (Matches media_1791347258516.png & media_1791347258532.png)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recommended near you',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNeutral)),
                  GestureDetector(
                    onTap: () => context.push('/explore'),
                    child: const Row(
                      children: [
                        Text('Explore',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textMuted)),
                        Icon(Icons.arrow_forward_ios_rounded,
                            size: 12, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (featuredSalon != null)
                GestureDetector(
                  onTap: () => context.push('/salon-detail', extra: {
                    'salonId': featuredSalon['id'],
                    'salon': featuredSalon
                  }),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: const [AppShadows.cardShadow],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24)),
                          child: Image.network(
                            ApiConfig.formatImageUrl(
                                featuredSalon['cover_image']?.toString()),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _salonCoverFallback(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    featuredSalon['name']?.toString() ??
                                        'Salon',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.darkNeutral),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: secondaryBadgeColor,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.star_rounded,
                                            size: 14,
                                            color: isWomenTheme
                                                ? const Color(0xFFEC4899)
                                                : AppColors.primaryGoldDark),
                                        const SizedBox(width: 2),
                                        Text(
                                          (featuredSalon['rating'] ?? 4.9)
                                              .toString(),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkNeutral),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                  '${featuredSalon['area'] ?? featuredSalon['city'] ?? ""} · ${featuredSalon['formattedDistance'] ?? "Nearby"}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textMuted)),
                              const SizedBox(height: 12),
                              const Divider(
                                  height: 1, color: AppColors.borderLight),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded,
                                          size: 14,
                                          color: AppColors.darkNeutral),
                                      const SizedBox(width: 4),
                                      Text(
                                          'Open until ${featuredSalon['closing_time'] ?? "21:00"}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkNeutral)),
                                    ],
                                  ),
                                  const Text('View details →',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGoldDark)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 40, color: AppColors.textMuted),
                      SizedBox(height: 10),
                      Text(
                        'No partner salons in this area yet',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkNeutral),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Registered partner salons will appear here.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // 9. Referral Card ("Invite friends, earn ₹250")
              GestureDetector(
                onTap: () => context.push('/profile/invite'),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: secondaryBadgeColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.card_giftcard_rounded,
                            color: isWomenTheme
                                ? const Color(0xFFEC4899)
                                : AppColors.primaryGoldDark,
                            size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Invite friends, earn ₹250',
                                style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.darkNeutral)),
                            SizedBox(height: 2),
                            Text('Good hair days are better together',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SlotBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) context.push('/explore');
          if (index == 2) context.push('/my-bookings');
          if (index == 3) context.push('/offers');
          if (index == 4) context.push('/profile');
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

  IconData _getServiceFallbackIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('cut') || lower.contains('hair') || lower.contains('styling')) {
      return Icons.content_cut_rounded;
    }
    if (lower.contains('beard') || lower.contains('shave')) {
      return Icons.face_retouching_natural_rounded;
    }
    if (lower.contains('spa') || lower.contains('massage')) {
      return Icons.spa_rounded;
    }
    if (lower.contains('facial') || lower.contains('cleanup') || lower.contains('glow')) {
      return Icons.auto_awesome_rounded;
    }
    if (lower.contains('nail') || lower.contains('manicure') || lower.contains('pedicure')) {
      return Icons.brush_rounded;
    }
    return Icons.star_border_rounded;
  }

  String _getServiceImageUrl(String title, bool isWomenTheme) {
    final lower = title.toLowerCase();
    if (lower.contains('beard') || lower.contains('shave')) {
      return 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?auto=format&fit=crop&q=80&w=400';
    }
    if (lower.contains('spa') || lower.contains('massage')) {
      return isWomenTheme
          ? 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?auto=format&fit=crop&q=80&w=400'
          : 'https://images.unsplash.com/photo-1519699047748-de8e457a634e?auto=format&fit=crop&q=80&w=400';
    }
    if (lower.contains('facial') || lower.contains('cleanup') || lower.contains('glow') || lower.contains('charcoal')) {
      return isWomenTheme
          ? 'https://images.unsplash.com/photo-1512290900672-1f02f9e42104?auto=format&fit=crop&q=80&w=400'
          : 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?auto=format&fit=crop&q=80&w=400';
    }
    if (lower.contains('nail') || lower.contains('manicure') || lower.contains('pedicure')) {
      return 'https://images.unsplash.com/photo-1604654894610-df63bc536371?auto=format&fit=crop&q=80&w=400';
    }
    return isWomenTheme
        ? 'https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&q=80&w=400'
        : 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?auto=format&fit=crop&q=80&w=400';
  }

  Widget _buildPopularServiceCard(
      String title, String subtitle, String price, String imageUrl,
      {required bool isWomenTheme, IconData? icon, VoidCallback? onTap}) {
    final accentColor =
        isWomenTheme ? const Color(0xFFEC4899) : AppColors.primaryGoldDark;
    final fallbackIcon = icon ?? _getServiceFallbackIcon(title);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
          boxShadow: const [AppShadows.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: 110,
                width: double.infinity,
                color: isWomenTheme
                    ? const Color(0xFFFDF2F8)
                    : const Color(0xFFF8FAFC),
                child: Image.network(
                  imageUrl,
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 110,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isWomenTheme
                              ? [
                                  const Color(0xFFFCE7F3),
                                  const Color(0xFFFBCFE8)
                                ]
                              : [
                                  const Color(0xFFF1F5F9),
                                  const Color(0xFFE2E8F0)
                                ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          fallbackIcon,
                          color: accentColor,
                          size: 38,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.darkNeutral),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Text(price,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.darkNeutral)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _salonCoverFallback() {
    return Container(
      height: 180,
      width: double.infinity,
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
            Icon(Icons.storefront_rounded, size: 48, color: AppColors.primaryGold),
            SizedBox(height: 6),
            Text(
              'SLOT Premium Salon',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiStyleStudioCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/ai-style-studio'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1A15), Color(0xFF2C241B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD49B28).withOpacity(0.35), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD49B28).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: Color(0xFFE5B552)),
                            SizedBox(width: 4),
                            Text(
                              'AI STYLE STUDIO',
                              style: TextStyle(
                                color: Color(0xFFE5B552),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '100% FREE',
                          style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Try Hairstyle & Beard Looks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'See your new cut or beard style before your chair appointment.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD49B28),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFFD49B28).withOpacity(0.4), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

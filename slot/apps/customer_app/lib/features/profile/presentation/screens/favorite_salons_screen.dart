import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:api_client/api_client.dart';
import '../../../auth/cubit/auth_cubit.dart';

class FavoriteSalonsScreen extends StatefulWidget {
  const FavoriteSalonsScreen({super.key});

  @override
  State<FavoriteSalonsScreen> createState() => _FavoriteSalonsScreenState();
}

class _FavoriteSalonsScreenState extends State<FavoriteSalonsScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final apiClient = context.read<AuthCubit>().apiClient;
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList('favorite_salon_ids') ?? const []).toSet();
    try {
      final salons = await apiClient.getSalons();
      if (!mounted) return;
      setState(() {
        _favorites = salons
            .where((salon) => ids.contains(salon['id']?.toString()))
            .map((salon) => Map<String, dynamic>.from(salon as Map))
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFavorite(int index) async {
    final salon = _favorites[index];
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList('favorite_salon_ids') ?? const []).toSet();
    ids.remove(salon['id']?.toString());
    await prefs.setStringList('favorite_salon_ids', ids.toList());
    if (mounted) setState(() => _favorites.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.darkNeutral, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Favorite Salons', style: AppTypography.screenTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border_rounded,
                          size: 64,
                          color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text('No Saved Salons Yet',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkNeutral)),
                      const SizedBox(height: 8),
                      const Text(
                          'Tap the heart icon on any salon to save it for quick booking.',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final salon = _favorites[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.borderLight),
                        boxShadow: const [AppShadows.cardShadow],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppRadius.card)),
                                child: Image.network(
                                  ApiConfig.formatImageUrl(
                                      salon['cover_image']?.toString()),
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 140,
                                    color: AppColors.darkNeutral,
                                    child: const Center(
                                      child: Icon(Icons.storefront_rounded,
                                          color: AppColors.primaryGold, size: 36),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    _removeFavorite(index);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              '${salon['name']} removed from favorites')),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.favorite_rounded,
                                        color: Colors.red, size: 18),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(salon['name'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: AppColors.darkNeutral)),
                                      const SizedBox(height: 4),
                                      Text(salon['address'],
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.star_rounded,
                                              color: AppColors.primaryGoldDark,
                                              size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                              '${salon['rating'] ?? 0} (${salon['review_count'] ?? 0})',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12)),
                                          const SizedBox(width: 12),
                                          Text(
                                              salon['formattedDistance']
                                                      ?.toString() ??
                                                  '',
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textMuted)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => context.go('/salon-detail',
                                      extra: {
                                        'salonId': salon['id'],
                                        'salon': salon
                                      }),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.darkNeutral,
                                    foregroundColor: AppColors.primaryGold,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                  ),
                                  child: const Text('Book Now',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

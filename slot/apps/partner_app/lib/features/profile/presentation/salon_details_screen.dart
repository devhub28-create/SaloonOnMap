import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:api_client/api_client.dart';
import '../../../core/network/partner_api_service.dart';
import '../../auth/cubit/partner_auth_cubit.dart';

class SalonDetailsScreen extends StatefulWidget {
  const SalonDetailsScreen({super.key});

  @override
  State<SalonDetailsScreen> createState() => _SalonDetailsScreenState();
}

class _SalonDetailsScreenState extends State<SalonDetailsScreen> {
  late TextEditingController _salonNameController;
  late TextEditingController _areaController;
  late TextEditingController _addressController;
  late TextEditingController _seatCountController;

  String _selectedCity = 'Bengaluru';
  String _coverImage = '';
  TimeOfDay _openingTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 21, minute: 0);
  String _targetGender = 'UNISEX';

  final List<String> _cities = [
    'Bengaluru',
    'Indore',
    'Mumbai',
    'Delhi NCR',
    'Hyderabad',
    'Chennai',
    'Pune',
  ];

  @override
  void initState() {
    super.initState();
    final authState = context.read<PartnerAuthCubit>().state;
    final salonName = authState is PartnerAuthenticated ? authState.salonName : 'My Salon';
    final seatCount = authState is PartnerAuthenticated ? authState.seatCount : 4;
    final area = authState is PartnerAuthenticated ? authState.area : '';
    final address = authState is PartnerAuthenticated ? authState.address : '';
    final city = authState is PartnerAuthenticated ? authState.city : 'Bengaluru';
    _coverImage = authState is PartnerAuthenticated ? authState.coverImage : '';

    _salonNameController = TextEditingController(text: salonName);
    _areaController = TextEditingController(text: area);
    _addressController = TextEditingController(text: address);
    _seatCountController = TextEditingController(text: seatCount.toString());
    _selectedCity = city;
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _seatCountController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isOpening) async {
    final initial = isOpening ? _openingTime : _closingTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  Future<void> _pickCoverImage(ImageSource source) async {
    final authCubit = context.read<PartnerAuthCubit>();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
      if (picked != null) {
        final uploaded = await authCubit.apiClient.uploadSalonImage(picked.path);
        if (uploaded.isNotEmpty) {
          setState(() => _coverImage = uploaded);
          authCubit.updateCoverImage(uploaded);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Salon photo updated!'), backgroundColor: AppColors.primaryGoldDark),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: $e'), backgroundColor: AppColors.statusDestructiveText),
        );
      }
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Salon Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNeutral),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryGoldDark),
              title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _pickCoverImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryGoldDark),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(ctx);
                _pickCoverImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveDetails() async {
    final updatedName = _salonNameController.text.trim();
    if (updatedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter salon name.')),
      );
      return;
    }

    final authCubit = context.read<PartnerAuthCubit>();
    final authState = authCubit.state;
    if (authState is PartnerAuthenticated) {
      final seatCount = int.tryParse(_seatCountController.text.trim()) ?? 4;
      try {
        await PartnerApiService.instance.updateSalonProfile({
          'name': updatedName,
          'city': _selectedCity,
          'area': _areaController.text.trim(),
          'address': _addressController.text.trim(),
          'openingTime': '${_openingTime.hour.toString().padLeft(2, '0')}:${_openingTime.minute.toString().padLeft(2, '0')}',
          'closingTime': '${_closingTime.hour.toString().padLeft(2, '0')}:${_closingTime.minute.toString().padLeft(2, '0')}',
          if (_coverImage.isNotEmpty) 'coverImage': _coverImage,
        });
      } catch (_) {}
      authCubit.updateSeatCount(seatCount);
      if (_coverImage.isNotEmpty) {
        authCubit.updateCoverImage(_coverImage);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Salon details saved successfully!')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedCoverUrl = ApiConfig.formatImageUrl(_coverImage);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkNeutral, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Salon details & hours', style: AppTypography.screenTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SALON PHOTO & BRANDING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGoldDark, letterSpacing: 1.2)),
              const SizedBox(height: AppSpacing.sm),
              Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        resolvedCoverUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFD6C8B8),
                          child: const Center(
                            child: Icon(Icons.storefront_rounded, size: 48, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkNeutral,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: _showImagePickerModal,
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text('Change Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              const Text('GENERAL INFORMATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGoldDark, letterSpacing: 1.2)),
              const SizedBox(height: AppSpacing.md),

              _buildField(_salonNameController, 'Salon Display Name', Icons.storefront_rounded),
              const SizedBox(height: AppSpacing.md),

              const Text('Target Audience', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNeutral)),
              const SizedBox(height: 8),
              Row(
                children: ['UNISEX', 'MEN', 'WOMEN'].map((gender) {
                  final isSelected = _targetGender == gender;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _targetGender = gender),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.darkNeutral : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.darkNeutral : AppColors.borderLight),
                        ),
                        child: Center(
                          child: Text(
                            gender,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.primaryGold : AppColors.darkNeutral,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              const Text('OPERATING HOURS & CAPACITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGoldDark, letterSpacing: 1.2)),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime(true),
                      child: _timeTile('Opening Time', _formatTime(_openingTime), Icons.access_time_rounded),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickTime(false),
                      child: _timeTile('Closing Time', _formatTime(_closingTime), Icons.access_time_filled_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildField(_seatCountController, 'Styling Chairs / Seats Count', Icons.event_seat_rounded, keyboardType: TextInputType.number),
              const SizedBox(height: AppSpacing.xl),

              const Text('LOCATION & ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGoldDark, letterSpacing: 1.2)),
              const SizedBox(height: AppSpacing.md),

              Row(
                children: [
                  Expanded(child: _buildCityDropdown()),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: _buildField(_areaController, 'Area / Locality', Icons.map_rounded)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildField(_addressController, 'Full Address', Icons.pin_drop_rounded),
              const SizedBox(height: AppSpacing.xxl),

              SlotPrimaryButton(
                text: 'Save Salon Details →',
                onPressed: _saveDetails,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          const Text('City', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          Builder(
            builder: (context) {
              final dropdownCities = List<String>.from(_cities);
              if (!dropdownCities.contains(_selectedCity) && _selectedCity.isNotEmpty) {
                dropdownCities.add(_selectedCity);
              }
              final activeValue = dropdownCities.contains(_selectedCity)
                  ? _selectedCity
                  : (dropdownCities.isNotEmpty ? dropdownCities.first : null);

              return DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: activeValue,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.darkNeutral),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCity = val);
                  },
                  items: dropdownCities.map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Row(
                        children: [
                          const Icon(Icons.location_city_rounded, color: AppColors.primaryGoldDark, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            city,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _timeTile(String label, String timeText, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGoldDark, size: 18),
              const SizedBox(width: 8),
              Text(
                timeText,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.darkNeutral),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryGoldDark, width: 1.5)),
      ),
    );
  }
}

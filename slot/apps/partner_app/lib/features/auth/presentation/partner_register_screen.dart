import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:design_system/design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:api_client/api_client.dart';
import '../../../core/network/partner_api_service.dart';
import '../cubit/partner_auth_cubit.dart';

class PartnerRegisterScreen extends StatefulWidget {
  const PartnerRegisterScreen({super.key});

  @override
  State<PartnerRegisterScreen> createState() => _PartnerRegisterScreenState();
}

class _PartnerRegisterScreenState extends State<PartnerRegisterScreen> {
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _salonNameController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _seatCountController = TextEditingController(text: '6');

  String _selectedCity = 'Bengaluru';
  TimeOfDay _openingTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = const TimeOfDay(hour: 21, minute: 0);
  String _targetGender = 'UNISEX';
  bool _obscurePassword = true;

  final List<String> _uploadedImages = [];

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
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _useCurrentLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detecting GPS location...'),
        backgroundColor: AppColors.primaryGoldDark,
        duration: Duration(seconds: 1),
      ),
    );

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Please grant location permissions.'),
              backgroundColor: AppColors.statusDestructiveText,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );

      final lat = position.latitude;
      final lng = position.longitude;

      String city = 'Bengaluru';
      String area = '';
      String fullAddress = 'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}';

      try {
        final dio = PartnerApiService.instance.dio;
        final response = await dio.get(
          PartnerApiUrls.reverseGeocodeUrl,
          queryParameters: {'format': 'json', 'lat': lat, 'lon': lng},
          options: Options(headers: {'User-Agent': 'SlotPartnerApp/1.0'}),
        ).timeout(const Duration(seconds: 4));

        if (response.data != null) {
          if (response.data['display_name'] != null) {
            fullAddress = response.data['display_name'].toString();
          }
          final addr = response.data['address'];
          if (addr != null && addr is Map) {
            final fetchedCity = addr['city'] ?? addr['town'] ?? addr['county'] ?? addr['state_district'];
            if (fetchedCity != null) {
              city = fetchedCity.toString();
            }
            final fetchedArea = addr['suburb'] ?? addr['neighbourhood'] ?? addr['subdistrict'] ?? addr['quarter'] ?? addr['road'];
            if (fetchedArea != null) {
              area = fetchedArea.toString();
            }
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          final trimmedCity = city.trim();
          final match = _cities.firstWhere(
            (c) => c.toLowerCase() == trimmedCity.toLowerCase() || trimmedCity.toLowerCase().contains(c.toLowerCase()),
            orElse: () => trimmedCity,
          );
          if (!_cities.any((c) => c.toLowerCase() == match.toLowerCase())) {
            _cities.add(match);
          }
          _selectedCity = _cities.firstWhere((c) => c.toLowerCase() == match.toLowerCase());
          _areaController.text = area.isNotEmpty ? area : trimmedCity;
          _addressController.text = fullAddress;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 GPS location detected: $_selectedCity (${_areaController.text})'),
            backgroundColor: AppColors.primaryGoldDark,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to fetch GPS location: $e'),
            backgroundColor: AppColors.statusDestructiveText,
          ),
        );
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return TimeOfDay.fromDateTime(dt).format(context);
  }

  Future<void> _submitRegistration() async {
    final ownerName = _ownerNameController.text.trim();
    final rawPhone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final salonName = _salonNameController.text.trim();

    if (rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mobile phone number is required.'),
          backgroundColor: AppColors.statusDestructiveText,
        ),
      );
      return;
    }

    String formattedPhone = rawPhone;
    final digitsOnly = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 10) {
      formattedPhone = '+91 $digitsOnly';
    } else if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      formattedPhone = '+91 ${digitsOnly.substring(2)}';
    } else if (!formattedPhone.startsWith('+') && digitsOnly.isNotEmpty) {
      formattedPhone = '+$digitsOnly';
    }

    if (ownerName.isEmpty || email.isEmpty || password.isEmpty || salonName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields.'),
          backgroundColor: AppColors.statusDestructiveText,
        ),
      );
      return;
    }

    final authCubit = context.read<PartnerAuthCubit>();

    // Process and upload any local images picked by the partner
    final List<String> localImages = _uploadedImages
        .where((img) => !img.startsWith('http://') && !img.startsWith('https://'))
        .toList();
    final List<String> remoteImages = _uploadedImages
        .where((img) => img.startsWith('http://') || img.startsWith('https://'))
        .toList();

    final List<String> finalImageUrls = [];
    for (final img in localImages) {
      try {
        final uploadedUrl = await authCubit.apiClient.uploadSalonImage(img);
        if (uploadedUrl.isNotEmpty) {
          finalImageUrls.add(uploadedUrl);
        }
      } catch (e) {
        debugPrint('Failed to upload salon image: $e');
      }
    }
    finalImageUrls.addAll(remoteImages);

    final primaryCover = finalImageUrls.isNotEmpty
        ? finalImageUrls.first
        : 'https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&q=80&w=1000';

    authCubit.registerSalon(
      ownerName: ownerName,
      phone: formattedPhone,
      email: email,
      password: password,
      salonName: salonName,
      targetGender: _targetGender,
      city: _selectedCity,
      area: _areaController.text.trim(),
      address: _addressController.text.trim(),
      seatCount: int.tryParse(_seatCountController.text.trim()) ?? 6,
      coverImage: primaryCover,
      images: finalImageUrls,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.darkNeutral, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Register Salon Partner',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNeutral),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<PartnerAuthCubit, PartnerAuthState>(
        listener: (context, state) {
          if (state is PartnerAuthenticated) {
            context.go('/');
          } else if (state is PartnerAuthError) {
            final isAlreadyRegistered = state.message.contains('registered') || state.message.contains('Login');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.statusDestructiveText,
                duration: const Duration(seconds: 4),
                action: isAlreadyRegistered
                    ? SnackBarAction(
                        label: 'LOGIN NOW',
                        textColor: Colors.white,
                        onPressed: () => context.pop(),
                      )
                    : null,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is PartnerAuthLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Centered Header
                  const Center(
                    child: Column(
                      children: [
                        SlotLogo(
                          size: 72,
                          badgeText: 'PARTNER',
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Text(
                          'Join SLOT Partner Platform',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkNeutral),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Set up your salon profile, seats & live calendar',
                          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section 1: Owner Details
                  const Text('1. OWNER & ACCOUNT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGoldDark, letterSpacing: 1.2)),
                  const SizedBox(height: AppSpacing.md),

                  _buildTextField(_ownerNameController, 'Owner Full Name', Icons.person_outline_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(_phoneController, 'Mobile Phone Number', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: AppSpacing.md),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                    decoration: InputDecoration(
                      labelText: 'Account Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borderLight)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaryGoldDark, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Section 2: Salon Details
                  const Text('2. SALON PROFILE & LOCATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGoldDark, letterSpacing: 1.2)),
                  const SizedBox(height: AppSpacing.md),

                  _buildTextField(_salonNameController, 'Salon Name', Icons.content_cut_rounded),
                  const SizedBox(height: AppSpacing.md),

                  // Target Gender Segment
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
                  const SizedBox(height: AppSpacing.lg),

                  // Operating Hours Time Pickers
                  const Text('Operating Hours', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkNeutral)),
                  const SizedBox(height: 8),
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
                  const SizedBox(height: AppSpacing.lg),

                  // Use Current Location Action Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: OutlinedButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location_rounded, color: AppColors.primaryGoldDark, size: 18),
                      label: const Text(
                        'Use Current Location for Salon Address',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkNeutral),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: AppColors.primaryGoldDark, width: 1.2),
                      ),
                    ),
                  ),

                  // City Dropdown & Area
                  Row(
                    children: [
                      Expanded(child: _buildCityDropdown()),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: _buildTextField(_areaController, 'Area / Locality', Icons.map_rounded)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(_addressController, 'Full Street Address', Icons.pin_drop_rounded),
                  const SizedBox(height: AppSpacing.md),
                  _buildTextField(_seatCountController, 'Total Styling Chairs / Seats', Icons.event_seat_rounded, keyboardType: TextInputType.number),
                  const SizedBox(height: AppSpacing.lg),

                  // Section 3: Salon Photos & Interior Upload
                  const Text('3. SALON PHOTOS & INTERIOR IMAGES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryGoldDark, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  const Text('Upload photos of your salon interior, chairs & storefront for customers', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 12),

                  _buildImageUploadSection(),
                  const SizedBox(height: AppSpacing.xxl),

                  // Primary Submit Button
                  SlotPrimaryButton(
                    text: isLoading ? 'Registering Salon...' : 'Register & Open Salon Desk →',
                    onPressed: isLoading ? null : _submitRegistration,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have a salon desk?', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Sign In', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkNeutral)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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
                          Expanded(
                            child: Text(
                              city,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
                            ),
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

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _uploadedImages.insert(0, pickedFile.path);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Salon photo captured & set as primary cover!'),
              backgroundColor: AppColors.primaryGoldDark,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick photo: ${e.toString()}'),
            backgroundColor: AppColors.statusDestructiveText,
          ),
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
              'Add Salon Photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.darkNeutral),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryGoldDark),
              title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Capture salon interior/storefront live'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.primaryGoldDark),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Select from saved phone photos'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 105,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._uploadedImages.asMap().entries.map((entry) {
                final idx = entry.key;
                final url = entry.value;
                final isCover = idx == 0;
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCover ? AppColors.primaryGoldDark : AppColors.borderLight,
                      width: isCover ? 2.0 : 1.0,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: url.startsWith('http')
                            ? Image.network(
                                ApiConfig.formatImageUrl(url),
                                width: 100,
                                height: 105,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 100,
                                  height: 105,
                                  color: const Color(0xFFE5E7EB),
                                  child: const Icon(Icons.broken_image_rounded, size: 24, color: AppColors.textMuted),
                                ),
                              )
                            : Image.file(
                                File(url),
                                width: 100,
                                height: 105,
                                fit: BoxFit.cover,
                              ),
                      ),
                      if (isCover)
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGoldDark,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'COVER',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _uploadedImages.removeAt(idx)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              GestureDetector(
                onTap: _showImagePickerModal,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9C3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGoldDark, width: 1.5),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_rounded, color: AppColors.primaryGoldDark, size: 24),
                      SizedBox(height: 6),
                      Text('+ Add Photo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.darkNeutral)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
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

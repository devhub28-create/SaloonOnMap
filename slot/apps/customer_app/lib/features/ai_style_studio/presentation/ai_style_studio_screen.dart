import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:api_client/api_client.dart';
import '../cubit/ai_style_cubit.dart';
import '../cubit/ai_style_state.dart';
import 'widgets/consent_dialog.dart';
import 'look_detail_sheet.dart';
import 'saved_looks_screen.dart';

class AiStyleStudioScreen extends StatefulWidget {
  const AiStyleStudioScreen({super.key});

  @override
  State<AiStyleStudioScreen> createState() => _AiStyleStudioScreenState();
}

class _AiStyleStudioScreenState extends State<AiStyleStudioScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AiStyleCubit>().initStudio();
  }

  Color _parseHexColor(String? hex, {Color fallback = const Color(0xFF1E3A5F)}) {
    if (hex == null || hex.isEmpty) return fallback;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      final val = int.tryParse('FF$cleaned', radix: 16);
      if (val != null) return Color(val);
    }
    return fallback;
  }

  void _openFullScreenStoryboard(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pinch to zoom • Show to your barber',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F3),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFD49B28), size: 22),
            SizedBox(width: 8),
            Text(
              'AI Style Studio',
              style: TextStyle(
                color: Color(0xFF1E1A15),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFFBF8F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E1A15)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'My Saved Looks',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SavedLooksScreen()),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<AiStyleCubit, AiStyleState>(
        listener: (context, state) {
          if (state is AiStyleConfigState && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is AiStyleUploadingState ||
              state is AiStyleAnalyzingState ||
              state is AiStyleGeneratingState) {
            return _buildProgressScreenC(state);
          }

          if (state is AiStyleSuccessState) {
            return _buildStoryboardScreenD(context, state);
          }

          if (state is AiStyleErrorState) {
            return _buildErrorView(context, state);
          }

          if (state is AiStyleConfigState) {
            return _buildLandingAndPreferencesView(context, state);
          }

          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFD49B28)),
          );
        },
      ),
    );
  }

  /// Screen A (Landing) + Screen B (Photo Review, Dynamic Analysis & Preferences)
  Widget _buildLandingAndPreferencesView(BuildContext context, AiStyleConfigState state) {
    final cubit = context.read<AiStyleCubit>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!state.isServiceOnline)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                border: Border.all(color: const Color(0xFFFFEEBA)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.wifi_off, color: Color(0xFF856404), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI inference server is unreachable. Please verify backend is running.',
                      style: TextStyle(color: Color(0xFF856404), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          // Screen A: Hero Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF14243B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD49B28).withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DYNAMIC FACE-BASED STYLE ADVISOR',
                          style: TextStyle(
                            color: Color(0xFFFFD579),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Personalized Hair & Beard Suggestions on Your Own Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Analyses your facial proportions, hairline, eyewear & beard density to rank and render tailored styles directly on your portrait.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD49B28).withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.face_retouching_natural, color: Color(0xFFFFD579), size: 34),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Step 1: Upload / Capture Portrait
          const Text(
            '1. Your Portrait Photo',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1A15)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Use a well-lit, front-facing head-and-shoulders photo for accurate facial proportion analysis.',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A7265)),
          ),
          const SizedBox(height: 12),
          _buildPhotoSection(context, state),
          const SizedBox(height: 16),

          // Screen B: Live Photo Analysis Summary (shown as soon as photo is selected)
          if (state.isAnalyzingPhoto)
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5DEC9)),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD49B28)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Analyzing face geometry, hair texture, eyewear & lighting...',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else if (state.photoAnalysis != null)
            _buildPhotoAnalysisCard(state.photoAnalysis!),

          // Screen B: Interactive Styling Preferences
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE5DEC9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, size: 19, color: Color(0xFF1E3A5F)),
                    SizedBox(width: 8),
                    Text(
                      '2. Your Styling Preferences (Optional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: Color(0xFF1E1A15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Customize how the recommendation engine ranks your hairstyle & beard options:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF7A7265)),
                ),
                const SizedBox(height: 14),

                if (state.hairStyles.isNotEmpty) ...[
                  _buildCatalogStyleChipGroup(
                    title: 'Target Hairstyle (Optional)',
                    selectedId: state.selectedHairStyle,
                    options: state.hairStyles,
                    onSelected: cubit.selectHairStyle,
                    defaultLabel: '✨ Auto-Recommend Best Cut',
                  ),
                  const SizedBox(height: 14),
                ],

                if (state.beardStyles.isNotEmpty) ...[
                  _buildCatalogStyleChipGroup(
                    title: 'Target Facial Hair / Beard (Optional)',
                    selectedId: state.selectedBeardStyle,
                    options: state.beardStyles,
                    onSelected: cubit.selectBeardStyle,
                    defaultLabel: '✨ Auto-Recommend Best Beard',
                  ),
                  const SizedBox(height: 14),
                ],

                _buildPreferenceChipGroup(
                  title: 'Maintenance Level',
                  selectedValue: state.maintenanceLevel,
                  options: const [
                    {'id': 'any', 'label': 'Any'},
                    {'id': 'low', 'label': 'Low Effort'},
                    {'id': 'medium', 'label': 'Medium'},
                    {'id': 'high', 'label': 'High Styling'},
                  ],
                  onSelected: cubit.setMaintenanceLevel,
                ),
                const SizedBox(height: 12),

                _buildPreferenceChipGroup(
                  title: 'Style Vibe',
                  selectedValue: state.styleVibe,
                  options: const [
                    {'id': 'any', 'label': 'All Vibes'},
                    {'id': 'professional', 'label': 'Executive'},
                    {'id': 'modern', 'label': 'Modern'},
                    {'id': 'casual', 'label': 'Casual'},
                    {'id': 'classic', 'label': 'Classic'},
                  ],
                  onSelected: cubit.setStyleVibe,
                ),
                const SizedBox(height: 12),

                _buildPreferenceChipGroup(
                  title: 'Number of Variations',
                  selectedValue: state.variationsCount.toString(),
                  options: const [
                    {'id': '3', 'label': '3 Looks'},
                    {'id': '4', 'label': '4 Looks'},
                    {'id': '6', 'label': '6 Looks (Full Board)'},
                  ],
                  onSelected: (val) => cubit.setVariationsCount(int.tryParse(val) ?? 6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Privacy & Consent Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: state.consentGiven,
                  activeColor: const Color(0xFFD49B28),
                  onChanged: (val) {
                    cubit.setConsent(val ?? false);
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final accepted = await AiConsentDialog.show(context);
                      if (accepted == true) cubit.setConsent(true);
                    },
                    child: const Text(
                      'I consent to local AI processing of my portrait for hairstyle & beard preview generation. You can delete your photos anytime.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4A443B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD49B28),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                'Generate ${state.variationsCount} Style Suggestions',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: state.selectedImageBase64 != null
                  ? () => cubit.generateStyles()
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoAnalysisCard(PhotoAnalysisSummary summary) {
    final isOk = summary.faceDetected && summary.isAcceptable;
    final shapeLabel = summary.estimatedFaceShape.replaceAll('_', ' ').toUpperCase();
    final texLabel = summary.visibleTexture.replaceAll('_', ' ');
    final lenLabel = summary.currentHairLength.replaceAll('_', ' ');
    final beardLabel = summary.currentFacialHair.replaceAll('_', ' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOk ? const Color(0xFFF3F8F6) : const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOk ? const Color(0xFF2E6F5E).withOpacity(0.35) : Colors.redAccent.withOpacity(0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOk ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                size: 18,
                color: isOk ? const Color(0xFF1F5C4D) : Colors.redAccent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOk
                      ? 'Portrait Analyzed • Approximate Proportions: $shapeLabel'
                      : (summary.rejectionReason ?? 'Photo quality check failed'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isOk ? const Color(0xFF1F3D3A) : Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          if (isOk) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildAnalysisBadge('Hair: $lenLabel ($texLabel)'),
                _buildAnalysisBadge('Beard: $beardLabel'),
                if (summary.eyewearDetected) _buildAnalysisBadge('Eyewear Protected'),
              ],
            ),
            if (summary.shapeGuidance.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                summary.shapeGuidance,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF43534F), height: 1.35),
              ),
            ],
          ],
          if (summary.warnings.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...summary.warnings.map(
              (w) => Text(
                '• $w',
                style: const TextStyle(fontSize: 11, color: Color(0xFF8A5A19)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD0E2DC)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A5F)),
      ),
    );
  }

  Widget _buildPreferenceChipGroup({
    required String title,
    required String selectedValue,
    required List<Map<String, String>> options,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A4238)),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final id = opt['id']!;
            final label = opt['label']!;
            final isSelected = selectedValue == id;
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: const Color(0xFF1E3A5F),
              backgroundColor: const Color(0xFFF5F1EA),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF3A352F),
              ),
              onSelected: (_) => onSelected(id),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCatalogStyleChipGroup({
    required String title,
    required String? selectedId,
    required List<AiStyleOption> options,
    required ValueChanged<String?> onSelected,
    String defaultLabel = '✨ Auto-Suggest Best Fit',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A4238)),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(defaultLabel),
              selected: selectedId == null,
              selectedColor: const Color(0xFFD49B28),
              backgroundColor: const Color(0xFFF5F1EA),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selectedId == null ? Colors.white : const Color(0xFF3A352F),
              ),
              onSelected: (_) => onSelected(null),
            ),
            ...options.map((opt) {
              final isSelected = selectedId == opt.id;
              return ChoiceChip(
                label: Text(opt.name),
                selected: isSelected,
                selectedColor: const Color(0xFF1E3A5F),
                backgroundColor: const Color(0xFFF5F1EA),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF3A352F),
                ),
                onSelected: (_) => onSelected(isSelected ? null : opt.id),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSection(BuildContext context, AiStyleConfigState state) {
    if (state.selectedImage != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.file(
              state.selectedImage!,
              height: 240,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white, size: 16),
              label: const Text('Change Photo', style: TextStyle(color: Colors.white, fontSize: 12)),
              onPressed: () => context.read<AiStyleCubit>().clearPhoto(),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5DEC9), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFD49B28).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.face_retouching_natural, size: 36, color: Color(0xFFD49B28)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Upload a clear, front-facing portrait',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Good lighting • Looking straight at camera • Hair & jaw clearly visible',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF7A7265)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1A15),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                label: const Text('Camera', style: TextStyle(color: Colors.white)),
                onPressed: () => context.read<AiStyleCubit>().pickPhoto(ImageSource.camera),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  side: const BorderSide(color: Color(0xFF1E1A15)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.photo_library_outlined, color: Color(0xFF1E1A15), size: 18),
                label: const Text('Gallery', style: TextStyle(color: Color(0xFF1E1A15))),
                onPressed: () => context.read<AiStyleCubit>().pickPhoto(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Screen C: Live Generation Progress
  Widget _buildProgressScreenC(AiStyleState state) {
    String title = 'Creating Your Personalized Storyboard...';
    String subtitle = 'Synthesizing realistic hair & beard styles directly on your portrait.';
    int activeStep = 2;

    if (state is AiStyleUploadingState) {
      title = 'Uploading Portrait...';
      subtitle = state.message;
      activeStep = 0;
    } else if (state is AiStyleAnalyzingState) {
      title = 'Analyzing Face & Hair Characteristics...';
      subtitle = state.message;
      activeStep = 1;
    } else if (state is AiStyleGeneratingState) {
      title = 'Generating Tailored Style Suggestions...';
      subtitle = state.message;
      activeStep = 2;
    }

    final steps = [
      '1. Portrait quality, pose & eyewear check',
      '2. Facial proportion & hairline/beard analysis',
      '3. Multi-factor style recommendation & ranking',
      '4. Customer-centric hair & beard synthesis',
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 68,
              height: 68,
              child: CircularProgressIndicator(
                color: Color(0xFFD49B28),
                strokeWidth: 5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1A15),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF7A7265)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5DEC9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(steps.length, (idx) {
                  final done = idx <= activeStep;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Icon(
                          done ? Icons.check_circle : Icons.radio_button_unchecked,
                          size: 18,
                          color: done ? const Color(0xFFD49B28) : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            steps[idx],
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                              color: done ? const Color(0xFF1E1A15) : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Screen D: Personalized Storyboard & Dynamic Recommendations View
  Widget _buildStoryboardScreenD(BuildContext context, AiStyleSuccessState state) {
    final storyboardFullUrl = state.storyboardImageUrl != null
        ? ApiConfig.formatImageUrl(state.storyboardImageUrl!)
        : null;

    // Dynamically resolve the #1 recommended variation (never hardcoded to Option 3)
    final topVariation = state.variations.firstWhere(
      (v) => v.isRecommended,
      orElse: () => state.variations.first,
    );
    final bestTitle = state.bestOption?['title']?.toString() ??
        'Option ${topVariation.optionNumber}: ${topVariation.styleLabel}';
    final bestReason = state.bestOption?['reason']?.toString() ??
        topVariation.whyItSuits ??
        'Ranked #1 for your analyzed facial proportions and styling preferences.';
    final analyzedShape = state.analysis?.estimatedFaceShape.replaceAll('_', ' ').toUpperCase() ??
        state.bestOption?['face_shape']?.toString().toUpperCase() ??
        'BALANCED';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Action Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Color(0xFFFFD579), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.variations.length} Tailored Style Suggestions Ready',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Analyzed Proportions: $analyzedShape • Tap any card for Barber Specs',
                        style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => context.read<AiStyleCubit>().initStudio(),
                  icon: const Icon(Icons.refresh, size: 15, color: Colors.white),
                  label: const Text('New Photo', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic Best Option For You Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF8E7), Color(0xFFFDF2D0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD49B28), width: 1.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD49B28),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'TOP SUGGESTION FOR YOUR FACE • ${topVariation.suitabilityScore}% MATCH',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  bestTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1E1A15),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bestReason,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF4A4238), height: 1.38),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Composite Storyboard Sheet Preview
          if (storyboardFullUrl != null) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5DEC9), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.grid_view_rounded, size: 18, color: Color(0xFF1E3A5F)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'AI Face-Based Style Suggestions',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1E1A15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () async {
                                final ok = await context.read<AiStyleCubit>().saveStoryboard();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      ok ? 'Storyboard saved to My Saved Looks!' : 'Failed to save storyboard.',
                                    ),
                                    backgroundColor: ok ? const Color(0xFF1F3D3A) : Colors.redAccent,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD49B28),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.bookmark_add, size: 13, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'Save Sheet',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => _openFullScreenStoryboard(context, storyboardFullUrl),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A5F).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.zoom_out_map, size: 15, color: Color(0xFF1E3A5F)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openFullScreenStoryboard(context, storyboardFullUrl),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
                      child: Image.network(
                        storyboardFullUrl,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Individual Personalized Look Cards (1..N)
          const Text(
            'Tailored Style Suggestions for Your Face',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E1A15),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Facial proportion-based style suggestions generated on your portrait • Tap card for Barber Specs',
            style: TextStyle(fontSize: 12, color: Color(0xFF7A7265)),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.variations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, idx) {
              final v = state.variations[idx];
              return _buildPersonalizedOptionCard(context, state, v, idx + 1);
            },
          ),

          const SizedBox(height: 20),

          // Dynamic Key Styling Notes for Your Barber
          if (state.barberNotes.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD8D0C5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF283E5D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.content_cut, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Key Styling Notes for Your Barber',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...state.barberNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Expanded(
                            child: Text(
                              note,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF2C2620), height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Privacy Control: Delete Generation & Stored Photos
          Center(
            child: TextButton.icon(
              onPressed: () async {
                final deleted = await context.read<AiStyleCubit>().deleteCurrentGeneration();
                if (!context.mounted) return;
                if (deleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Generation job and stored photos deleted from server.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: 18),
              label: const Text(
                'Delete This Generation & Stored Photos',
                style: TextStyle(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalizedOptionCard(
    BuildContext context,
    AiStyleSuccessState state,
    AiVariation v,
    int displayIdx,
  ) {
    final fullUrl = ApiConfig.formatImageUrl(v.imageUrl);
    final headerColor = _parseHexColor(v.headerHex);
    final optNum = v.optionNumber > 0 ? v.optionNumber : displayIdx;

    return GestureDetector(
      onTap: () {
        LookDetailSheet.show(
          context,
          originalImageUrl: state.originalImageUrl,
          variation: v,
          onSave: (title, notes) async {
            final ok = await context.read<AiStyleCubit>().saveLook(v, title: title, notes: notes);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(ok ? 'Saved "${v.styleLabel}"!' : 'Failed to save look.'),
                backgroundColor: ok ? const Color(0xFF1F3D3A) : Colors.redAccent,
              ),
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: v.isRecommended ? const Color(0xFFD49B28) : const Color(0xFFD8D0C5),
            width: v.isRecommended ? 2.2 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: headerColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$optNum. ${v.styleLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: v.isRecommended ? const Color(0xFFD49B28) : Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      v.isRecommended ? '★ TOP SUGGESTION • ${v.suitabilityScore}%' : 'Suggestion ${v.suitabilityScore}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer's Transformed Portrait
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 122,
                      height: 152,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            fullUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.65),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'YOUR PORTRAIT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Dynamic Specs & Suitability Explanation
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (v.hairLengthCm != null || v.hairDesc != null)
                          _buildBulletPoint('Hair:', v.hairLengthCm ?? v.hairDesc!),
                        if (v.beardLengthMm != null || v.beardDesc != null) ...[
                          const SizedBox(height: 5),
                          _buildBulletPoint('Beard:', v.beardLengthMm ?? v.beardDesc!),
                        ],
                        if (v.maintenanceLevel != null) ...[
                          const SizedBox(height: 5),
                          _buildBulletPoint('Maintenance:', v.maintenanceLevel!.toUpperCase()),
                        ],
                        if (v.whyItSuits != null && v.whyItSuits!.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          _buildBulletPoint('Why it fits:', v.whyItSuits!),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                  side: BorderSide(color: headerColor),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(Icons.compare_arrows, size: 14, color: headerColor),
                                label: Text(
                                  'Barber Card',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: headerColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () {
                                  LookDetailSheet.show(
                                    context,
                                    originalImageUrl: state.originalImageUrl,
                                    variation: v,
                                    onSave: (title, notes) async {
                                      await context.read<AiStyleCubit>().saveLook(v, title: title, notes: notes);
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Save Look',
                              icon: const Icon(Icons.bookmark_add_outlined, color: Color(0xFFD49B28), size: 20),
                              onPressed: () async {
                                final ok = await context.read<AiStyleCubit>().saveLook(v);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? 'Saved "${v.styleLabel}"!' : 'Failed to save look.'),
                                    backgroundColor: ok ? const Color(0xFF1F3D3A) : Colors.redAccent,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String label, String value) {
    return RichText(
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF2C2620), height: 1.32),
        children: [
          const TextSpan(text: '• ', style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, AiStyleErrorState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Could Not Generate Style Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              state.error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF7A7265)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD49B28),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Another Photo', style: TextStyle(color: Colors.white)),
              onPressed: () => context.read<AiStyleCubit>().initStudio(),
            ),
          ],
        ),
      ),
    );
  }
}

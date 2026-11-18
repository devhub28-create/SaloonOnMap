import 'dart:io';

class AiStyleOption {
  final String id;
  final String name;
  final String description;

  const AiStyleOption({
    required this.id,
    required this.name,
    required this.description,
  });

  factory AiStyleOption.fromJson(Map<String, dynamic> json) {
    return AiStyleOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? json['label'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class PhotoAnalysisSummary {
  final bool faceDetected;
  final bool isAcceptable;
  final String? rejectionReason;
  final List<String> warnings;
  final String estimatedFaceShape;
  final double shapeConfidence;
  final String shapeGuidance;
  final String currentHairLength;
  final String visibleTexture;
  final String hairDensity;
  final String foreheadExposure;
  final bool eyewearDetected;
  final String currentFacialHair;

  const PhotoAnalysisSummary({
    required this.faceDetected,
    required this.isAcceptable,
    this.rejectionReason,
    this.warnings = const [],
    this.estimatedFaceShape = 'uncertain',
    this.shapeConfidence = 0.0,
    this.shapeGuidance = '',
    this.currentHairLength = 'medium',
    this.visibleTexture = 'natural',
    this.hairDensity = 'medium',
    this.foreheadExposure = 'balanced',
    this.eyewearDetected = false,
    this.currentFacialHair = 'light_stubble',
  });

  factory PhotoAnalysisSummary.fromJson(Map<String, dynamic> json) {
    final quality = json['quality'] is Map
        ? Map<String, dynamic>.from(json['quality'] as Map)
        : <String, dynamic>{};
    final geo = json['face_geometry'] is Map
        ? Map<String, dynamic>.from(json['face_geometry'] as Map)
        : <String, dynamic>{};
    final hair = json['hair_analysis'] is Map
        ? Map<String, dynamic>.from(json['hair_analysis'] as Map)
        : <String, dynamic>{};
    final beard = json['facial_hair_analysis'] is Map
        ? Map<String, dynamic>.from(json['facial_hair_analysis'] as Map)
        : <String, dynamic>{};

    final rawWarnings = quality['warnings'] as List<dynamic>? ?? const [];

    return PhotoAnalysisSummary(
      faceDetected: json['face_detected'] == true,
      isAcceptable: quality['is_acceptable'] != false,
      rejectionReason: quality['rejection_reason'] as String?,
      warnings: rawWarnings.map((e) => e.toString()).toList(),
      estimatedFaceShape: geo['estimated_face_shape'] as String? ?? 'uncertain',
      shapeConfidence: (geo['confidence'] as num?)?.toDouble() ?? 0.0,
      shapeGuidance: geo['shape_guidance'] as String? ?? '',
      currentHairLength:
          hair['estimated_current_length'] as String? ?? 'medium',
      visibleTexture: hair['visible_texture'] as String? ?? 'natural',
      hairDensity: hair['hair_density'] as String? ?? 'medium',
      foreheadExposure: hair['forehead_exposure'] as String? ?? 'balanced',
      eyewearDetected: hair['eyewear_detected'] == true,
      currentFacialHair:
          beard['estimated_current_facial_hair'] as String? ?? 'none',
    );
  }
}

class AiVariation {
  final String id;
  final String? archetypeId;
  final int optionNumber;
  final String imageUrl;
  final String? sideImageUrl;
  final String? backImageUrl;
  final bool sideViewAvailable;
  final bool backViewAvailable;
  final String styleLabel;
  final String? headerHex;
  final String? hairStyle;
  final String? beardStyle;
  final String? hairLengthCm;
  final String? beardLengthMm;
  final String? hairDesc;
  final String? beardDesc;
  final String? lookDesc;
  final String? whyItSuits;
  final int suitabilityScore;
  final String? maintenanceLevel;
  final String? stylingProducts;
  final List<String> barberInstructions;
  final bool isRecommended;
  final int? seed;

  const AiVariation({
    required this.id,
    this.archetypeId,
    this.optionNumber = 1,
    required this.imageUrl,
    this.sideImageUrl,
    this.backImageUrl,
    this.sideViewAvailable = false,
    this.backViewAvailable = false,
    required this.styleLabel,
    this.headerHex,
    this.hairStyle,
    this.beardStyle,
    this.hairLengthCm,
    this.beardLengthMm,
    this.hairDesc,
    this.beardDesc,
    this.lookDesc,
    this.whyItSuits,
    this.suitabilityScore = 88,
    this.maintenanceLevel,
    this.stylingProducts,
    this.barberInstructions = const [],
    this.isRecommended = false,
    this.seed,
  });

  factory AiVariation.fromJson(Map<String, dynamic> json) {
    final rawInstr = json['barber_instructions'] as List<dynamic>? ?? const [];
    final sideUrl = json['side_image_url'] as String?;
    final backUrl = json['back_image_url'] as String?;
    return AiVariation(
      id: json['id'] as String? ?? '',
      archetypeId: json['archetype_id'] as String?,
      optionNumber: (json['option_number'] as num?)?.toInt() ?? 1,
      imageUrl: json['image_url'] as String? ?? '',
      sideImageUrl: sideUrl,
      backImageUrl: backUrl,
      sideViewAvailable: json['side_view_available'] == true &&
          sideUrl != null &&
          sideUrl.isNotEmpty,
      backViewAvailable: json['back_view_available'] == true &&
          backUrl != null &&
          backUrl.isNotEmpty,
      styleLabel: json['style_label'] as String? ?? 'Personalized Look',
      headerHex: json['header_hex'] as String?,
      hairStyle: json['hair_style'] as String?,
      beardStyle: json['beard_style'] as String?,
      hairLengthCm: json['hair_length_cm'] as String?,
      beardLengthMm: json['beard_length_mm'] as String?,
      hairDesc: json['hair_desc'] as String?,
      beardDesc: json['beard_desc'] as String?,
      lookDesc: json['look_desc'] as String?,
      whyItSuits: json['why_it_suits'] as String?,
      suitabilityScore: (json['suitability_score'] as num?)?.toInt() ?? 88,
      maintenanceLevel: json['maintenance_level'] as String?,
      stylingProducts: json['styling_products'] as String?,
      barberInstructions: rawInstr.map((e) => e.toString()).toList(),
      isRecommended: json['is_recommended'] == true,
      seed: (json['seed'] as num?)?.toInt(),
    );
  }
}

class AiSavedLookItem {
  final String id;
  final String? jobId;
  final String? archetypeId;
  final int? optionNumber;
  final String originalImageUrl;
  final String styledImageUrl;
  final String? hairStyle;
  final String? beardStyle;
  final String title;
  final String? notes;
  final String? whyItSuits;
  final int? suitabilityScore;
  final String? maintenanceLevel;
  final String? hairLengthCm;
  final String? beardLengthMm;
  final String? stylingProducts;
  final List<String> barberInstructions;
  final DateTime createdAt;

  const AiSavedLookItem({
    required this.id,
    this.jobId,
    this.archetypeId,
    this.optionNumber,
    required this.originalImageUrl,
    required this.styledImageUrl,
    this.hairStyle,
    this.beardStyle,
    required this.title,
    this.notes,
    this.whyItSuits,
    this.suitabilityScore,
    this.maintenanceLevel,
    this.hairLengthCm,
    this.beardLengthMm,
    this.stylingProducts,
    this.barberInstructions = const [],
    required this.createdAt,
  });

  factory AiSavedLookItem.fromJson(Map<String, dynamic> json) {
    final rawInstr = json['barber_instructions'] as List<dynamic>? ?? const [];
    return AiSavedLookItem(
      id: json['id'] as String? ?? '',
      jobId: json['job_id'] as String?,
      archetypeId: json['archetype_id'] as String?,
      optionNumber: (json['option_number'] as num?)?.toInt(),
      originalImageUrl: json['original_image_url'] as String? ?? '',
      styledImageUrl: json['styled_image_url'] as String? ?? '',
      hairStyle: json['hair_style'] as String?,
      beardStyle: json['beard_style'] as String?,
      title: json['title'] as String? ?? 'My AI Look',
      notes: json['notes'] as String?,
      whyItSuits: json['why_it_suits'] as String?,
      suitabilityScore: (json['suitability_score'] as num?)?.toInt(),
      maintenanceLevel: json['maintenance_level'] as String?,
      hairLengthCm: json['hair_length_cm'] as String?,
      beardLengthMm: json['beard_length_mm'] as String?,
      stylingProducts: json['styling_products'] as String?,
      barberInstructions: rawInstr.map((e) => e.toString()).toList(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

abstract class AiStyleState {}

class AiStyleInitialState extends AiStyleState {}

class AiStyleConfigState extends AiStyleState {
  final File? selectedImage;
  final String? selectedImageBase64;
  final PhotoAnalysisSummary? photoAnalysis;
  final bool isAnalyzingPhoto;
  final List<AiStyleOption> hairStyles;
  final List<AiStyleOption> beardStyles;
  final String? selectedHairStyle;
  final String? selectedBeardStyle;
  final String? selectedColor;
  final String maintenanceLevel;
  final String styleVibe;
  final String hairLengthPref;
  final String beardPref;
  final int variationsCount;
  final bool consentGiven;
  final bool isServiceOnline;
  final String? errorMessage;

  AiStyleConfigState({
    this.selectedImage,
    this.selectedImageBase64,
    this.photoAnalysis,
    this.isAnalyzingPhoto = false,
    this.hairStyles = const [],
    this.beardStyles = const [],
    this.selectedHairStyle,
    this.selectedBeardStyle,
    this.selectedColor,
    this.maintenanceLevel = 'any',
    this.styleVibe = 'any',
    this.hairLengthPref = 'any',
    this.beardPref = 'any',
    this.variationsCount = 6,
    this.consentGiven = true,
    this.isServiceOnline = true,
    this.errorMessage,
  });

  bool get hasPhotoSelected => selectedImageBase64 != null;

  AiStyleConfigState copyWith({
    File? selectedImage,
    String? selectedImageBase64,
    PhotoAnalysisSummary? photoAnalysis,
    bool? isAnalyzingPhoto,
    List<AiStyleOption>? hairStyles,
    List<AiStyleOption>? beardStyles,
    String? selectedHairStyle,
    String? selectedBeardStyle,
    String? selectedColor,
    String? maintenanceLevel,
    String? styleVibe,
    String? hairLengthPref,
    String? beardPref,
    int? variationsCount,
    bool? consentGiven,
    bool? isServiceOnline,
    String? errorMessage,
    bool clearImage = false,
    bool clearAnalysis = false,
    bool clearHairStyle = false,
    bool clearBeardStyle = false,
  }) {
    return AiStyleConfigState(
      selectedImage: clearImage ? null : (selectedImage ?? this.selectedImage),
      selectedImageBase64:
          clearImage ? null : (selectedImageBase64 ?? this.selectedImageBase64),
      photoAnalysis: (clearImage || clearAnalysis)
          ? null
          : (photoAnalysis ?? this.photoAnalysis),
      isAnalyzingPhoto: isAnalyzingPhoto ?? this.isAnalyzingPhoto,
      hairStyles: hairStyles ?? this.hairStyles,
      beardStyles: beardStyles ?? this.beardStyles,
      selectedHairStyle:
          clearHairStyle ? null : (selectedHairStyle ?? this.selectedHairStyle),
      selectedBeardStyle: clearBeardStyle
          ? null
          : (selectedBeardStyle ?? this.selectedBeardStyle),
      selectedColor: selectedColor ?? this.selectedColor,
      maintenanceLevel: maintenanceLevel ?? this.maintenanceLevel,
      styleVibe: styleVibe ?? this.styleVibe,
      hairLengthPref: hairLengthPref ?? this.hairLengthPref,
      beardPref: beardPref ?? this.beardPref,
      variationsCount: variationsCount ?? this.variationsCount,
      consentGiven: consentGiven ?? this.consentGiven,
      isServiceOnline: isServiceOnline ?? this.isServiceOnline,
      errorMessage: errorMessage,
    );
  }
}

class AiStyleUploadingState extends AiStyleState {
  final String message;
  AiStyleUploadingState({this.message = 'Uploading your portrait securely...'});
}

class AiStyleAnalyzingState extends AiStyleState {
  final String message;
  AiStyleAnalyzingState({
    this.message = 'Analyzing face proportions, hairline & beard density...',
  });
}

class AiStyleGeneratingState extends AiStyleState {
  final String message;
  final String stage;
  final double progress;
  AiStyleGeneratingState({
    this.message =
        'Synthesizing personalized hair & beard styles on your portrait...',
    this.stage = 'GENERATING',
    this.progress = 0.65,
  });
}

class AiStyleSuccessState extends AiStyleState {
  final String originalImageUrl;
  final String? storyboardImageUrl;
  final List<AiVariation> variations;
  final List<String> barberNotes;
  final Map<String, dynamic>? bestOption;
  final PhotoAnalysisSummary? analysis;
  final Map<String, dynamic>? preferences;
  final String? hairStyle;
  final String? beardStyle;
  final String jobId;
  final bool isPartiallyCompleted;
  final bool isSaving;

  AiStyleSuccessState({
    required this.originalImageUrl,
    this.storyboardImageUrl,
    required this.variations,
    this.barberNotes = const [],
    this.bestOption,
    this.analysis,
    this.preferences,
    this.hairStyle,
    this.beardStyle,
    required this.jobId,
    this.isPartiallyCompleted = false,
    this.isSaving = false,
  });

  AiStyleSuccessState copyWith({bool? isSaving}) {
    return AiStyleSuccessState(
      originalImageUrl: originalImageUrl,
      storyboardImageUrl: storyboardImageUrl,
      variations: variations,
      barberNotes: barberNotes,
      bestOption: bestOption,
      analysis: analysis,
      preferences: preferences,
      hairStyle: hairStyle,
      beardStyle: beardStyle,
      jobId: jobId,
      isPartiallyCompleted: isPartiallyCompleted,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class AiStyleErrorState extends AiStyleState {
  final String error;
  AiStyleErrorState(this.error);
}

class AiSavedLooksLoadingState extends AiStyleState {}

class AiEmptySavedLooksState extends AiStyleState {}

class AiSavedLooksLoadedState extends AiStyleState {
  final List<AiSavedLookItem> looks;
  AiSavedLooksLoadedState(this.looks);
}

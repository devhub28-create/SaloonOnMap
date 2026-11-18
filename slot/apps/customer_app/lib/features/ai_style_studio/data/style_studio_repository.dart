import 'package:api_client/api_client.dart';

import '../cubit/ai_style_state.dart';

class StyleStudioRepository {
  final ApiClient apiClient;

  const StyleStudioRepository({required this.apiClient});

  Future<Map<String, dynamic>> fetchOptions() => apiClient.getAiStyleOptions();

  Future<Map<String, dynamic>> checkHealth() => apiClient.getAiStyleHealth();

  Future<PhotoAnalysisSummary> analyzePhoto(String imageBase64) async {
    final res = await apiClient.analyzeAiPhoto(imageBase64: imageBase64);
    final rawAnalysis = res['analysis'] is Map<String, dynamic>
        ? res['analysis'] as Map<String, dynamic>
        : (res['analysis'] is Map
            ? Map<String, dynamic>.from(res['analysis'])
            : <String, dynamic>{});
    return PhotoAnalysisSummary.fromJson(rawAnalysis);
  }

  Future<Map<String, dynamic>> createGeneration({
    required String imageBase64,
    String? sideImageBase64,
    String? backImageBase64,
    String? hairStyle,
    String? beardStyle,
    String maintenanceLevel = 'any',
    String styleVibe = 'any',
    String hairLengthPref = 'any',
    String beardPref = 'any',
    int variationsCount = 6,
    bool consentGiven = true,
    bool async = true,
  }) {
    return apiClient.generateAiStyle(
      imageBase64: imageBase64,
      sideImageBase64: sideImageBase64,
      backImageBase64: backImageBase64,
      hairStyle: hairStyle,
      beardStyle: beardStyle,
      maintenanceLevel: maintenanceLevel,
      styleVibe: styleVibe,
      hairLengthPref: hairLengthPref,
      beardPref: beardPref,
      variationsCount: variationsCount,
      mode: 'storyboard',
      consentGiven: consentGiven,
      async: async,
    );
  }

  Future<Map<String, dynamic>> getJob(String jobId) =>
      apiClient.getAiStyleJob(jobId);

  Future<Map<String, dynamic>> deleteGeneration(String jobId) =>
      apiClient.deleteAiStyleGeneration(jobId);

  Future<AiSavedLookItem> saveLook({
    required String jobId,
    required String originalImageUrl,
    required AiVariation variation,
    String? customTitle,
    String? customNotes,
  }) async {
    final res = await apiClient.saveAiLook(
      jobId: jobId,
      archetypeId: variation.archetypeId,
      optionNumber: variation.optionNumber,
      originalImageUrl: originalImageUrl,
      styledImageUrl: variation.imageUrl,
      hairStyle: variation.hairStyle,
      beardStyle: variation.beardStyle,
      title: customTitle ?? variation.styleLabel,
      notes: customNotes ??
          [
            variation.hairDesc,
            variation.beardDesc,
            variation.lookDesc,
          ].whereType<String>().where((s) => s.isNotEmpty).join(' • '),
      whyItSuits: variation.whyItSuits,
      suitabilityScore: variation.suitabilityScore,
      maintenanceLevel: variation.maintenanceLevel,
      hairLengthCm: variation.hairLengthCm,
      beardLengthMm: variation.beardLengthMm,
      stylingProducts: variation.stylingProducts,
      barberInstructions: variation.barberInstructions,
    );
    return AiSavedLookItem.fromJson(res);
  }

  Future<List<AiSavedLookItem>> getSavedLooks() async {
    final raw = await apiClient.getSavedAiLooks();
    return raw
        .map(
          (e) => AiSavedLookItem.fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }

  Future<void> deleteSavedLook(String lookId) async {
    await apiClient.deleteSavedAiLook(lookId);
  }

  Future<Map<String, dynamic>> shareSavedLook(String lookId) =>
      apiClient.shareAiLook(lookId);
}

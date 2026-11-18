import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:api_client/api_client.dart';

import '../data/style_studio_repository.dart';
import 'ai_style_state.dart';

class AiStyleCubit extends Cubit<AiStyleState> {
  final ApiClient apiClient;
  late final StyleStudioRepository repository;
  final ImagePicker _picker = ImagePicker();

  AiStyleCubit({required this.apiClient, StyleStudioRepository? repository})
      : super(AiStyleInitialState()) {
    this.repository = repository ?? StyleStudioRepository(apiClient: apiClient);
  }

  Future<void> initStudio() async {
    emit(AiStyleConfigState());
    try {
      final optionsFuture = repository.fetchOptions();
      final healthFuture = repository.checkHealth();

      final optionsData = await optionsFuture;
      final healthData = await healthFuture;

      final hairList = (optionsData['hairStyles'] as List<dynamic>? ?? [])
          .map((e) => AiStyleOption.fromJson(e as Map<String, dynamic>))
          .toList();

      final beardList = (optionsData['beardStyles'] as List<dynamic>? ?? [])
          .map((e) => AiStyleOption.fromJson(e as Map<String, dynamic>))
          .toList();

      final isOnline = healthData['online'] == true;

      emit(
        AiStyleConfigState(
          hairStyles: hairList,
          beardStyles: beardList,
          isServiceOnline: isOnline,
        ),
      );
    } catch (e) {
      emit(
        AiStyleConfigState(
          hairStyles: const [
            AiStyleOption(
              id: 'classic_taper',
              name: 'Classic Taper',
              description: 'Balanced low taper with textured top',
            ),
            AiStyleOption(
              id: 'textured_crop',
              name: 'Textured Crop',
              description: 'Modern crop with point-cut top and mid taper',
            ),
            AiStyleOption(
              id: 'classic_side_part',
              name: 'Classic Side Part',
              description: 'Refined side part with structured top',
            ),
            AiStyleOption(
              id: 'modern_quiff',
              name: 'Modern Quiff',
              description: 'Lifted front quiff with tapered temples',
            ),
            AiStyleOption(
              id: 'buzz_cut',
              name: 'Crew / Buzz Cut',
              description: 'Athletic short crew cut with tight taper',
            ),
            AiStyleOption(
              id: 'textured_fringe',
              name: 'Textured Fringe',
              description: 'Forward-swept layered fringe',
            ),
          ],
          beardStyles: const [
            AiStyleOption(
              id: 'clean_shaven',
              name: 'Clean Shaven',
              description: 'Smooth, hair-free jawline',
            ),
            AiStyleOption(
              id: 'stubble',
              name: 'Designer Stubble',
              description: '2–3 mm refined designer stubble',
            ),
            AiStyleOption(
              id: 'short_beard',
              name: 'Short Boxed Beard',
              description: '4–6 mm manicured short beard',
            ),
            AiStyleOption(
              id: 'full_beard',
              name: 'Well-Groomed Beard',
              description: '6–8 mm sculpted medium beard',
            ),
            AiStyleOption(
              id: 'goatee',
              name: 'Tailored Goatee',
              description: '5–7 mm circle goatee with clean cheeks',
            ),
          ],
          isServiceOnline: false,
        ),
      );
    }
  }

  Future<void> pickPhoto(ImageSource source) async {
    final currentState = state;
    if (currentState is! AiStyleConfigState) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (picked != null) {
        final file = File(picked.path);
        final bytes = await file.readAsBytes();
        final b64 = base64Encode(bytes);
        final updated = currentState.copyWith(
          selectedImage: file,
          selectedImageBase64: b64,
          isAnalyzingPhoto: true,
          clearAnalysis: true,
          errorMessage: null,
        );
        emit(updated);

        // Run live photo analysis so Screen B immediately shows face proportions & quality check
        try {
          final summary = await repository.analyzePhoto(b64);
          final latest = state;
          if (latest is AiStyleConfigState &&
              latest.selectedImageBase64 == b64) {
            emit(
              latest.copyWith(
                photoAnalysis: summary,
                isAnalyzingPhoto: false,
                errorMessage: (!summary.faceDetected || !summary.isAcceptable)
                    ? (summary.rejectionReason ??
                        'Please choose a clear front-facing portrait.')
                    : null,
              ),
            );
          }
        } catch (e) {
          final latest = state;
          if (latest is AiStyleConfigState) {
            emit(
              latest.copyWith(
                isAnalyzingPhoto: false,
                errorMessage:
                    (e is DioException && e.response?.statusCode == 400)
                        ? _formatError(e)
                        : null,
              ),
            );
          }
        }
      }
    } catch (e) {
      emit(
        currentState.copyWith(
          errorMessage: 'Failed to access camera/photo: $e',
        ),
      );
    }
  }

  void clearPhoto() {
    final currentState = state;
    if (currentState is! AiStyleConfigState) return;
    emit(
      currentState.copyWith(
        clearImage: true,
        clearAnalysis: true,
        errorMessage: null,
      ),
    );
  }

  void selectHairStyle(String? id) {
    final currentState = state;
    if (currentState is! AiStyleConfigState) return;
    emit(
      currentState.copyWith(
        selectedHairStyle: id,
        clearHairStyle: id == null,
        errorMessage: null,
      ),
    );
  }

  void selectBeardStyle(String? id) {
    final currentState = state;
    if (currentState is! AiStyleConfigState) return;
    emit(
      currentState.copyWith(
        selectedBeardStyle: id,
        clearBeardStyle: id == null,
        errorMessage: null,
      ),
    );
  }

  void setMaintenanceLevel(String level) {
    final currentState = state;
    if (currentState is! AiStyleConfigState) return;
    emit(currentState.copyWith(maintenanceLevel: level, errorMessage: null));
  }

  void setStyleVibe(String vibe) {
    final currentState = state;
    if (currentState is! AiStyleConfigState) return;
    emit(currentState.copyWith(styleVibe: vibe, errorMessage: null));
  }

  void setHairLengthPref(String pref) {
    final currentState = state;
    if (currentState is! AiStyleConfigState) return;
    emit(currentState.copyWith(hairLengthPref: pref, errorMessage: null));
  }

  void setBeardPref(String pref) {
    final currentState = state;
    if (currentState is! AiStyleConfigState) return;
    emit(currentState.copyWith(beardPref: pref, errorMessage: null));
  }

  void setVariationsCount(int count) {
    final currentState = state;
    if (currentState is! AiStyleConfigState) return;
    emit(currentState.copyWith(variationsCount: count.clamp(1, 6)));
  }

  void setConsent(bool consent) {
    final currentState = state;
    if (currentState is! AiStyleConfigState) return;
    emit(currentState.copyWith(consentGiven: consent, errorMessage: null));
  }

  Future<void> generateStyles() async {
    final currentState = state;
    if (currentState is! AiStyleConfigState) return;

    if (currentState.selectedImageBase64 == null) {
      emit(
        currentState.copyWith(
          errorMessage: 'Please upload or capture a portrait photo first.',
        ),
      );
      return;
    }

    if (!currentState.consentGiven) {
      emit(
        currentState.copyWith(
          errorMessage: 'Consent is required before processing your photo.',
        ),
      );
      return;
    }

    if (currentState.photoAnalysis != null &&
        (!currentState.photoAnalysis!.faceDetected ||
            !currentState.photoAnalysis!.isAcceptable)) {
      emit(
        currentState.copyWith(
          errorMessage: currentState.photoAnalysis!.rejectionReason ??
              'No clear front-facing face detected. Please upload a clearer photo.',
        ),
      );
      return;
    }

    emit(AiStyleUploadingState());
    await Future<void>.delayed(const Duration(milliseconds: 120));
    emit(AiStyleAnalyzingState());
    await Future<void>.delayed(const Duration(milliseconds: 150));
    emit(
      AiStyleGeneratingState(
        message:
            'Synthesizing ${currentState.variationsCount} personalized hair & beard styles on your portrait...',
        stage: 'GENERATING',
        progress: 0.65,
      ),
    );

    try {
      final initialRes = await repository.createGeneration(
        imageBase64: currentState.selectedImageBase64!,
        hairStyle: currentState.selectedHairStyle,
        beardStyle: currentState.selectedBeardStyle,
        maintenanceLevel: currentState.maintenanceLevel,
        styleVibe: currentState.styleVibe,
        hairLengthPref: currentState.hairLengthPref,
        beardPref: currentState.beardPref,
        variationsCount: currentState.variationsCount,
        consentGiven: true,
        async: true,
      );

      Map<String, dynamic> res = initialRes;
      var status = res['status'] as String? ?? '';
      final jobId = res['id'] as String? ?? '';

      // If job is queued or processing asynchronously, poll until completion
      if (jobId.isNotEmpty &&
          (status == 'PROCESSING' ||
              status == 'ANALYZING' ||
              status == 'PENDING' ||
              status.isEmpty)) {
        const maxAttempts = 150; // up to 5 minutes (150 * 2s)
        int attempts = 0;
        while (attempts < maxAttempts) {
          await Future<void>.delayed(const Duration(seconds: 2));
          attempts++;
          try {
            final polled = await repository.getJob(jobId);
            res = polled;
            status = res['status'] as String? ?? '';
            final stage = res['progress_stage'] as String? ?? 'GENERATING';
            final compCount =
                (res['completed_variations'] as num?)?.toInt() ?? 0;
            final targetCount = (res['variations_count'] as num?)?.toInt() ??
                currentState.variationsCount;

            if (status == 'COMPLETED' ||
                status == 'PARTIALLY_COMPLETED' ||
                status == 'FAILED') {
              break;
            }

            final progressFraction = targetCount > 0
                ? (0.15 + (compCount / targetCount) * 0.8).clamp(0.15, 0.95)
                : 0.5;
            final stageMessage = stage == 'ANALYZING'
                ? 'Analyzing facial landmarks & cranial geometry...'
                : 'Synthesizing variation ${compCount + 1} of $targetCount...';

            emit(
              AiStyleGeneratingState(
                message: stageMessage,
                stage: stage,
                progress: progressFraction,
              ),
            );
          } catch (_) {
            // Transient polling error, continue loop
          }
        }
      }

      if (status == 'FAILED') {
        final errorMsg =
            res['error_message'] as String? ?? 'Local AI generation failed.';
        emit(AiStyleErrorState(errorMsg));
        return;
      }

      final origUrl = res['original_image_url'] as String? ?? '';
      final rawVariations = res['variations'] as List<dynamic>? ?? [];
      final firstVarMap = rawVariations.isNotEmpty &&
              rawVariations.first is Map<String, dynamic>
          ? rawVariations.first as Map<String, dynamic>
          : <String, dynamic>{};

      final storyboardUrl = (res['storyboard_image_url'] as String?) ??
          (firstVarMap['storyboard_image_url'] as String?);

      final rawBarberNotes = (res['barber_notes'] as List<dynamic>?) ??
          (firstVarMap['barber_notes'] as List<dynamic>?) ??
          const [];
      final barberNotes = rawBarberNotes.map((e) => e.toString()).toList();

      final bestOptionRaw = res['best_option'] ?? firstVarMap['best_option'];
      final bestOption = bestOptionRaw is Map<String, dynamic>
          ? bestOptionRaw
          : (bestOptionRaw is Map
              ? Map<String, dynamic>.from(bestOptionRaw)
              : null);

      final rawAnalysis = res['analysis'] ?? res['analysis_result'];
      final analysisSummary = rawAnalysis is Map
          ? PhotoAnalysisSummary.fromJson(
              Map<String, dynamic>.from(rawAnalysis),
            )
          : currentState.photoAnalysis;

      final rawPrefs = res['preferences'];
      final prefsMap =
          rawPrefs is Map ? Map<String, dynamic>.from(rawPrefs) : null;

      final variations = rawVariations
          .map(
            (e) => AiVariation.fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();

      if (variations.isEmpty) {
        emit(
          AiStyleErrorState(
            'No variations were generated by the local AI service.',
          ),
        );
        return;
      }

      emit(
        AiStyleSuccessState(
          originalImageUrl: origUrl,
          storyboardImageUrl: storyboardUrl,
          variations: variations,
          barberNotes: barberNotes,
          bestOption: bestOption,
          analysis: analysisSummary,
          preferences: prefsMap,
          hairStyle: currentState.selectedHairStyle,
          beardStyle: currentState.selectedBeardStyle,
          jobId: jobId,
          isPartiallyCompleted: status == 'PARTIALLY_COMPLETED',
        ),
      );
    } catch (e) {
      emit(
        AiStyleErrorState(
          _formatError(e, fallbackPrefix: 'Style generation error'),
        ),
      );
    }
  }

  Future<bool> saveLook(
    AiVariation variation, {
    String? title,
    String? notes,
  }) async {
    final currentState = state;
    if (currentState is! AiStyleSuccessState) return false;

    emit(currentState.copyWith(isSaving: true));
    try {
      await repository.saveLook(
        jobId: currentState.jobId,
        originalImageUrl: currentState.originalImageUrl,
        variation: variation,
        customTitle: title,
        customNotes: notes,
      );
      emit(currentState.copyWith(isSaving: false));
      return true;
    } catch (e) {
      emit(currentState.copyWith(isSaving: false));
      return false;
    }
  }

  Future<bool> saveStoryboard() async {
    final currentState = state;
    if (currentState is! AiStyleSuccessState ||
        currentState.storyboardImageUrl == null) {
      return false;
    }

    final topVar = currentState.variations.firstWhere(
      (v) => v.isRecommended,
      orElse: () => currentState.variations.first,
    );

    emit(currentState.copyWith(isSaving: true));
    try {
      await apiClient.saveAiLook(
        jobId: currentState.jobId,
        archetypeId: topVar.archetypeId,
        optionNumber: topVar.optionNumber,
        originalImageUrl: currentState.originalImageUrl,
        styledImageUrl: currentState.storyboardImageUrl!,
        hairStyle: topVar.hairStyle ?? 'personalized_storyboard',
        beardStyle: topVar.beardStyle ?? 'personalized_storyboard',
        title: 'Personalized Storyboard (${topVar.styleLabel})',
        notes: currentState.barberNotes.join(' • '),
        whyItSuits: topVar.whyItSuits,
        suitabilityScore: topVar.suitabilityScore,
        maintenanceLevel: topVar.maintenanceLevel,
        hairLengthCm: topVar.hairLengthCm,
        beardLengthMm: topVar.beardLengthMm,
        stylingProducts: topVar.stylingProducts,
        barberInstructions: topVar.barberInstructions,
      );
      emit(currentState.copyWith(isSaving: false));
      return true;
    } catch (e) {
      emit(currentState.copyWith(isSaving: false));
      return false;
    }
  }

  Future<bool> deleteCurrentGeneration() async {
    final currentState = state;
    if (currentState is! AiStyleSuccessState || currentState.jobId.isEmpty) {
      return false;
    }
    try {
      await repository.deleteGeneration(currentState.jobId);
      await initStudio();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadSavedLooks() async {
    emit(AiSavedLooksLoadingState());
    try {
      final looks = await repository.getSavedLooks();
      if (looks.isEmpty) {
        emit(AiEmptySavedLooksState());
      } else {
        emit(AiSavedLooksLoadedState(looks));
      }
    } catch (e) {
      emit(
        AiStyleErrorState(
          _formatError(e, fallbackPrefix: 'Failed to load saved looks'),
        ),
      );
    }
  }

  Future<void> deleteSavedLook(String lookId) async {
    final currentState = state;
    if (currentState is! AiSavedLooksLoadedState) return;
    try {
      await repository.deleteSavedLook(lookId);
      final updated = currentState.looks.where((l) => l.id != lookId).toList();
      if (updated.isEmpty) {
        emit(AiEmptySavedLooksState());
      } else {
        emit(AiSavedLooksLoadedState(updated));
      }
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> shareSavedLook(String lookId) async {
    try {
      return await repository.shareSavedLook(lookId);
    } catch (_) {
      return null;
    }
  }

  String _formatError(dynamic e, {String fallbackPrefix = 'Error'}) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Unable to connect right now. Check your internet connection and try again.';
      }
      if (e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return 'Style generation timed out on the inference server. Please try again with fewer variations or a clearer portrait photo.';
      }
      final data = e.response?.data;
      if (data is Map) {
        if (data['message'] != null) {
          final msg = data['message'];
          if (msg is List) return msg.join(', ');
          return msg.toString();
        }
        if (data['error_message'] != null) {
          return data['error_message'].toString();
        }
        if (data['detail'] != null) {
          return data['detail'].toString();
        }
      }
      if (e.response?.statusCode == 401) {
        return 'Authentication required. Please sign in to your SLOT account to generate and save styles.';
      }
      if (e.response?.statusCode == 413) {
        return 'Photo file is too large. Please select a photo under 10MB.';
      }
      if (e.message != null && e.message!.isNotEmpty) {
        return e.message!;
      }
    }
    return '$fallbackPrefix: $e';
  }
}

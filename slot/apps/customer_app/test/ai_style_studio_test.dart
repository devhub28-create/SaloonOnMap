import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/features/ai_style_studio/cubit/ai_style_state.dart';

void main() {
  group('AI Style Studio Dynamic Models & State Tests', () {
    test('PhotoAnalysisSummary parses computer-vision analysis payload', () {
      final json = {
        'face_detected': true,
        'quality': {
          'is_acceptable': true,
          'warnings': ['Slight head turn detected'],
        },
        'face_geometry': {
          'estimated_face_shape': 'oblong',
          'confidence': 0.85,
          'shape_guidance': 'Balanced top height suits oblong proportions.',
        },
        'hair_analysis': {
          'estimated_current_length': 'long_or_voluminous',
          'visible_texture': 'wavy_textured',
          'hair_density': 'dense',
          'forehead_exposure': 'balanced',
          'eyewear_detected': true,
        },
        'facial_hair_analysis': {
          'estimated_current_facial_hair': 'light_stubble',
        },
      };

      final summary = PhotoAnalysisSummary.fromJson(json);
      expect(summary.faceDetected, isTrue);
      expect(summary.isAcceptable, isTrue);
      expect(summary.estimatedFaceShape, 'oblong');
      expect(summary.eyewearDetected, isTrue);
      expect(summary.currentHairLength, 'long_or_voluminous');
      expect(summary.warnings.length, 1);
    });

    test('AiVariation enforces honest side/back view availability', () {
      final jsonFrontOnly = {
        'id': 'var_1',
        'archetype_id': 'classic_taper_boxed_beard',
        'option_number': 1,
        'image_url': '/uploads/ai-styles/generated/gen_1.png',
        'side_view_available': false,
        'back_view_available': false,
        'style_label': 'Classic Taper + Short Boxed Beard',
        'suitability_score': 98,
        'is_recommended': true,
        'barber_instructions': ['Low #2 taper on sides'],
      };

      final v = AiVariation.fromJson(jsonFrontOnly);
      expect(v.optionNumber, 1);
      expect(v.isRecommended, isTrue);
      expect(v.suitabilityScore, 98);
      expect(v.sideViewAvailable, isFalse);
      expect(v.backViewAvailable, isFalse);
      expect(v.barberInstructions.first, 'Low #2 taper on sides');
    });

    test('AiStyleConfigState copyWith updates customer preferences cleanly',
        () {
      final initial = AiStyleConfigState();
      final updated = initial.copyWith(
        maintenanceLevel: 'low',
        styleVibe: 'professional',
        hairLengthPref: 'short',
        beardPref: 'short_beard',
        variationsCount: 4,
      );

      expect(updated.maintenanceLevel, 'low');
      expect(updated.styleVibe, 'professional');
      expect(updated.hairLengthPref, 'short');
      expect(updated.beardPref, 'short_beard');
      expect(updated.variationsCount, 4);
    });
  });
}

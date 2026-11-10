# SLOT AI Style Studio — Legacy Implementation Audit & Removal Plan

## 1. Executive Summary

Before rebuilding **SLOT AI Style Studio** from scratch with dynamic photo analysis, a deterministic preference- & geometry-driven recommendation engine, and genuine local image-to-image generation, we audited the entire repository (`slot/apps/customer_app`, `slot/packages/api_client`, `slot/apps/backend`, and `slot/apps/ai_style_service`).

The previous implementation suffered from fundamental architectural flaws that violated the dynamic, customer-driven requirements:
1. **Hardcoded Static 6-Option Array (`STORYBOARD_OPTIONS`)**: `slot/apps/ai_style_service/pipeline.py` hardcoded the exact six style titles, hex headers, descriptions, and option #3 recommendation (`is_recommended: True` on Option 3) from a static reference image.
2. **Static Reference Template Compositing (`storyboard_template.jpg`)**: Instead of generating styles dynamically from a recommendation engine, `pipeline.py` cropped hair from `assets/storyboard_template.jpg` (a static reference image of another person) and pasted results back onto that static `1024×1024` JPEG template.
3. **Fabricated Static Side & Back Views (`assets/side_1..6.png`, `assets/back_1..6.png`)**: The service returned static cropped images of the reference person's side and back head for every customer, regardless of the customer's actual appearance or whether side/back photos were uploaded.
4. **Hardcoded Barber Notes & Fixed Best Option**: `pipeline.py` returned a hardcoded 5-bullet `barber_notes` list and always selected `Option 3: Classic Taper + Short Beard` as the `best_option`.
5. **Missing Structured Photo Analysis**: There was no structured photo quality, pose, lighting, hair texture/length/density, or facial-hair visibility analysis stored per job, nor honest fallbacks when face visibility or pose angle was unsuitable.
6. **Synchronous Monolithic UI State**: The Flutter `AiStyleCubit` only had a single `AiStyleGeneratingState` instead of granular real-time job lifecycle states (`Initial`, `PhotoSelected`, `Uploading`, `Analyzing`, `PreparingMasks`, `Generating`, `PartiallyCompleted`, `Completed`, `Saving`, `Failed`, `SavedLooksLoading`, `SavedLooksLoaded`, `EmptySavedLooks`) and lacked a dedicated repository layer, Barber Instructions share sheet (Screen E), and Preference/Photo Review screen (Screen B).

---

## 2. Inventory of Audited Files

### 2.1 Python AI Service (`slot/apps/ai_style_service/`)
| File / Asset | Legacy Issue Identified | Action Taken |
|---|---|---|
| `assets/storyboard_template.jpg` | Static reference image of another person used for hair extraction and storyboard pasting | **DELETED** |
| `assets/side_1.png` .. `side_6.png` | Static side-view crops of reference person attached to every user's results | **DELETED** |
| `assets/back_1.png` .. `back_6.png` | Static back-view crops of reference person attached to every user's results | **DELETED** |
| `pipeline.py` | Contained hardcoded `STORYBOARD_OPTIONS`, static `storyboard_template.jpg` warping, fixed Option 3 recommendation, and hardcoded `barber_notes` | **REPLACED** with modular `analyzer.py`, `recommender.py`, `generator.py`, and `storyboard_renderer.py` |
| `main.py` | Lacked `/api/v1/analyze` endpoint, structured preference parameters, concurrency lock/queueing, and honest side/back handling | **REBUILT** with full analysis, recommendation, and generation pipeline |
| `benchmark_optimizations.py`, `benchmark_test_faces.py` | Obsolete scratch scripts from prototype | **DELETED** |

### 2.2 NestJS Backend (`slot/apps/backend/src/modules/ai-style/` & `entities/`)
| File | Legacy Issue Identified | Action Taken |
|---|---|---|
| `src/entities/ai-style-job.entity.ts` | Lacked `analysis_result` (`jsonb`), `preferences` (`jsonb`), `recommended_option_id`, `progress_stage`, `completed_variations`, and sharing metadata; defaulted `hair_style` to `'storyboard_6_looks'` | **REBUILT** with full lifecycle states, analysis JSONB, preferences JSONB, dynamic options, and migration |
| `src/entities/ai-saved-look.entity.ts` | Lacked structured `option_id`, `maintenance_level`, `hair_length`, `beard_length`, `barber_instructions`, `suitability_explanation`, `is_shared`, and `share_token` | **UPDATED** to persist complete look metadata and explicit access-controlled sharing |
| `src/modules/ai-style/ai-style.controller.ts` | Only exposed legacy `/ai-style/generate` and `/ai-style/looks` without `/style-studio/generations`, `/style-studio/looks/:id/save`, `/style-studio/looks/:id/share`, pagination, or image deletion | **REBUILT** to support both `/api/v1/style-studio/*` (primary) and `/api/v1/ai-style/*` compatibility routes |
| `src/modules/ai-style/ai-style.service.ts` | Hardcoded `optNum === 3` as `is_recommended`, wrote shared `ref_side_*.png` files, and lacked photo-analysis persistence or file cleanup on deletion | **REBUILT** with dynamic analysis, recommendation engine integration, private storage cleanup on delete, and ownership checks |

### 2.3 Flutter Customer App (`slot/apps/customer_app/lib/features/ai_style_studio/` & `slot/packages/api_client/`)
| File | Legacy Issue Identified | Action Taken |
|---|---|---|
| `presentation/ai_style_studio_screen.dart` | Hardcoded `previewItems` array (`Classic Side Part`, `Short Textured Crop`, etc.), hardcoded fallback `barberNotes`, and combined Landing + Config into a single static screen | **REBUILT** into modular screens: **Screen A (Landing)**, **Screen B (Photo Review & Preferences)**, **Screen C (Live Generation Progress)**, **Screen D (Personalized Storyboard)**, **Screen E (Barber Instructions & Share Sheet)**, and **Screen F (Saved Looks)** |
| `cubit/ai_style_cubit.dart` & `ai_style_state.dart` | Missing repository layer, hardcoded fallback style lists, missing granular states (`PhotoSelected`, `Uploading`, `Analyzing`, `Generating`, `PartiallyCompleted`, `Completed`, `Saving`, `EmptySavedLooks`) | **REBUILT** with clean Repository pattern (`StyleStudioRepository`), typed models, and all 12 explicit states |
| `packages/api_client/lib/api_client.dart` | Missing methods for photo analysis, generation list pagination, saving/unsaving by look ID, sharing looks, and deleting generation jobs | **UPDATED** with complete `style-studio` API client methods |

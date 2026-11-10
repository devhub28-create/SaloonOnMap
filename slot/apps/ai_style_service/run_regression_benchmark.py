import os
import json
import time
import base64
from io import BytesIO
import numpy as np
from PIL import Image

from pipeline import AiStyleEngine
from style_spec import compose_style_specification

ARTIFACT_DIR = "/Users/manishdubey/.gemini/antigravity/brain/aad37d72-35ae-4411-b5ce-5e319350d0d6"
INPUT_PHOTO = os.path.join(ARTIFACT_DIR, ".user_uploaded/media_1791869599296.jpg")
BENCH_OUT_DIR = os.path.join(os.path.dirname(__file__), "benchmark_outputs")

SCENARIOS = [
    {
        "scenario_id": "scenario_1_classic_side_part_clean_shaven",
        "name": "Scenario 1 — Classic Side Part + Clean Shaven",
        "hair_style": "classic_side_part",
        "beard_style": "clean_shaven",
        "custom_title": "Classic Side Part (Clean Shaven)",
        "header_hex": "#1E3A5F",
    },
    {
        "scenario_id": "scenario_2_textured_crop_light_stubble",
        "name": "Scenario 2 — Short Textured Crop + Light Stubble",
        "hair_style": "textured_crop",
        "beard_style": "stubble",
        "custom_title": "Short Textured Crop (Light Stubble)",
        "header_hex": "#1F3D3A",
    },
    {
        "scenario_id": "scenario_3_classic_taper_short_beard",
        "name": "Scenario 3 — Classic Taper + Short Beard",
        "hair_style": "classic_taper",
        "beard_style": "short_beard",
        "custom_title": "Classic Taper + Short Beard",
        "header_hex": "#283E5D",
    },
    {
        "scenario_id": "scenario_4_quiff_style_well_groomed_beard",
        "name": "Scenario 4 — Quiff Style + Well-Groomed Beard",
        "hair_style": "modern_quiff",
        "beard_style": "full_beard",
        "custom_title": "Quiff Style + Well-Groomed Beard",
        "header_hex": "#3B3355",
    },
    {
        "scenario_id": "scenario_5_crew_cut_short_beard",
        "name": "Scenario 5 — Crew Cut + Short Beard",
        "hair_style": "buzz_cut",
        "beard_style": "short_beard",
        "custom_title": "Crew Cut + Short Beard",
        "header_hex": "#4E3629",
    },
    {
        "scenario_id": "scenario_6_textured_fringe_light_beard",
        "name": "Scenario 6 — Textured Fringe + Light Beard",
        "hair_style": "textured_fringe",
        "beard_style": "light_beard",
        "custom_title": "Textured Fringe + Light Beard",
        "header_hex": "#3E3349",
    },
]


def main():
    os.makedirs(BENCH_OUT_DIR, exist_ok=True)
    models_dir = os.path.join(os.path.dirname(__file__), "models")
    engine = AiStyleEngine.get_instance(models_dir=models_dir)

    raw_img = Image.open(INPUT_PHOTO)
    oriented_img, analysis, pts, cat_mask = engine.analyzer.analyze(raw_img)
    ctx = engine.generator.prepare_customer_context(oriented_img, pts, cat_mask)

    # Save aligned original portrait for direct side-by-side comparison
    orig_aligned_path = os.path.join(BENCH_OUT_DIR, "input_aligned_customer.png")
    Image.fromarray(ctx["u_slot"]).save(orig_aligned_path)
    Image.fromarray(ctx["u_slot"]).save(os.path.join(ARTIFACT_DIR, "bench_input_aligned.png"))

    results = []
    portraits = []

    for idx, sc in enumerate(SCENARIOS):
        t0 = time.time()
        spec = compose_style_specification(
            hairstyle_id=sc["hair_style"],
            beard_style_id=sc["beard_style"],
            spec_id=sc["scenario_id"],
            custom_title=sc["custom_title"],
            custom_header_hex=sc["header_hex"],
        )

        styled_pil, diag = engine.generator.render_from_specification(
            ctx, spec, strength_mult=1.0, return_diagnostics=True
        )
        val = engine.validator.validate_single_output(ctx, styled_pil, spec, diagnostics=diag)
        if not val["passed"]:
            styled_pil, diag = engine.generator.render_from_specification(
                ctx, spec, strength_mult=1.18, return_diagnostics=True
            )
            val = engine.validator.validate_single_output(ctx, styled_pil, spec, diagnostics=diag)
            val["retried"] = True
        else:
            val["retried"] = False

        elapsed = round(time.time() - t0, 3)
        portraits.append(styled_pil)

        out_img_path = os.path.join(BENCH_OUT_DIR, f"{sc['scenario_id']}.png")
        hair_mask_path = os.path.join(BENCH_OUT_DIR, f"{sc['scenario_id']}_hair_mask.png")
        beard_mask_path = os.path.join(BENCH_OUT_DIR, f"{sc['scenario_id']}_beard_mask.png")

        styled_pil.save(out_img_path)
        styled_pil.save(os.path.join(ARTIFACT_DIR, f"bench_{idx + 1}_{sc['hair_style']}_{sc['beard_style']}.png"))

        h_m_img = Image.fromarray(np.clip(diag["target_hair_mask"] * 255.0, 0, 255).astype(np.uint8))
        b_m_img = Image.fromarray(np.clip(diag["active_beard_mask"] * 255.0, 0, 255).astype(np.uint8))
        h_m_img.save(hair_mask_path)
        b_m_img.save(beard_mask_path)

        results.append({
            "scenario_number": idx + 1,
            "scenario_id": sc["scenario_id"],
            "scenario_name": sc["name"],
            "input_image": INPUT_PHOTO,
            "style_specification": spec.dict(),
            "positive_prompt": spec.positive_prompt,
            "negative_prompt": spec.negative_prompt,
            "hair_mask_path": hair_mask_path,
            "beard_mask_path": beard_mask_path,
            "output_image_path": out_img_path,
            "artifact_image_path": os.path.join(ARTIFACT_DIR, f"bench_{idx + 1}_{sc['hair_style']}_{sc['beard_style']}.png"),
            "validation": val,
            "generation_time_seconds": elapsed,
        })
        print(
            f"[Scenario {idx + 1}] {sc['name']} -> passed={val['passed']}, "
            f"hair_l1={val['hair_l1_diff']}, id_sim={val['identity_similarity']}, "
            f"chin_dark={val['chin_darkening']}, cheek_dark={val['cheek_darkening']}, "
            f"ring_halo={val['outer_ring_bg_diff']}, time={elapsed}s"
        )

    batch_div = engine.validator.validate_batch_diversity(portraits)
    print(f"[Batch Diversity] distinct={batch_div['distinct_from_peers']}, min_l1={batch_div['min_pairwise_l1']}, mean_l1={batch_div['mean_pairwise_l1']}")

    # Also run full pipeline generate_personalized_styles to produce the updated 6-card Storyboard
    full_res = engine.generate_personalized_styles(raw_img, preferences={}, count=6)
    sb_bytes = base64.b64decode(full_res["storyboard_image_base64"])
    sb_path = os.path.join(BENCH_OUT_DIR, "storyboard_v4_regression.png")
    with open(sb_path, "wb") as f:
        f.write(sb_bytes)
    with open(os.path.join(ARTIFACT_DIR, "storyboard_v4_regression.png"), "wb") as f:
        f.write(sb_bytes)

    summary = {
        "input_photo": INPUT_PHOTO,
        "face_analysis": analysis,
        "batch_diversity": batch_div,
        "storyboard_path": sb_path,
        "scenarios": results,
    }
    report_json_path = os.path.join(BENCH_OUT_DIR, "regression_benchmark_report.json")
    with open(report_json_path, "w") as f:
        json.dump(summary, f, indent=2)
    print(f"Saved full regression report to {report_json_path}")


if __name__ == "__main__":
    main()

from typing import Dict, Any, List, Optional
from style_spec import (
    StyleSpecification,
    HAIRSTYLE_SPECS,
    BEARD_SPECS,
    compose_style_specification,
)


def _build_catalog_entry(
    archetype_id: str,
    hair_style: str,
    beard_style: str,
    custom_title: Optional[str] = None,
    custom_header_hex: Optional[str] = None,
) -> Dict[str, Any]:
    spec = compose_style_specification(
        hairstyle_id=hair_style,
        beard_style_id=beard_style,
        spec_id=archetype_id,
        custom_title=custom_title,
        custom_header_hex=custom_header_hex,
    )
    h_meta = HAIRSTYLE_SPECS[spec.hairstyle]
    b_meta = BEARD_SPECS[spec.beard_style]

    return {
        "archetype_id": archetype_id,
        "title": spec.title,
        "hair_style": spec.hairstyle,
        "beard_style": spec.beard_style,
        "header_hex": spec.header_hex,
        "hair_category": h_meta["hair_category"],
        "beard_category": b_meta["beard_category"],
        "maintenance_level": spec.maintenance_level,
        "vibes": h_meta["vibes"],
        "suitable_shapes": h_meta["suitable_shapes"],
        "hair_length_cm": f"{spec.top_length}, {spec.side_length}",
        "beard_length_mm": spec.beard_length_mm,
        "hair_desc": spec.hair_desc,
        "beard_desc": spec.beard_desc,
        "look_desc": spec.look_desc,
        "styling_products": spec.styling_products,
        "barber_instructions": spec.barber_instructions,
        "style_spec": spec.dict(),
        "render_params": {
            "hair_style": spec.hairstyle,
            "beard_style": spec.beard_style,
            "spec": spec.dict(),
            "crown_lift": spec.crown_height_ratio,
            "side_width": spec.side_thickness_ratio,
            "fringe_drop": spec.fringe_coverage_ratio,
            "fade_height": "high_skin" if spec.temple_fade_strength >= 0.8 else ("high" if spec.temple_fade_strength >= 0.65 else ("mid" if spec.temple_fade_strength >= 0.45 else "low")),
            "texture_freq": spec.strand_flow_mode,
        },
    }


STYLE_CATALOG: List[Dict[str, Any]] = [
    _build_catalog_entry(
        archetype_id="executive_side_part_clean",
        hair_style="classic_side_part",
        beard_style="clean_shaven",
        custom_title="Classic Side Part (Clean Shaven)",
        custom_header_hex="#1E3A5F",
    ),
    _build_catalog_entry(
        archetype_id="textured_crop_light_stubble",
        hair_style="textured_crop",
        beard_style="stubble",
        custom_title="Short Textured Crop (Light Stubble)",
        custom_header_hex="#1F3D3A",
    ),
    _build_catalog_entry(
        archetype_id="classic_taper_boxed_beard",
        hair_style="classic_taper",
        beard_style="short_beard",
        custom_title="Classic Taper + Short Beard",
        custom_header_hex="#283E5D",
    ),
    _build_catalog_entry(
        archetype_id="modern_quiff_groomed_beard",
        hair_style="modern_quiff",
        beard_style="full_beard",
        custom_title="Quiff Style + Well-Groomed Beard",
        custom_header_hex="#3B3355",
    ),
    _build_catalog_entry(
        archetype_id="tapered_crew_cut_short_beard",
        hair_style="buzz_cut",
        beard_style="short_beard",
        custom_title="Crew Cut + Short Beard",
        custom_header_hex="#4E3629",
    ),
    _build_catalog_entry(
        archetype_id="textured_fringe_light_beard",
        hair_style="textured_fringe",
        beard_style="light_beard",
        custom_title="Textured Fringe + Light Beard",
        custom_header_hex="#3E3349",
    ),
    _build_catalog_entry(
        archetype_id="ivy_league_clean_stubble",
        hair_style="ivy_league",
        beard_style="stubble",
        custom_title="Ivy League Taper + Light Stubble",
        custom_header_hex="#244743",
    ),
    _build_catalog_entry(
        archetype_id="layered_wavy_flow_short_beard",
        hair_style="medium_length",
        beard_style="short_beard",
        custom_title="Layered Medium Flow + Short Beard",
        custom_header_hex="#2E3B4E",
    ),
    _build_catalog_entry(
        archetype_id="skin_fade_buzz_heavy_stubble",
        hair_style="fade",
        beard_style="light_beard",
        custom_title="High Skin Fade Crop + Light Beard",
        custom_header_hex="#3D2E2E",
    ),
    _build_catalog_entry(
        archetype_id="pompadour_taper_goatee",
        hair_style="curly_style",
        beard_style="goatee",
        custom_title="Structured Pompadour + Tailored Goatee",
        custom_header_hex="#362C47",
    ),
]


FACE_SHAPE_DIAGNOSTICS: Dict[str, Dict[str, Any]] = {
    "oblong": {
        "title": "Oblong Face Architecture",
        "description": "Longer vertical proportions benefit from forward texture or fringes that reduce forehead exposure, paired with beard styles that add horizontal jawline width.",
        "best_styles": {
            "textured_crop_light_stubble": (97, "Forward choppy crop layers minimize vertical height and add horizontal balance across your oblong face shape"),
            "textured_fringe_light_beard": (93, "Forward fringe coverage shortens forehead exposure and adds width along the cheekbones"),
            "classic_taper_boxed_beard": (88, "Low taper sides with a boxed beard square off your jawline without adding excessive crown height"),
            "ivy_league_clean_stubble": (82, "Side-swept short taper maintains neat proportions without excess vertical volume"),
            "layered_wavy_flow_short_beard": (78, "Side wavy volume creates width balance, though requires more daily styling"),
            "tapered_crew_cut_short_beard": (73, "Short buzz cut is neutral, but benefits from beard width to avoid lengthening"),
            "executive_side_part_clean": (70, "Clean-shaven bare chin provides less horizontal structure for oblong jawlines"),
            "skin_fade_buzz_heavy_stubble": (67, "High skin fade can over-accentuate vertical head elongation"),
            "pompadour_taper_goatee": (64, "Pointed goatee and pompadour lift can undesirably lengthen oblong facial proportions"),
            "modern_quiff_groomed_beard": (62, "Tall quiff adds vertical lift that further elongates oblong facial proportions"),
        },
    },
    "round": {
        "title": "Round Face Architecture",
        "description": "Rounder facial proportions benefit from high crown volume (quiffs/pompadours) and tight faded sides that visually elongate and slim the face outline.",
        "best_styles": {
            "modern_quiff_groomed_beard": (97, "Lifted quiff height on top with tapered sides elongates and slims round facial contours"),
            "skin_fade_buzz_heavy_stubble": (92, "High contrast skin fade eliminates side bulk to sculpt sharp cheekbone definition"),
            "pompadour_taper_goatee": (88, "Vertical pompadour volume with an angular goatee adds chin length and definition"),
            "executive_side_part_clean": (84, "Structured side parting creates diagonal lines that break up round facial symmetry"),
            "classic_taper_boxed_beard": (80, "Boxed beard gives angular structure to rounder cheeks"),
            "textured_crop_light_stubble": (74, "Flat crop can accentuate facial roundness without adequate crown lift"),
            "textured_fringe_light_beard": (66, "Forward heavy fringe shortens the forehead, making a round face appear wider"),
        },
    },
    "square": {
        "title": "Square Face Architecture",
        "description": "Strong, chiseled square jawlines are complemented by soft scissor-textured cuts that balance strong bone structure without looking boxy.",
        "best_styles": {
            "classic_taper_boxed_beard": (96, "Soft scissor-textured top complements your chiseled jawline without creating a boxy silhouette"),
            "textured_crop_light_stubble": (92, "Choppy texture softens strong square temple angles while accentuating a strong jawline"),
            "executive_side_part_clean": (88, "Clean razor-shaven jawline showcases sharp, masculine angular facial structure"),
            "tapered_crew_cut_short_beard": (85, "Athletic crew cut pairs naturally with strong square facial bone structure"),
            "modern_quiff_groomed_beard": (82, "Adds stylish crown lift above a strong square jawline"),
        },
    },
    "oval": {
        "title": "Oval Face Architecture",
        "description": "Naturally balanced and symmetrical proportions provide freedom to wear almost any structured haircut or tailored beard style.",
        "best_styles": {
            "executive_side_part_clean": (96, "Symmetrical, balanced facial proportions naturally suit sleek side-parted tailoring"),
            "textured_crop_light_stubble": (93, "Versatile modern crop provides effortless everyday polish on oval proportions"),
            "classic_taper_boxed_beard": (90, "Classic barbershop low taper with manicured beard frames balanced features"),
            "modern_quiff_groomed_beard": (86, "Confident upward brush-up highlights balanced cheek and eye symmetry"),
        },
    },
    "heart": {
        "title": "Heart / Diamond Architecture",
        "description": "Wider cheekbones or forehead with a tapered chin are balanced by textured flows and fuller beards that add lower-face width.",
        "best_styles": {
            "layered_wavy_flow_short_beard": (96, "Medium flow volume softens forehead width while short beard fills a narrower chin"),
            "textured_fringe_light_beard": (92, "Fringe narrows wide temple lines while light beard balances the tapered jaw"),
            "classic_taper_boxed_beard": (87, "Boxed beard adds necessary weight and structure to the lower third of the face"),
        },
    },
}


class StyleRecommendationEngine:
    """
    Deterministic, explainable recommendation and style-specification engine.
    - Honors explicit customer hairstyle and/or beard_style selections first (constructing a
      validated StyleSpecification dynamically so requested styles are never lost or overridden).
    - Scores and ranks diverse companion styles using MediaPipe 478-landmark face geometry,
      forehead exposure, eyewear detection, hair texture, and customer preferences.
    """

    def select_recommendations(
        self,
        analysis: Dict[str, Any],
        preferences: Optional[Dict[str, Any]] = None,
        count: int = 6,
    ) -> Dict[str, Any]:
        prefs = preferences or {}
        req_maintenance = (prefs.get("maintenance_level") or "any").lower().strip()
        req_vibe = (prefs.get("style_vibe") or "any").lower().strip()
        req_hair_len = (prefs.get("hair_length_pref") or "any").lower().strip()
        req_beard_pref = (prefs.get("beard_pref") or "any").lower().strip()
        req_hair_style = (prefs.get("hair_style") or "").lower().strip()
        req_beard_style = (prefs.get("beard_style") or "").lower().strip()

        if req_hair_style == "any":
            req_hair_style = ""
        if req_beard_style == "any":
            req_beard_style = ""
        if req_hair_style == "crew_cut":
            req_hair_style = "buzz_cut"

        face_geo = analysis.get("face_geometry", {})
        hair_info = analysis.get("hair_analysis", {})
        beard_info = analysis.get("facial_hair_analysis", {})

        face_shape = face_geo.get("estimated_face_shape", "oval")
        if face_shape not in FACE_SHAPE_DIAGNOSTICS:
            face_shape = "oval"

        fh_exposure = hair_info.get("forehead_exposure", "balanced")
        cur_hair_len = hair_info.get("estimated_current_length", "medium")
        cur_texture = hair_info.get("visible_texture", "wavy_textured")
        eyewear = hair_info.get("eyewear_detected", False)
        cur_beard = beard_info.get("estimated_current_facial_hair", "light_stubble")

        scored_candidates: List[Dict[str, Any]] = []

        # If customer explicitly requested a specific hair_style or beard_style
        explicit_primary: Optional[Dict[str, Any]] = None
        if req_hair_style in HAIRSTYLE_SPECS or req_beard_style in BEARD_SPECS:
            target_h = req_hair_style if req_hair_style in HAIRSTYLE_SPECS else "classic_taper"
            if req_beard_style in BEARD_SPECS:
                target_b = req_beard_style
            elif req_beard_pref in BEARD_SPECS:
                target_b = req_beard_pref
            else:
                matched_b = next(
                    (item["beard_style"] for item in STYLE_CATALOG if item["hair_style"] == target_h),
                    "short_beard",
                )
                target_b = matched_b

            explicit_entry = _build_catalog_entry(
                archetype_id=f"custom__{target_h}__{target_b}",
                hair_style=target_h,
                beard_style=target_b,
            )
            explicit_entry["suitability_score"] = 98
            explicit_entry["why_it_suits"] = (
                f"Directly tailored to your selected {HAIRSTYLE_SPECS[target_h]['label']} and "
                f"{BEARD_SPECS[target_b]['label']} specification for your {face_shape} face shape. "
                f"(Styling guidance score: 98/100)"
            )
            explicit_primary = explicit_entry

        shape_data = FACE_SHAPE_DIAGNOSTICS.get(face_shape, FACE_SHAPE_DIAGNOSTICS["oval"])
        style_scores = shape_data["best_styles"]

        for item in STYLE_CATALOG:
            arch_id = item["archetype_id"]
            if arch_id in style_scores:
                base_score, shape_reason = style_scores[arch_id]
            else:
                base_score, shape_reason = 75, "Versatile cut balancing crown volume and jawline structure"

            score = float(base_score)
            reasons = [shape_reason]

            # Adjust score by eyewear
            if eyewear and item["render_params"]["fade_height"] in ("low", "mid"):
                score += 2.0
                reasons.append("neat temple fade leaves space for eyeglasses frames")

            # Adjust score by customer explicit preferences
            if req_maintenance != "any":
                if item["maintenance_level"] == req_maintenance:
                    score += 8.0
                else:
                    score -= 8.0

            if req_vibe != "any":
                if req_vibe in item["vibes"]:
                    score += 10.0
                else:
                    score -= 10.0

            if req_hair_len != "any":
                if item["hair_category"] == req_hair_len:
                    score += 10.0
                else:
                    score -= 10.0

            if req_beard_pref != "any":
                if item["beard_style"] == req_beard_pref or item["beard_category"] == req_beard_pref:
                    score += 15.0
                else:
                    score -= 15.0

            if req_hair_style and req_hair_style == item["hair_style"]:
                score += 25.0
            if req_beard_style and req_beard_style == item["beard_style"]:
                score += 20.0

            final_score = int(round(max(60.0, min(98.0, score))))
            why_text = f"{reasons[0]}. (Face Suitability: {final_score}%)"

            cand = dict(item)
            cand["suitability_score"] = final_score
            cand["why_it_suits"] = why_text
            scored_candidates.append(cand)

        # Sort deterministically by suitability_score descending, then archetype_id
        scored_candidates.sort(key=lambda x: (-x["suitability_score"], x["archetype_id"]))

        target_count = max(1, min(6, count))
        selected: List[Dict[str, Any]] = []
        used_pairs = set()

        if explicit_primary is not None:
            selected.append(explicit_primary)
            used_pairs.add((explicit_primary["hair_style"], explicit_primary["beard_style"]))

        for cand in scored_candidates:
            if len(selected) >= target_count:
                break
            pair_key = (cand["hair_style"], cand["beard_style"])
            if pair_key in used_pairs:
                continue
            selected.append(cand)
            used_pairs.add(pair_key)

        best_opt = None
        for idx, opt in enumerate(selected):
            opt["option_number"] = idx + 1
            opt["is_recommended"] = idx == 0
            if idx == 0:
                best_opt = {
                    "option_number": opt["option_number"],
                    "archetype_id": opt["archetype_id"],
                    "title": f"Option {opt['option_number']}: {opt['title']}",
                    "reason": opt["why_it_suits"],
                    "suitability_score": opt["suitability_score"],
                    "face_shape": face_shape.replace("_", " ").title(),
                    "maintenance_level": opt["maintenance_level"].title(),
                    "style_spec": opt["style_spec"],
                }

        barber_notes: List[str] = []
        if eyewear:
            barber_notes.append(
                "Eyewear fit: Ask your barber for a clean low-to-mid temple taper so hair sits neatly around your glasses arms."
            )
        else:
            barber_notes.append(
                "Sides & Temples: Ask for a low-to-mid taper (#2 to #3 guard) blended smoothly into the parietal ridge."
            )

        if cur_texture == "wavy_textured":
            barber_notes.append(
                "Texture handling: Use point-cutting on top to embrace your natural wave without bulky side weight."
            )
        elif cur_texture == "curly_coily":
            barber_notes.append(
                "Curl definition: Scissor-layer the top and apply a leave-in curl cream on damp hair."
            )
        else:
            barber_notes.append(
                "Top texture: Ask for light texturizing shears at the ends for natural lift and movement."
            )

        if best_opt and selected:
            top_item = selected[0]
            barber_notes.append(f"Recommended length: {top_item['hair_length_cm']}.")
            barber_notes.append(f"Facial hair guide: {top_item['beard_length_mm']}.")
            barber_notes.append(f"Daily product: {top_item['styling_products']}.")

        return {
            "selected_options": selected,
            "best_option": best_opt,
            "barber_notes": barber_notes,
        }

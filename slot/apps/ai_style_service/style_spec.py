from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field, validator


class StyleSpecification(BaseModel):
    """
    Typed, validated structured styling specification for a single hairstyle + beard combination.
    Used across recommendation, mask construction, multi-stage hair/beard synthesis, prompt construction,
    output validation, database storage, and Flutter Storyboard/Barber cards.
    """

    spec_id: str
    title: str
    header_hex: str = "#1E3A5F"

    # Hair specification fields
    hairstyle: str
    top_length: str
    side_length: str
    back_length: str
    hair_texture: str
    parting: Optional[str] = None
    fringe: Optional[str] = None
    volume: str
    taper_type: Optional[str] = None
    fade_type: Optional[str] = None

    # Facial hair / beard specification fields
    beard_style: str
    beard_length_mm: str
    moustache_style: Optional[str] = None
    cheek_line: Optional[str] = None
    neckline: Optional[str] = None

    # Finish & care
    finish: str
    maintenance_level: str
    styling_products: str
    barber_instructions: List[str] = Field(default_factory=list)
    hair_desc: str = ""
    beard_desc: str = ""
    look_desc: str = ""

    # Prompting & conditioning
    positive_prompt: str = ""
    negative_prompt: str = ""

    # Geometric & synthesis targets for mask construction, strand synthesis, and output validation
    crown_height_ratio: float = 1.0      # Relative top height above cranial brow-to-hairline distance
    side_thickness_ratio: float = 0.85   # Relative temple/parietal width
    fringe_coverage_ratio: float = 0.0   # 0.0 = exposed forehead, >0 = forward fringe covering upper forehead
    strand_flow_mode: str = "side_part_right"  # side_part_right, crop_forward, taper_swept, quiff_upward, crew_short, fringe_forward, wavy_flow
    temple_fade_strength: float = 0.35   # 0.0 (full scissor) to 0.88 (high skin fade)
    beard_density_target: float = 0.0    # 0.0 (clean_shaven) to 0.92 (full_beard)
    beard_cheek_height: float = 0.0      # 0.0 (none/goatee) to 0.75 (full beard)

    @validator("maintenance_level")
    def validate_maintenance(cls, v: str) -> str:
        v_low = v.lower().strip()
        if v_low not in ("low", "medium", "high"):
            return "medium"
        return v_low

    def validate_consistency(self) -> List[str]:
        """Verifies no contradictory hair or beard attributes exist in the specification."""
        issues: List[str] = []
        if self.beard_style == "clean_shaven":
            if self.beard_density_target > 0.05:
                issues.append("clean_shaven cannot have beard_density_target > 0.05")
            if "beard" in self.positive_prompt.lower() and "clean-shaven" not in self.positive_prompt.lower():
                issues.append("clean_shaven positive prompt contains conflicting beard instruction")
        else:
            if "clean-shavensmooth bare face" in self.positive_prompt.lower():
                issues.append(f"{self.beard_style} prompt conflicts with clean-shaven instruction")

        if self.hairstyle in ("crew_cut", "buzz_cut", "high_skin_fade_buzz") and self.volume in ("high_front_lift", "full_layered"):
            issues.append(f"{self.hairstyle} cannot specify high volume ({self.volume})")

        if self.hairstyle == "textured_fringe" and self.fringe_coverage_ratio < 0.20:
            issues.append("textured_fringe must specify positive fringe_coverage_ratio >= 0.20")

        return issues


# Modular Hairstyle Component Specifications
HAIRSTYLE_SPECS: Dict[str, Dict[str, Any]] = {
    "classic_side_part": {
        "hairstyle": "classic_side_part",
        "label": "Classic Side Part",
        "header_hex": "#1E3A5F",
        "hair_category": "medium",
        "top_length": "6–8 cm combed top",
        "side_length": "#3 guard (10 mm) classic scissor/clipper taper",
        "back_length": "Graduated #2–#3 tapered neckline",
        "hair_texture": "sleek_combed",
        "parting": "left_side_part",
        "fringe": "swept_aside_exposed_forehead",
        "volume": "moderate",
        "taper_type": "low_taper",
        "fade_type": "none",
        "finish": "medium_pomade_sheen",
        "maintenance_level": "medium",
        "styling_products": "Water-based medium-shine pomade or styling cream",
        "hair_desc": "Defined left side part with neatly combed medium top (6–8 cm) and tapered sides.",
        "look_desc": "Sharp, formal, timeless executive polish.",
        "suitable_shapes": ["oval", "square", "round", "diamond", "uncertain"],
        "vibes": ["professional", "classic"],
        "crown_height_ratio": 1.02,
        "side_thickness_ratio": 0.78,
        "fringe_coverage_ratio": 0.0,
        "strand_flow_mode": "side_part_right",
        "temple_fade_strength": 0.35,
        "barber_steps": [
            "Part the hair cleanly along the natural left recession line and comb the top (6–8 cm) smoothly to the right.",
            "Graduate the sides with a #3 clipper-over-comb low taper around the ears and nape.",
        ],
    },
    "textured_crop": {
        "hairstyle": "textured_crop",
        "label": "Short Textured Crop",
        "header_hex": "#1F3D3A",
        "hair_category": "short",
        "top_length": "3.5–5 cm choppy point-cut top",
        "side_length": "#1.5 to #2.5 mid-low taper",
        "back_length": "Tapered #1.5–#2 nape",
        "hair_texture": "choppy_point_cut",
        "parting": "none",
        "fringe": "short_choppy_forward",
        "volume": "low",
        "taper_type": "mid_taper",
        "fade_type": "low_drop_fade",
        "finish": "natural_matte",
        "maintenance_level": "low",
        "styling_products": "Sea salt spray + matte texture clay or powder",
        "hair_desc": "Short point-cut textured crop on top (3.5–5 cm) directed forward with clean tapered sides.",
        "look_desc": "Casual, crisp, modern, easy to maintain.",
        "suitable_shapes": ["oval", "oblong", "heart", "diamond", "uncertain"],
        "vibes": ["modern", "casual"],
        "crown_height_ratio": 0.86,
        "side_thickness_ratio": 0.70,
        "fringe_coverage_ratio": 0.26,
        "strand_flow_mode": "crop_forward",
        "temple_fade_strength": 0.58,
        "barber_steps": [
            "Point-cut the top to 4 cm and style forward into a short choppy crop with natural irregular texture (no side part).",
            "Clipper mid-low taper on the sides (#1.5 to #2.5) keeping weight tight at the parietal ridge.",
        ],
    },
    "classic_taper": {
        "hairstyle": "classic_taper",
        "label": "Classic Taper",
        "header_hex": "#283E5D",
        "hair_category": "medium",
        "top_length": "5–7 cm textured brushed-back top",
        "side_length": "#2–#3 guard low taper around temples",
        "back_length": "Natural low-tapered neckline",
        "hair_texture": "natural_textured",
        "parting": "soft_left_sweep",
        "fringe": "swept_up_and_aside",
        "volume": "moderate",
        "taper_type": "low_taper",
        "fade_type": "none",
        "finish": "natural_matte",
        "maintenance_level": "low",
        "styling_products": "Matte hair clay or light grooming cream",
        "hair_desc": "Side-parted low taper with natural textured top (5–7 cm) and scissor-blended temples.",
        "look_desc": "Balanced, stylish, versatile for both office and casual settings.",
        "suitable_shapes": ["oval", "oblong", "square", "diamond", "uncertain"],
        "vibes": ["professional", "classic", "casual"],
        "crown_height_ratio": 0.98,
        "side_thickness_ratio": 0.76,
        "fringe_coverage_ratio": 0.05,
        "strand_flow_mode": "taper_swept",
        "temple_fade_strength": 0.38,
        "barber_steps": [
            "Keep the sides as a low taper (#2 to #3 guard, not an aggressive skin fade) around the ears and neckline.",
            "Maintain 5–7 cm length on top with point-cutting for natural directional flow.",
        ],
    },
    "modern_quiff": {
        "hairstyle": "modern_quiff",
        "label": "Quiff Style",
        "header_hex": "#3B3355",
        "hair_category": "medium",
        "top_length": "7–9 cm lifted front quiff",
        "side_length": "#2 guard mid taper blended with shears",
        "back_length": "Graduated #2 tapered back",
        "hair_texture": "voluminous_lifted",
        "parting": "upward_back",
        "fringe": "lifted_upward_quiff",
        "volume": "high_front_lift",
        "taper_type": "mid_taper",
        "fade_type": "low_drop_fade",
        "finish": "textured_dry_matte",
        "maintenance_level": "medium",
        "styling_products": "Volumizing pre-styler + strong-hold matte clay",
        "hair_desc": "Voluminous lifted front quiff (7–9 cm) brushed upward and back with clean low-mid tapered sides.",
        "look_desc": "Trendy, confident, structured high-contrast silhouette.",
        "suitable_shapes": ["round", "square", "oval", "heart", "uncertain"],
        "vibes": ["modern", "professional", "casual"],
        "crown_height_ratio": 1.18,
        "side_thickness_ratio": 0.74,
        "fringe_coverage_ratio": 0.0,
        "strand_flow_mode": "quiff_upward",
        "temple_fade_strength": 0.50,
        "barber_steps": [
            "Leave 7–9 cm at the front hairline, blow-dried upward and slightly back for pronounced front lift.",
            "Taper the temples and sides (#2 guard) blended into scissor work at the parietal ridge.",
        ],
    },
    "buzz_cut": {
        "hairstyle": "buzz_cut",
        "label": "Crew Cut",
        "header_hex": "#4E3629",
        "hair_category": "short",
        "top_length": "2–3.5 cm short graduated crew top",
        "side_length": "#1 to #2 tight high-mid taper",
        "back_length": "Tight #1–#2 tapered nape",
        "hair_texture": "short_uniform_crop",
        "parting": "none",
        "fringe": "none_exposed_forehead",
        "volume": "minimal",
        "taper_type": "high_taper",
        "fade_type": "mid_fade",
        "finish": "natural_matte",
        "maintenance_level": "low",
        "styling_products": "Light matte paste (optional)",
        "hair_desc": "Crew cut with short even top (2–4 cm), clearly short tapered sides, and minimal volume.",
        "look_desc": "Sharp, athletic, clean, ultra-low maintenance.",
        "suitable_shapes": ["oval", "square", "oblong", "round", "uncertain"],
        "vibes": ["casual", "classic", "professional"],
        "crown_height_ratio": 0.68,
        "side_thickness_ratio": 0.58,
        "fringe_coverage_ratio": 0.04,
        "strand_flow_mode": "crew_short",
        "temple_fade_strength": 0.72,
        "barber_steps": [
            "Cut the top short and even (2–3.5 cm at the front runner, graduating shorter toward the crown).",
            "Keep the sides clearly short (#1 to #2 taper) with crisp temple contours.",
        ],
    },
    "textured_fringe": {
        "hairstyle": "textured_fringe",
        "label": "Textured Fringe",
        "header_hex": "#3E3349",
        "hair_category": "medium",
        "top_length": "6–8 cm forward-directed layered top",
        "side_length": "#2–#3 low taper sides",
        "back_length": "Scissor-tapered #2.5 nape",
        "hair_texture": "forward_layered_fringe",
        "parting": "none",
        "fringe": "textured_forehead_fringe",
        "volume": "moderate",
        "taper_type": "low_taper",
        "fade_type": "none",
        "finish": "textured_dry_matte",
        "maintenance_level": "medium",
        "styling_products": "Texture powder or lightweight matte clay",
        "hair_desc": "Forward-directed textured fringe covering the upper forehead with low taper sides.",
        "look_desc": "Young, relaxed, casual, modern.",
        "suitable_shapes": ["oblong", "heart", "diamond", "oval"],
        "vibes": ["modern", "casual"],
        "crown_height_ratio": 0.94,
        "side_thickness_ratio": 0.78,
        "fringe_coverage_ratio": 0.45,
        "strand_flow_mode": "fringe_forward",
        "temple_fade_strength": 0.35,
        "barber_steps": [
            "Direct 6–8 cm top hair forward and point-cut heavily to form a textured fringe over the upper forehead.",
            "Keep a clean low taper on the sides (#2–#3 guard) clear of eyeglasses frames.",
        ],
    },
    "ivy_league": {
        "hairstyle": "ivy_league",
        "label": "Ivy League Taper",
        "header_hex": "#244743",
        "hair_category": "short",
        "top_length": "3.5–4.5 cm side-swept short top",
        "side_length": "#2 guard neat mid taper",
        "back_length": "Graduated #2 nape",
        "hair_texture": "natural_textured",
        "parting": "soft_side_sweep",
        "fringe": "swept_aside",
        "volume": "low",
        "taper_type": "mid_taper",
        "fade_type": "none",
        "finish": "natural_matte",
        "maintenance_level": "low",
        "styling_products": "Light matte styling cream",
        "hair_desc": "Short Ivy League cut (3.5–4.5 cm) swept subtly to the side at the front.",
        "look_desc": "Smart-casual hybrid between a crew cut and classic side part.",
        "suitable_shapes": ["oval", "square", "round", "diamond"],
        "vibes": ["professional", "classic"],
        "crown_height_ratio": 0.78,
        "side_thickness_ratio": 0.66,
        "fringe_coverage_ratio": 0.0,
        "strand_flow_mode": "side_part_right",
        "temple_fade_strength": 0.52,
        "barber_steps": [
            "Scissor-cut top to ~4 cm, leaving just enough length at the front to sweep neatly aside.",
            "Taper sides with a #2 guard.",
        ],
    },
    "medium_length": {
        "hairstyle": "medium_length",
        "label": "Layered Medium Flow",
        "header_hex": "#2E3B4E",
        "hair_category": "long",
        "top_length": "8–10 cm scissor-layered wavy flow",
        "side_length": "3–4 cm scissor-layered sides",
        "back_length": "Scissor-tapered natural nape",
        "hair_texture": "wavy_layered_flow",
        "parting": "center_off_part",
        "fringe": "swept_curtain_flow",
        "volume": "full_layered",
        "taper_type": "scissor_taper",
        "fade_type": "none",
        "finish": "healthy_satin",
        "maintenance_level": "medium",
        "styling_products": "Argan grooming cream or sea-salt texture mist",
        "hair_desc": "Scissor-layered medium flow (8–10 cm) embracing natural wave and movement.",
        "look_desc": "Relaxed, textured, natural movement.",
        "suitable_shapes": ["oblong", "diamond", "heart", "oval", "square"],
        "vibes": ["casual", "modern"],
        "crown_height_ratio": 1.08,
        "side_thickness_ratio": 0.90,
        "fringe_coverage_ratio": 0.14,
        "strand_flow_mode": "wavy_flow",
        "temple_fade_strength": 0.15,
        "barber_steps": [
            "Scissor-cut throughout (no tight clipper fade); leave 8–10 cm on top and 3–4 cm on the sides.",
            "Use slide-cutting to open up natural wave movement.",
        ],
    },
    "fade": {
        "hairstyle": "fade",
        "label": "High Skin Fade Crop",
        "header_hex": "#3D2E2E",
        "hair_category": "short",
        "top_length": "1.5–2.5 cm tight buzz/crop top",
        "side_length": "#0.5 to #1.5 high skin drop fade",
        "back_length": "High skin-faded nape",
        "hair_texture": "short_uniform_crop",
        "parting": "none",
        "fringe": "none_exposed_forehead",
        "volume": "minimal",
        "taper_type": "high_taper",
        "fade_type": "high_skin_fade",
        "finish": "natural_matte",
        "maintenance_level": "low",
        "styling_products": "Moisturizing scalp & matte balm",
        "hair_desc": "Ultra-short cropped top with a high skin fade on the sides.",
        "look_desc": "Bold, high-contrast, minimalist barbershop fade.",
        "suitable_shapes": ["oval", "square", "diamond"],
        "vibes": ["modern", "casual"],
        "crown_height_ratio": 0.62,
        "side_thickness_ratio": 0.50,
        "fringe_coverage_ratio": 0.0,
        "strand_flow_mode": "crew_short",
        "temple_fade_strength": 0.85,
        "barber_steps": [
            "Crop the top short (1.5–2.5 cm) with a sharp front lineup.",
            "Drop-fade the sides from #0.5 skin level up to #1.5 at the parietal ridge.",
        ],
    },
    "curly_style": {
        "hairstyle": "curly_style",
        "label": "Structured Pompadour",
        "header_hex": "#362C47",
        "hair_category": "medium",
        "top_length": "7–9 cm swept-back pompadour",
        "side_length": "#2 guard clean mid taper",
        "back_length": "Tapered #2 neckline",
        "hair_texture": "voluminous_lifted",
        "parting": "upward_back",
        "fringe": "lifted_quiff",
        "volume": "high_front_lift",
        "taper_type": "mid_taper",
        "fade_type": "none",
        "finish": "medium_pomade_sheen",
        "maintenance_level": "high",
        "styling_products": "Blow-dryer + medium-strong pomade",
        "hair_desc": "Swept-back volume on top (7–9 cm) with clean tapered temples.",
        "look_desc": "Distinctive, elongating, statement grooming style.",
        "suitable_shapes": ["round", "oval", "heart"],
        "vibes": ["classic", "modern"],
        "crown_height_ratio": 1.22,
        "side_thickness_ratio": 0.72,
        "fringe_coverage_ratio": 0.0,
        "strand_flow_mode": "quiff_upward",
        "temple_fade_strength": 0.48,
        "barber_steps": [
            "Keep 7–9 cm at the front swept upward and back into a structured pompadour.",
            "Taper the sides cleanly with a #2 guard.",
        ],
    },
}


# Modular Beard Component Specifications
BEARD_SPECS: Dict[str, Dict[str, Any]] = {
    "clean_shaven": {
        "beard_style": "clean_shaven",
        "beard_category": "clean_shaven",
        "label": "Clean Shaven",
        "beard_length_mm": "0 mm clean shaven",
        "moustache_style": "clean_shaven",
        "cheek_line": "clean_shaven",
        "neckline": "clean_shaven",
        "beard_desc": "Clean shaven smooth jawline, cheeks, and upper lip.",
        "beard_density_target": 0.0,
        "beard_cheek_height": 0.0,
        "barber_step": "Perform a close clean shave across the cheeks, jawline, chin, and upper lip with squared sideburns at mid-ear.",
    },
    "stubble": {
        "beard_style": "stubble",
        "beard_category": "stubble",
        "label": "Light Stubble",
        "beard_length_mm": "2–3 mm light stubble",
        "moustache_style": "light_stubble_moustache",
        "cheek_line": "natural_soft",
        "neckline": "defined_1_finger_above_adams_apple",
        "beard_desc": "Light stubble (2–3 mm) across the jawline and upper lip.",
        "beard_density_target": 0.35,
        "beard_cheek_height": 0.35,
        "barber_step": "Trim facial hair evenly to 2–3 mm light stubble with a neat cheek and neck contour.",
    },
    "light_beard": {
        "beard_style": "light_beard",
        "beard_category": "stubble",
        "label": "Light Beard",
        "beard_length_mm": "3–5 mm light beard",
        "moustache_style": "natural_connected",
        "cheek_line": "crisp_boxed",
        "neckline": "defined_1_finger_above_adams_apple",
        "beard_desc": "Light beard (3–5 mm) with clean cheek and neckline borders.",
        "beard_density_target": 0.52,
        "beard_cheek_height": 0.45,
        "barber_step": "Trim facial hair to 3–5 mm with clean cheek lines and a tapered sideburn transition.",
    },
    "short_beard": {
        "beard_style": "short_beard",
        "beard_category": "short_beard",
        "label": "Short Boxed Beard",
        "beard_length_mm": "4–6 mm short boxed beard",
        "moustache_style": "natural_connected",
        "cheek_line": "crisp_boxed",
        "neckline": "defined_1_finger_above_adams_apple",
        "beard_desc": "Short boxed beard (4–6 mm) with defined cheek lines and clean neckline.",
        "beard_density_target": 0.68,
        "beard_cheek_height": 0.52,
        "barber_step": "Shape a 4–6 mm short boxed beard with crisp cheek lines and a clean neckline one finger above the Adam's apple.",
    },
    "full_beard": {
        "beard_style": "full_beard",
        "beard_category": "full_beard",
        "label": "Well-Groomed Beard",
        "beard_length_mm": "5–8 mm well-groomed medium beard",
        "moustache_style": "structured_full",
        "cheek_line": "high_sculpted",
        "neckline": "sharp_contoured",
        "beard_desc": "Medium well-groomed beard (5–8 mm), fuller at the chin and sharply contoured.",
        "beard_density_target": 0.85,
        "beard_cheek_height": 0.65,
        "barber_step": "Sculpt a 5–8 mm well-groomed medium beard with fuller chin density, faded sideburns, and sharp cheek/neck lines.",
    },
    "goatee": {
        "beard_style": "goatee",
        "beard_category": "goatee",
        "label": "Tailored Goatee",
        "beard_length_mm": "5–7 mm connected circle goatee",
        "moustache_style": "connected_goatee",
        "cheek_line": "clean_bare_cheeks",
        "neckline": "sharp_contoured",
        "beard_desc": "Tailored 5–7 mm moustache and chin goatee with clean-shaven bare cheeks.",
        "beard_density_target": 0.72,
        "beard_cheek_height": 0.0,
        "barber_step": "Shave the cheeks completely clean while shaping a connected 5–7 mm circle goatee around the moustache and chin.",
    },
    "moustache": {
        "beard_style": "moustache",
        "beard_category": "moustache",
        "label": "Chevron Moustache",
        "beard_length_mm": "4–6 mm structured moustache, clean jaw",
        "moustache_style": "chevron_featured",
        "cheek_line": "clean_bare_cheeks",
        "neckline": "clean_shaven",
        "beard_desc": "Defined 4–6 mm moustache above the upper lip with clean-shaven cheeks and chin.",
        "beard_density_target": 0.65,
        "beard_cheek_height": 0.0,
        "barber_step": "Sculpt a neat 4–6 mm chevron moustache above the upper lip and shave the cheeks and chin clean.",
    },
}


def build_prompts_from_spec(h_spec: Dict[str, Any], b_spec: Dict[str, Any]) -> Dict[str, str]:
    """
    Constructs physical, non-contradictory positive and negative prompts from the structured
    hairstyle and beard specifications.
    """
    h_id = h_spec["hairstyle"]
    b_id = b_spec["beard_style"]

    hair_clauses = [
        f"{h_spec['label']} men's barbershop haircut",
        f"top length {h_spec['top_length']}",
        f"sides {h_spec['side_length']}",
        f"texture {h_spec['hair_texture'].replace('_', ' ')}",
    ]
    if h_spec.get("parting") and h_spec["parting"] != "none":
        hair_clauses.append(f"distinct {h_spec['parting'].replace('_', ' ')}")
    if h_spec.get("fringe") and "forward" in h_spec["fringe"]:
        hair_clauses.append("forward-directed textured fringe over upper forehead")
    elif h_spec.get("fringe") and "quiff" in h_spec["fringe"]:
        hair_clauses.append("voluminous upward-lifted front quiff")
    elif h_spec.get("fringe") and "exposed" in h_spec["fringe"]:
        hair_clauses.append("clean exposed forehead hairline")

    if b_id == "clean_shaven":
        beard_clause = "clean-shaven smooth bare skin on cheeks, jawline, chin, and upper lip, zero facial hair"
        neg_beard = "beard, stubble, moustache, goatee, facial hair, 5 o'clock shadow"
    elif b_id == "goatee":
        beard_clause = "defined connected circle goatee and moustache on chin with clean-shaven bare cheeks"
        neg_beard = "full cheek beard, Mutton chops, messy neckbeard"
    elif b_id == "moustache":
        beard_clause = "defined chevron moustache above upper lip with clean-shaven bare cheeks and chin"
        neg_beard = "chin beard, cheek beard, full beard"
    else:
        beard_clause = (
            f"{b_spec['label']} facial hair ({b_spec['beard_length_mm']}), "
            f"{b_spec['cheek_line'].replace('_', ' ')} cheek line, {b_spec['neckline'].replace('_', ' ')} neckline"
        )
        neg_beard = "clean shaven bare chin, patchy asymmetrical beard, blurry skin"

    if h_id == "classic_side_part":
        neg_hair = "messy bangs covering forehead, buzz cut, afro, long mullet"
    elif h_id in ("textured_crop", "textured_fringe"):
        neg_hair = "slicked back pompadour, hard side part, bald head"
    elif h_id in ("buzz_cut", "fade"):
        neg_hair = "long flowing hair, big puffy curls, bangs covering forehead, pompadour"
    elif h_id in ("modern_quiff", "curly_style"):
        neg_hair = "flat bangs over forehead, buzz cut, messy uncombed hair"
    else:
        neg_hair = "deformed hair, bald patches, unnatural wig"

    positive = (
        f"photorealistic studio portrait, {', '.join(hair_clauses)}, {beard_clause}, "
        f"{h_spec['finish'].replace('_', ' ')} finish, preserving exact facial identity, eyes, nose, skin tone, and clothing, 8k"
    )
    negative = (
        f"{neg_hair}, {neg_beard}, deformed face, altered eyes, distorted glasses, cartoon, painting, blurry, halo artifact"
    )
    return {"positive_prompt": positive, "negative_prompt": negative}


def compose_style_specification(
    hairstyle_id: str,
    beard_style_id: str,
    spec_id: Optional[str] = None,
    custom_title: Optional[str] = None,
    custom_header_hex: Optional[str] = None,
) -> StyleSpecification:
    """
    Dynamically builds a validated StyleSpecification from any hairstyle_id and beard_style_id.
    Never falls back to contradictory defaults.
    """
    h_key = hairstyle_id if hairstyle_id in HAIRSTYLE_SPECS else "classic_taper"
    b_key = beard_style_id if beard_style_id in BEARD_SPECS else "short_beard"

    h = HAIRSTYLE_SPECS[h_key]
    b = BEARD_SPECS[b_key]

    prompts = build_prompts_from_spec(h, b)

    if b_key == "clean_shaven":
        title = custom_title or f"{h['label']} (Clean Shaven)"
    elif b_key == "stubble" and h_key == "textured_crop":
        title = custom_title or f"{h['label']} (Light Stubble)"
    else:
        title = custom_title or f"{h['label']} + {b['label']}"

    instructions = list(h.get("barber_steps", []))
    if b.get("barber_step"):
        instructions.append(b["barber_step"])

    spec = StyleSpecification(
        spec_id=spec_id or f"{h_key}__{b_key}",
        title=title,
        header_hex=custom_header_hex or h["header_hex"],
        hairstyle=h["hairstyle"],
        top_length=h["top_length"],
        side_length=h["side_length"],
        back_length=h["back_length"],
        hair_texture=h["hair_texture"],
        parting=h.get("parting"),
        fringe=h.get("fringe"),
        volume=h["volume"],
        taper_type=h.get("taper_type"),
        fade_type=h.get("fade_type"),
        beard_style=b["beard_style"],
        beard_length_mm=b["beard_length_mm"],
        moustache_style=b.get("moustache_style"),
        cheek_line=b.get("cheek_line"),
        neckline=b.get("neckline"),
        finish=h["finish"],
        maintenance_level=h["maintenance_level"],
        styling_products=h["styling_products"],
        barber_instructions=instructions,
        hair_desc=h["hair_desc"],
        beard_desc=b["beard_desc"],
        look_desc=h["look_desc"],
        positive_prompt=prompts["positive_prompt"],
        negative_prompt=prompts["negative_prompt"],
        crown_height_ratio=float(h["crown_height_ratio"]),
        side_thickness_ratio=float(h["side_thickness_ratio"]),
        fringe_coverage_ratio=float(h["fringe_coverage_ratio"]),
        strand_flow_mode=str(h["strand_flow_mode"]),
        temple_fade_strength=float(h["temple_fade_strength"]),
        beard_density_target=float(b["beard_density_target"]),
        beard_cheek_height=float(b["beard_cheek_height"]),
    )

    issues = spec.validate_consistency()
    if issues:
        raise ValueError(f"Invalid StyleSpecification ({spec.spec_id}): {'; '.join(issues)}")

    return spec

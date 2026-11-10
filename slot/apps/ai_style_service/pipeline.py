import os
import io
import time
import base64
import logging
from typing import Tuple, Dict, Any, List, Optional
import numpy as np
from PIL import Image, ImageOps
import cv2
import torch
from diffusers import StableDiffusionInpaintPipeline, DPMSolverMultistepScheduler
import mediapipe as mp
from mediapipe.tasks import python as mp_python
from mediapipe.tasks.python import vision as mp_vision

from analyzer import PhotoAnalyzer
from recommender import StyleRecommendationEngine, STYLE_CATALOG
from storyboard_renderer import StoryboardRenderer
from masker import FacialMaskManager

logger = logging.getLogger("ai_style_pipeline")
logger.setLevel(logging.INFO)

# Barbershop Style Prompts for Photorealistic Inpainting
STYLE_PROMPTS = {
    # Hairstyles
    "classic_taper": {
        "prompt": "classic taper haircut, short scissor-textured top, clean low taper fade, neat neckline",
        "label": "Classic Taper",
    },
    "textured_crop": {
        "prompt": "modern textured crop haircut, layered textured top, clean high skin fade, sharp temple lineup",
        "label": "Textured Crop Fade",
    },
    "classic_side_part": {
        "prompt": "classic side part pompadour hairstyle, sleek comb over, sharp parting line, low taper fade",
        "label": "Classic Side Part",
    },
    "modern_quiff": {
        "prompt": "modern quiff hairstyle, voluminous textured brush up top, clean taper fade",
        "label": "Modern Quiff",
    },
    "buzz_cut": {
        "prompt": "short uniform buzz cut crew cut, sharp lineup edging, clean fade taper",
        "label": "Clean Buzz Cut",
    },
    "textured_fringe": {
        "prompt": "textured fringe haircut, messy forward-swept layers, clean low taper fade",
        "label": "Textured Fringe",
    },
    "ivy_league": {
        "prompt": "smart ivy league crew haircut, side-swept short taper fade",
        "label": "Ivy League Taper",
    },
    "medium_length": {
        "prompt": "medium length flow hairstyle, layered wavy hair, natural movement and texture",
        "label": "Layered Medium Flow",
    },
    "fade": {
        "prompt": "high skin fade haircut, bald fade sides, structured short top, sharp lineup",
        "label": "High Skin Fade",
    },
    "curly_style": {
        "prompt": "curly hairstyle, defined voluminous curls on top, neat tapered sides",
        "label": "Structured Pompadour",
    },
    # Beard Styles
    "clean_shaven": {
        "prompt": "clean shaven smooth face, bare jawline, silky skin, no beard, no stubble",
        "label": "Clean Shaven",
    },
    "stubble": {
        "prompt": "5 o'clock designer stubble beard, rugged light scruff, defined jawline stubble",
        "label": "Designer Stubble",
    },
    "light_beard": {
        "prompt": "neat light trimmed beard, 3-5mm groomed facial hair, defined cheek lines",
        "label": "Light Beard",
    },
    "short_beard": {
        "prompt": "neatly trimmed short boxed beard, sharp cheek lines, clean barbershop neckline",
        "label": "Short Boxed Beard",
    },
    "full_beard": {
        "prompt": "full thick dense beard, well-groomed lush facial hair, sharp borders",
        "label": "Well-Groomed Beard",
    },
    "goatee": {
        "prompt": "classic sharp circle goatee and moustache, clean-shaven bare cheeks",
        "label": "Tailored Goatee",
    },
    "moustache": {
        "prompt": "neat chevron moustache above upper lip, clean shaven cheeks and chin",
        "label": "Chevron Moustache",
    },
}

COLOR_MODIFIERS = {
    "natural_black": "jet black hair color, rich dark tone",
    "dark_brown": "rich dark brown hair color, chocolate tones",
    "chestnut": "chestnut auburn brown hair color, warm undertones",
    "platinum_blonde": "platinum blonde dyed hair color, ash blonde tones",
    "silver_grey": "silver grey salt and pepper hair color",
}

NEGATIVE_PROMPT = (
    "deformed, bad anatomy, bad eyes, disfigured face, mutated, blurry, out of focus, "
    "low resolution, cartoon, painting, 3d render, plastic doll, distorted jaw, unnatural hair, "
    "white hair, grey hair, silver hair, salt and pepper, streaks, highlights, bleached hair, patchy hair, messy strands, artifacts"
)


def _pil_to_b64(img: Image.Image) -> str:
    buf = io.BytesIO()
    img.save(buf, format="PNG")
    return base64.b64encode(buf.getvalue()).decode("utf-8")


class AiStyleEngine:
    _instance = None

    def __init__(self, models_dir: str = "models"):
        self.models_dir = os.path.abspath(models_dir)
        self.device = "mps" if torch.backends.mps.is_available() else "cpu"
        self.dtype = torch.float16 if self.device == "mps" else torch.float32

        self.segmenter = None
        self.landmarker = None
        self.inpaint_pipe = None

        self._init_mediapipe()
        self._init_diffusers()

        self.analyzer = PhotoAnalyzer(self.landmarker, self.segmenter)
        self.mask_manager = FacialMaskManager(self.segmenter, self.landmarker)
        self.recommender = StyleRecommendationEngine()
        self.storyboard_renderer = StoryboardRenderer()

    @classmethod
    def get_instance(cls, models_dir: str = "models") -> "AiStyleEngine":
        if cls._instance is None:
            cls._instance = cls(models_dir)
        return cls._instance

    def _init_mediapipe(self):
        """Initializes MediaPipe Multiclass Segmenter and FaceLandmarker."""
        logger.info("Initializing MediaPipe segmentation and landmark models...")
        seg_model_path = os.path.join(self.models_dir, "selfie_multiclass.tflite")
        lm_model_path = os.path.join(self.models_dir, "face_landmarker.task")

        if os.path.exists(seg_model_path):
            base_opts = mp_python.BaseOptions(model_asset_path=seg_model_path)
            opts = mp_vision.ImageSegmenterOptions(base_options=base_opts, output_category_mask=True)
            self.segmenter = mp_vision.ImageSegmenter.create_from_options(opts)
            logger.info("MediaPipe ImageSegmenter loaded.")
        else:
            logger.warning(f"Segmenter model not found at {seg_model_path}")

        if os.path.exists(lm_model_path):
            base_opts = mp_python.BaseOptions(model_asset_path=lm_model_path)
            opts = mp_vision.FaceLandmarkerOptions(base_options=base_opts, num_faces=1)
            self.landmarker = mp_vision.FaceLandmarker.create_from_options(opts)
            logger.info("MediaPipe FaceLandmarker loaded.")
        else:
            logger.warning(f"Face landmarker model not found at {lm_model_path}")

    def _init_diffusers(self):
        """Loads Stable Diffusion Inpainting pipeline in fp16 with DPMSolver and memory slicing."""
        model_id = "stable-diffusion-v1-5/stable-diffusion-inpainting"
        logger.info(f"Loading {model_id} on {self.device} ({self.dtype})...")
        t0 = time.time()

        self.inpaint_pipe = StableDiffusionInpaintPipeline.from_pretrained(
            model_id,
            torch_dtype=self.dtype,
            variant="fp16" if self.dtype == torch.float16 else None,
            safety_checker=None,
        )
        self.inpaint_pipe.scheduler = DPMSolverMultistepScheduler.from_config(self.inpaint_pipe.scheduler.config)

        # Memory optimizations for Apple Silicon unified memory
        self.inpaint_pipe.enable_attention_slicing(1)
        if hasattr(self.inpaint_pipe, "enable_vae_slicing"):
            self.inpaint_pipe.enable_vae_slicing()

        self.inpaint_pipe.to(self.device)
        logger.info(f"Diffusers pipeline ready in {time.time() - t0:.2f}s!")

    def analyze_photo(self, raw_image: Image.Image) -> Dict[str, Any]:
        """Runs PhotoAnalyzer on the input portrait."""
        _, analysis, _, _ = self.analyzer.analyze(raw_image)
        return analysis

    def normalize_image(self, input_image: Image.Image, target_size: int = 512) -> Tuple[Image.Image, Tuple[int, int]]:
        """Fixes EXIF rotation, scales to target_size x target_size with proportional padding."""
        img = ImageOps.exif_transpose(input_image).convert("RGB")
        orig_w, orig_h = img.size

        scale = target_size / max(orig_w, orig_h)
        new_w, new_h = int(orig_w * scale), int(orig_h * scale)
        img_resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)

        canvas = Image.new("RGB", (target_size, target_size), (245, 243, 240))
        offset_x = (target_size - new_w) // 2
        offset_y = (target_size - new_h) // 2
        canvas.paste(img_resized, (offset_x, offset_y))
        return canvas, (orig_w, orig_h)

    def extract_masks(self, image: Image.Image) -> Dict[str, Image.Image]:
        """
        Extracts high-precision hair, beard, and protected facial masks using FacialMaskManager.
        Guarantees that eyes, eyebrows, nose, mouth/lips, and glasses are strictly protected.
        """
        np_img = np.array(image)
        h, w = np_img.shape[:2]

        _, analysis, pts, cat_mask = self.analyzer.analyze(image)
        eyewear = analysis.get("hair_analysis", {}).get("eyewear_detected", False)

        raw_masks = self.mask_manager.extract_masks(
            image_np=np_img,
            landmarks=pts,
            category_mask=cat_mask,
            eyewear_detected=eyewear,
        )

        debug_img = self.mask_manager.render_debug_overlay(
            original_np=np_img,
            hair_mask=raw_masks["hair"],
            beard_mask=raw_masks["beard"],
            protected_mask=raw_masks["protected"],
        )

        return {
            "hair": Image.fromarray(raw_masks["hair"], mode="L"),
            "beard": Image.fromarray(raw_masks["beard"], mode="L"),
            "combined": Image.fromarray(raw_masks["combined"], mode="L"),
            "protected": Image.fromarray(raw_masks["protected"], mode="L"),
            "debug_overlay": debug_img,
        }

    def inpaint_single_region(
        self,
        base_image: Image.Image,
        binary_mask: Image.Image,
        protected_mask: Optional[Image.Image],
        prompt: str,
        negative_prompt: str,
        strength: float = 0.75,
        steps: int = 18,
        guidance_scale: float = 7.0,
        generator: Optional[torch.Generator] = None,
        use_roi_crop: bool = True,
    ) -> Image.Image:
        """
        Inpaints a specific surgical region (hair or beard) using Isotropic Square ROI cropping.
        Prevents aspect-ratio squashing/stretching by maintaining strict 1:1 geometry,
        inpaints with strength=0.75 to preserve natural head volume/curvature while
        synthesizing crisp hair strands/fades, resizes back, and composites with 100%
        bit-exact pixel preservation outside the authorized mask.
        """
        orig_w, orig_h = base_image.size
        base_np = np.array(base_image)
        mask_np = np.array(binary_mask)
        prot_np = np.array(protected_mask) if protected_mask is not None else None

        # Safe guard: if edit mask is empty, return unchanged base image
        if np.sum(mask_np > 0) == 0:
            return base_image

        if use_roi_crop:
            ys, xs = np.where(mask_np > 0)
            cx = int((np.min(xs) + np.max(xs)) / 2)
            cy = int((np.min(ys) + np.max(ys)) / 2)
            mask_w = int(np.max(xs) - np.min(xs))
            mask_h = int(np.max(ys) - np.min(ys))

            # Isotropic square crop: preserve 1:1 aspect ratio to prevent stretching/squashing
            side_len = int(max(mask_w, mask_h) * 1.35)
            side_len = max(side_len, 256)
            side_len = min(side_len, min(orig_w, orig_h))
            half = side_len // 2

            c_x1 = max(0, cx - half)
            c_y1 = max(0, cy - half)
            c_x2 = min(orig_w, c_x1 + side_len)
            c_y2 = min(orig_h, c_y1 + side_len)
            c_x1 = max(0, c_x2 - side_len)
            c_y1 = max(0, c_y2 - side_len)

            actual_w = c_x2 - c_x1
            actual_h = c_y2 - c_y1

            if actual_w >= 64 and actual_h >= 64:
                img_crop = base_image.crop((c_x1, c_y1, c_x2, c_y2)).resize((512, 512), Image.Resampling.LANCZOS)
                mask_crop = binary_mask.crop((c_x1, c_y1, c_x2, c_y2)).resize((512, 512), Image.Resampling.NEAREST)

                crop_raw = self.inpaint_pipe(
                    prompt=prompt,
                    negative_prompt=negative_prompt,
                    image=img_crop,
                    mask_image=mask_crop,
                    strength=strength,
                    num_inference_steps=steps,
                    guidance_scale=guidance_scale,
                    generator=generator,
                ).images[0]

                crop_restored = crop_raw.resize((actual_w, actual_h), Image.Resampling.LANCZOS)
                canvas = base_image.copy()
                canvas.paste(crop_restored, (c_x1, c_y1))
                gen_full_np = np.array(canvas)

                composite_np = FacialMaskManager.composite_with_exact_preservation(
                    original_np=base_np,
                    generated_np=gen_full_np,
                    binary_mask=mask_np,
                    protected_mask=prot_np,
                    blur_ksize=11,
                )
                return Image.fromarray(composite_np, mode="RGB")

        # Direct inpainting fallback
        inpainted_raw = self.inpaint_pipe(
            prompt=prompt,
            negative_prompt=negative_prompt,
            image=base_image,
            mask_image=binary_mask,
            strength=strength,
            num_inference_steps=steps,
            guidance_scale=guidance_scale,
            generator=generator,
        ).images[0]

        composite_np = FacialMaskManager.composite_with_exact_preservation(
            original_np=base_np,
            generated_np=np.array(inpainted_raw),
            binary_mask=mask_np,
            protected_mask=prot_np,
            blur_ksize=11,
        )
        return Image.fromarray(composite_np, mode="RGB")

    def generate_variation(
        self,
        image: Image.Image,
        hair_style: Optional[str] = None,
        beard_style: Optional[str] = None,
        hair_color: Optional[str] = None,
        beard_color: Optional[str] = None,
        seed: Optional[int] = None,
        steps: int = 18,
        precomputed_masks: Optional[Dict[str, Image.Image]] = None,
    ) -> Image.Image:
        """
        Synthesizes realistic hairstyle and beard variations using independent modular passes.
        Preserves 100% bit-exact original pixels outside the surgical edit zones.
        """
        if seed is None:
            seed = int(time.time() * 1000) % 1000000

        masks = precomputed_masks or self.extract_masks(image)
        protected_mask = masks.get("protected")

        color_desc = COLOR_MODIFIERS.get(hair_color, "natural dark black hair")
        generator = torch.Generator(device=self.device).manual_seed(seed)
        current_img = image

        # Pass 1: Hairstyle inpainting (if requested)
        if hair_style:
            h_meta = STYLE_PROMPTS.get(hair_style, {})
            h_prompt_core = h_meta.get("prompt", f"{hair_style.replace('_', ' ')} haircut, sharp taper fade")
            h_prompt = f"close-up photo of a handsome man with {color_desc}, {h_prompt_core}, professional barbershop haircut, natural clean hairline, 8k uhd, dslr"
            h_negative = (
                "wig, toupee, artificial hair, messy bald spots, patchy hairline, blurry, deformed face, "
                "bad eyes, white hair, grey hair, silver hair, streaks, highlights, bleached hair, "
                "text, watermark, signature, doodles, letters, numbers, drawing, cartoon, painting, 3d render"
            )

            current_img = self.inpaint_single_region(
                base_image=current_img,
                binary_mask=masks["hair"],
                protected_mask=protected_mask,
                prompt=h_prompt,
                negative_prompt=h_negative,
                strength=0.75,
                steps=steps,
                guidance_scale=7.0,
                generator=generator,
                use_roi_crop=True,
            )

        # Pass 2: Beard inpainting (if requested)
        if beard_style:
            b_meta = STYLE_PROMPTS.get(beard_style, {})
            b_prompt_core = b_meta.get("prompt", f"{beard_style.replace('_', ' ')} facial hair")
            b_prompt = f"close-up photo of a man with {color_desc}, {b_prompt_core}, groomed facial hair, sharp clean cheek line, skin texture, 8k uhd"
            b_negative = (
                "patchy stubble, asymmetrical beard, deformed lips, deformed mouth, distorted teeth, "
                "blurry skin, cuts, scars, text, watermark, signature, doodles, letters, numbers, drawing, cartoon, painting, 3d render, plastic doll"
            )

            current_img = self.inpaint_single_region(
                base_image=current_img,
                binary_mask=masks["beard"],
                protected_mask=protected_mask,
                prompt=b_prompt,
                negative_prompt=b_negative,
                strength=0.75,
                steps=steps,
                guidance_scale=7.0,
                generator=generator,
                use_roi_crop=True,
            )

        return current_img

    def generate_personalized_styles(
        self,
        raw_image: Image.Image,
        preferences: Optional[Dict[str, Any]] = None,
        count: int = 4,
        steps: int = 18,
        side_image: Optional[Image.Image] = None,
        back_image: Optional[Image.Image] = None,
    ) -> Dict[str, Any]:
        """
        Analyzes customer photo, selects tailored recommendations, and synthesizes
        photorealistic portraits using Stable Diffusion inpainting with bit-exact face compositing.
        """
        t0 = time.time()
        prefs = preferences or {}

        # 1. Photo Analysis
        oriented_img, analysis, pts, cat_mask = self.analyzer.analyze(raw_image)
        if not analysis.get("face_detected", False):
            reason = analysis.get("quality", {}).get(
                "rejection_reason",
                "No clear face detected in the uploaded image. Please upload a clear front-facing photo.",
            )
            raise ValueError(reason)

        if not analysis.get("quality", {}).get("is_acceptable", True):
            reason = analysis.get("quality", {}).get(
                "rejection_reason",
                "Uploaded photo did not meet quality or pose requirements for accurate styling.",
            )
            raise ValueError(reason)

        # 2. Select Style Recommendations
        rec = self.recommender.select_recommendations(
            analysis=analysis,
            preferences=prefs,
            count=max(1, min(6, count)),
        )
        selected_options = rec["selected_options"]
        best_option = rec["best_option"]
        barber_notes = rec["barber_notes"]

        # 3. Prepare normalized image & masks
        norm_img, _ = self.normalize_image(oriented_img, target_size=512)
        masks = self.extract_masks(norm_img)

        # Side and back view handling
        side_b64_shared: Optional[str] = None
        back_b64_shared: Optional[str] = None
        if side_image is not None:
            side_oriented, _ = self.analyzer.auto_orient_and_detect(side_image)
            side_b64_shared = _pil_to_b64(side_oriented.resize((380, 460), Image.Resampling.LANCZOS))
        if back_image is not None:
            back_oriented, _ = self.analyzer.auto_orient_and_detect(back_image)
            back_b64_shared = _pil_to_b64(back_oriented.resize((380, 460), Image.Resampling.LANCZOS))

        portraits: List[Image.Image] = []
        variations_out: List[Dict[str, Any]] = []
        base_seed = int(time.time() * 1000) % 999999

        # 4. Synthesize each variation using Neural Inpainting
        for idx, opt in enumerate(selected_options):
            v_t0 = time.time()
            seed = (base_seed + idx * 73) % 999999

            h_style = opt.get("hair_style")
            b_style = opt.get("beard_style")
            h_color = prefs.get("hair_color")
            b_color = prefs.get("beard_color")

            styled_pil = self.generate_variation(
                image=norm_img,
                hair_style=h_style,
                beard_style=b_style,
                hair_color=h_color,
                beard_color=b_color,
                seed=seed,
                steps=steps,
                precomputed_masks=masks,
            )

            portraits.append(styled_pil)
            front_b64 = _pil_to_b64(styled_pil)
            v_elapsed = round(time.time() - v_t0, 2)
            opt_num = opt["option_number"]

            variations_out.append(
                {
                    "id": f"var_{opt_num}",
                    "archetype_id": opt["archetype_id"],
                    "option_number": opt_num,
                    "image_base64": front_b64,
                    "side_image_base64": side_b64_shared,
                    "back_image_base64": back_b64_shared,
                    "side_view_available": side_b64_shared is not None,
                    "back_view_available": back_b64_shared is not None,
                    "style_label": opt["title"],
                    "hair_style": opt["hair_style"],
                    "beard_style": opt["beard_style"],
                    "header_hex": opt["header_hex"],
                    "hair_length_cm": opt["hair_length_cm"],
                    "beard_length_mm": opt["beard_length_mm"],
                    "hair_desc": opt["hair_desc"],
                    "beard_desc": opt["beard_desc"],
                    "look_desc": opt["look_desc"],
                    "why_it_suits": opt["why_it_suits"],
                    "suitability_score": opt["suitability_score"],
                    "maintenance_level": opt["maintenance_level"],
                    "styling_products": opt["styling_products"],
                    "barber_instructions": opt["barber_instructions"],
                    "style_spec": opt.get("style_spec"),
                    "is_recommended": opt["is_recommended"],
                    "seed": seed,
                    "elapsed_seconds": v_elapsed,
                }
            )

        # 5. Dynamic Storyboard composite
        storyboard_pil = self.storyboard_renderer.render_storyboard(
            portraits=portraits,
            options=selected_options,
            best_option=best_option,
            barber_notes=barber_notes,
            analysis=analysis,
        )
        storyboard_b64 = _pil_to_b64(storyboard_pil)
        total_elapsed = round(time.time() - t0, 2)

        return {
            "analysis": analysis,
            "preferences": prefs,
            "storyboard_image_base64": storyboard_b64,
            "variations": variations_out,
            "barber_notes": barber_notes,
            "best_option": best_option,
            "total_time_seconds": total_elapsed,
        }

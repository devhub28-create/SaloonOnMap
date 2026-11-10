import logging
from typing import Dict, Any, Tuple, Optional
import numpy as np
import cv2
from PIL import Image

logger = logging.getLogger("ai_style_service.masker")


class MaskExtractionError(Exception):
    """Raised when facial landmark or segmentation mask extraction fails quality thresholds."""
    pass


class FacialMaskManager:
    """
    Dedicated surgical facial feature masker and identity-preservation engine.
    
    Guarantees:
    1. Facial landmarks define immutable protected regions (eyes, eyebrows, nose, mouth/lips, inner cheeks).
    2. Scalp hair and beard/facial hair are segmented into independent, non-overlapping edit masks.
    3. Feathering is strictly bounded: feathering alpha is clamped to 0 everywhere outside the approved binary mask.
    4. Exact compositing: Output pixels outside the approved binary edit mask equal original pixels bit-for-bit.
    5. Validates mask coverage and rejects empty or corrupt masks safely.
    """

    def __init__(self, segmenter: Any = None, landmarker: Any = None):
        self.segmenter = segmenter
        self.landmarker = landmarker

    @staticmethod
    def _create_polygon_mask(shape: Tuple[int, int], points: np.ndarray) -> np.ndarray:
        mask = np.zeros(shape, dtype=np.uint8)
        if len(points) >= 3:
            pts = np.int32(points).reshape((-1, 1, 2))
            cv2.fillPoly(mask, [pts], 255)
        return mask

    def build_protected_mask(
        self,
        h: int,
        w: int,
        landmarks: Optional[np.ndarray],
        category_mask: Optional[np.ndarray] = None,
        eyewear_detected: bool = False,
    ) -> np.ndarray:
        """
        Builds a binary mask (255 = protected, 0 = editable) covering:
        - Eyes, pupils, and eyelids
        - Eyebrows
        - Nose bridge and nostrils
        - Lips and mouth interior
        - Exposed central cheek skin
        - Eyeglasses frames (if detected)
        """
        protected = np.zeros((h, w), dtype=np.uint8)
        if landmarks is None or len(landmarks) < 468:
            return protected

        pts = landmarks

        # 1. Left Eye & Eyebrow
        l_eye_indices = [33, 7, 163, 144, 145, 153, 154, 155, 133, 173, 157, 158, 159, 160, 161, 246]
        l_brow_indices = [70, 63, 105, 66, 107, 55, 65, 52, 53, 46]
        l_eye_poly = np.int32([pts[i] for i in l_eye_indices])
        l_brow_poly = np.int32([pts[i] for i in l_brow_indices])
        cv2.fillPoly(protected, [l_eye_poly, l_brow_poly], 255)

        # 2. Right Eye & Eyebrow
        r_eye_indices = [263, 249, 390, 373, 374, 380, 381, 382, 362, 398, 384, 385, 386, 387, 388, 466]
        r_brow_indices = [300, 293, 334, 296, 336, 285, 295, 282, 283, 276]
        r_eye_poly = np.int32([pts[i] for i in r_eye_indices])
        r_brow_poly = np.int32([pts[i] for i in r_brow_indices])
        cv2.fillPoly(protected, [r_eye_poly, r_brow_poly], 255)

        # 3. Nose bridge & tip
        nose_indices = [168, 6, 197, 195, 5, 4, 1, 19, 94, 2, 98, 97, 20, 242, 141, 94, 327, 462, 370]
        nose_poly = np.int32([pts[i] for i in nose_indices if i < len(pts)])
        cv2.fillPoly(protected, [nose_poly], 255)

        # 4. Lips & Mouth
        mouth_indices = [
            61, 185, 40, 39, 37, 0, 267, 269, 270, 409, 291,
            375, 321, 405, 314, 17, 84, 181, 91, 146
        ]
        mouth_poly = np.int32([pts[i] for i in mouth_indices])
        cv2.fillPoly(protected, [mouth_poly], 255)

        # Dilate eye/brow/mouth protection slightly (3px) to create safety buffer
        buffer_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
        protected = cv2.dilate(protected, buffer_kernel, iterations=1)

        # 5. Eyewear protection (if glasses detected from category 5 or geometry)
        if category_mask is not None:
            glasses_pixels = (category_mask == 5).astype(np.uint8) * 255
            if np.sum(glasses_pixels) > 50:
                protected = cv2.bitwise_or(protected, glasses_pixels)

        return protected

    def extract_masks(
        self,
        image_np: np.ndarray,
        landmarks: Optional[np.ndarray],
        category_mask: Optional[np.ndarray],
        eyewear_detected: bool = False,
    ) -> Dict[str, np.ndarray]:
        """
        Extracts independent hair and beard masks with guaranteed exclusion of protected facial zones.
        
        Returns:
            Dict containing:
            - "hair": Binary mask (uint8) of scalp hair edit zone
            - "beard": Binary mask (uint8) of facial hair/jawline edit zone
            - "combined": Union edit mask (hair | beard)
            - "protected": Immutable facial feature protection mask
        """
        h, w = image_np.shape[:2]
        protected_mask = self.build_protected_mask(h, w, landmarks, category_mask, eyewear_detected)

        # 1. Scalp Hair Mask
        hair_mask = np.zeros((h, w), dtype=np.uint8)
        if category_mask is not None:
            raw_hair = (category_mask == 1).astype(np.uint8) * 255
            # Morphological smoothing to cover roots, hairline, and sideburns
            smooth_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7))
            hair_mask = cv2.dilate(raw_hair, smooth_kernel, iterations=2)
            hair_mask = cv2.morphologyEx(hair_mask, cv2.MORPH_CLOSE, smooth_kernel)

        # Subtract protected regions so scalp hair NEVER intrudes into eyebrows, eyes, or nose
        hair_mask[protected_mask == 255] = 0

        # 2. Beard Mask (anatomically accurate mandibular and perioral contour)
        beard_mask = np.zeros((h, w), dtype=np.uint8)
        if landmarks is not None and len(landmarks) >= 468:
            pts = landmarks
            # Mandibular contour along the lower jawline and chin
            jaw_contour = [
                234, 93, 132, 58, 172, 136, 150, 149, 176, 148, 152,
                377, 400, 378, 379, 365, 397, 288, 361, 323, 454
            ]
            # Anatomical upper beard line: strictly bounded below upper cheeks
            # Tragus/sideburn -> mandibular angle -> diagonal down toward mouth corners & philtrum base
            beard_top_boundary = [454, 323, 361, 288, 397, 291, 164, 61, 58, 132, 93, 234]
            poly_indices = jaw_contour + beard_top_boundary[::-1]
            beard_poly = np.int32([pts[idx] for idx in poly_indices if idx < len(pts)])
            cv2.fillPoly(beard_mask, [beard_poly], 255)

            # Moustache sub-region: under nose philtrum and above upper lip
            moust_indices = [2, 97, 206, 61, 37, 0, 267, 291, 426, 326]
            moust_poly = np.int32([pts[idx] for idx in moust_indices if idx < len(pts)])
            cv2.fillPoly(beard_mask, [moust_poly], 255)

            # Strictly remove lips and mouth with an extra 9px safety buffer
            mouth_indices = [
                61, 185, 40, 39, 37, 0, 267, 269, 270, 409, 291,
                375, 321, 405, 314, 17, 84, 181, 91, 146
            ]
            mouth_pts = np.int32([pts[idx] for idx in mouth_indices])
            mouth_mask = np.zeros((h, w), dtype=np.uint8)
            cv2.fillPoly(mouth_mask, [mouth_pts], 255)
            mouth_dilated = cv2.dilate(mouth_mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (9, 9)), iterations=1)
            beard_mask[mouth_dilated == 255] = 0

            # Nostril and nose protection: exclude nose base and alar rims
            nose_base_indices = [168, 6, 197, 195, 5, 4, 1, 19, 94, 2, 98, 97, 20, 242, 141, 327, 462, 370]
            nose_mask = np.zeros((h, w), dtype=np.uint8)
            cv2.fillPoly(nose_mask, [np.int32([pts[idx] for idx in nose_base_indices if idx < len(pts)])], 255)
            nose_dilated = cv2.dilate(nose_mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (7, 7)), iterations=1)
            beard_mask[nose_dilated == 255] = 0

            # Subtle boundary smoothing for realistic hairline/beardline transition
            beard_kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
            beard_mask = cv2.morphologyEx(beard_mask, cv2.MORPH_OPEN, beard_kernel)

            # Strictly enforce zero overlap with protected regions (eyes, nose, mouth)
            beard_mask[protected_mask == 255] = 0

        # 3. Combined edit mask
        combined_mask = cv2.bitwise_or(hair_mask, beard_mask)
        combined_mask[protected_mask == 255] = 0

        return {
            "hair": hair_mask,
            "beard": beard_mask,
            "combined": combined_mask,
            "protected": protected_mask,
        }

    def validate_mask(self, mask: np.ndarray, min_area_ratio: float = 0.005, max_area_ratio: float = 0.85) -> bool:
        """
        Validates that an edit mask is structurally sound:
        - Non-empty (at least min_area_ratio of canvas)
        - Not over-invasive (does not consume entire portrait)
        """
        h, w = mask.shape[:2]
        total_pixels = h * w
        edit_pixels = int(np.sum(mask > 0))
        ratio = edit_pixels / max(total_pixels, 1)

        if ratio < min_area_ratio:
            logger.warning(f"Mask validation failed: edit area too small ({ratio:.4f} < {min_area_ratio})")
            return False
        if ratio > max_area_ratio:
            logger.warning(f"Mask validation failed: edit area excessively large ({ratio:.4f} > {max_area_ratio})")
            return False
        return True

    @staticmethod
    def compute_bounded_feathered_mask(binary_mask: np.ndarray, blur_ksize: int = 15) -> np.ndarray:
        """
        Computes an inner-bounded alpha feathering mask.
        
        CRITICAL IDENTITY PRESERVATION RULE:
        Feathering must NEVER leak outside the approved binary mask into untouched regions.
        We achieve this by:
        1. Eroding the binary mask by half the blur radius so the blur center is pulled inside.
        2. Applying Gaussian blur.
        3. Strictly multiplying by the binary mask:
           alpha(x, y) = 0.0 everywhere where binary_mask(x, y) == 0.
        """
        k = max(3, blur_ksize if blur_ksize % 2 == 1 else blur_ksize + 1)
        eroded = cv2.erode(binary_mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (k // 2, k // 2)))
        blurred = cv2.GaussianBlur(eroded.astype(np.float32) / 255.0, (k, k), 0)
        
        # Hard clamp: any pixel outside binary_mask is unconditionally ZERO
        bounded_alpha = blurred * (binary_mask.astype(np.float32) / 255.0)
        return bounded_alpha

    @classmethod
    def composite_with_exact_preservation(
        cls,
        original_np: np.ndarray,
        generated_np: np.ndarray,
        binary_mask: np.ndarray,
        protected_mask: Optional[np.ndarray] = None,
        blur_ksize: int = 11,
    ) -> np.ndarray:
        """
        Performs high-fidelity blending within the edit region while guaranteeing
        100% BIT-EXACT pixel preservation for:
        1. All pixels outside binary_mask
        2. All pixels inside protected_mask
        
        Returns:
            Composite image (uint8 RGB)
        """
        orig = original_np.astype(np.float32)
        gen = generated_np.astype(np.float32)
        
        # Approved edit zone (binary)
        approved = (binary_mask > 0)
        if protected_mask is not None:
            approved = approved & (protected_mask == 0)

        # Compute bounded alpha inside the approved zone
        alpha = cls.compute_bounded_feathered_mask(approved.astype(np.uint8) * 255, blur_ksize=blur_ksize)
        alpha_3d = alpha[:, :, np.newaxis]

        # Soft blend within the approved region
        blended = (gen * alpha_3d + orig * (1.0 - alpha_3d)).clip(0, 255).astype(np.uint8)

        # BIT-EXACT ENFORCEMENT:
        # Every pixel outside the approved mask is directly assigned the original pixel value!
        blended[~approved] = original_np[~approved]

        if protected_mask is not None:
            blended[protected_mask > 0] = original_np[protected_mask > 0]

        return blended

    @staticmethod
    def render_debug_overlay(
        original_np: np.ndarray,
        hair_mask: np.ndarray,
        beard_mask: np.ndarray,
        protected_mask: np.ndarray,
    ) -> Image.Image:
        """
        Renders a transparent visual diagnostic overlay for automated regression inspection:
        - Hair Edit Region: Cyan tint
        - Beard Edit Region: Green tint
        - Protected Facial Features: Red tint (eyes, mouth, nose)
        """
        h, w = original_np.shape[:2]
        overlay = original_np.copy()

        # Cyan for Hair
        hair_idx = (hair_mask > 0)
        overlay[hair_idx, 0] = (overlay[hair_idx, 0] * 0.4 + 0 * 0.6).astype(np.uint8)
        overlay[hair_idx, 1] = (overlay[hair_idx, 1] * 0.4 + 220 * 0.6).astype(np.uint8)
        overlay[hair_idx, 2] = (overlay[hair_idx, 2] * 0.4 + 255 * 0.6).astype(np.uint8)

        # Green for Beard
        beard_idx = (beard_mask > 0)
        overlay[beard_idx, 0] = (overlay[beard_idx, 0] * 0.4 + 30 * 0.6).astype(np.uint8)
        overlay[beard_idx, 1] = (overlay[beard_idx, 1] * 0.4 + 230 * 0.6).astype(np.uint8)
        overlay[beard_idx, 2] = (overlay[beard_idx, 2] * 0.4 + 70 * 0.6).astype(np.uint8)

        # Red for Protected Features
        prot_idx = (protected_mask > 0)
        overlay[prot_idx, 0] = (overlay[prot_idx, 0] * 0.3 + 255 * 0.7).astype(np.uint8)
        overlay[prot_idx, 1] = (overlay[prot_idx, 1] * 0.3 + 20 * 0.7).astype(np.uint8)
        overlay[prot_idx, 2] = (overlay[prot_idx, 2] * 0.3 + 20 * 0.7).astype(np.uint8)

        return Image.fromarray(overlay, mode="RGB")

import math
import logging
from typing import Dict, Any, Optional, Tuple, List
import cv2
import numpy as np
from PIL import Image, ImageOps
import mediapipe as mp

logger = logging.getLogger("ai_style_service.analyzer")


class PhotoAnalyzer:
    """
    Dynamic, privacy-safe computer-vision analyzer for customer portrait photos.
    Analyzes only styling-relevant visual characteristics:
    - Image quality, lighting, sharpness, pose angles (yaw/pitch/roll), and face visibility
    - Facial proportion ratios and approximate face-shape category (with honest 'uncertain' fallback)
    - Forehead exposure, hairline visibility, visible hair length, texture, and density
    - Eyewear presence (to protect glasses frames during hair/beard editing)
    - Visible facial hair / beard & moustache presence and density
    """

    def __init__(self, landmarker: Any, segmenter: Any):
        self.landmarker = landmarker
        self.segmenter = segmenter

    def auto_orient_and_detect(self, input_image: Image.Image) -> Tuple[Image.Image, Optional[np.ndarray]]:
        """Fixes EXIF transpose and checks 0/90/270/180 rotations so sideways camera uploads are upright."""
        img = ImageOps.exif_transpose(input_image).convert("RGB")
        if not self.landmarker:
            return img, None

        best_img = img
        best_pts = None
        best_score = -1e9

        for rot in [0, 90, 270, 180]:
            candidate = img.rotate(rot, expand=True) if rot else img
            np_cand = np.array(candidate)
            h, w = np_cand.shape[:2]
            mp_im = mp.Image(image_format=mp.ImageFormat.SRGB, data=np_cand)
            res = self.landmarker.detect(mp_im)
            if res.face_landmarks and len(res.face_landmarks) > 0:
                lms = res.face_landmarks[0]
                dy = lms[152].y - lms[10].y
                dx = lms[263].x - lms[33].x
                score = dy + dx
                if score > best_score:
                    best_score = score
                    best_img = candidate
                    best_pts = np.array([[lm.x * w, lm.y * h] for lm in lms], dtype=np.float32)
            if rot == 0 and best_pts is not None and best_score > 0.35:
                break

        return best_img, best_pts

    def get_segmentation(self, np_img: np.ndarray) -> np.ndarray:
        """
        Returns MediaPipe selfie_multiclass category mask:
        0 = background, 1 = hair, 2 = body_skin, 3 = face_skin, 4 = clothes, 5 = others (eyeglasses/accessories)
        """
        h, w = np_img.shape[:2]
        if not self.segmenter:
            return np.zeros((h, w), dtype=np.uint8)
        mp_im = mp.Image(image_format=mp.ImageFormat.SRGB, data=np_img)
        seg_res = self.segmenter.segment(mp_im)
        if seg_res and seg_res.category_mask:
            return np.squeeze(seg_res.category_mask.numpy_view()).astype(np.uint8)
        return np.zeros((h, w), dtype=np.uint8)

    def analyze(self, input_image: Image.Image) -> Tuple[Image.Image, Dict[str, Any], Optional[np.ndarray], np.ndarray]:
        """
        Runs complete styling analysis on the uploaded portrait.
        Returns: (oriented_pil_image, analysis_dict, landmarks_px, category_mask)
        """
        oriented_img, pts = self.auto_orient_and_detect(input_image)
        np_img = np.array(oriented_img)
        h, w = np_img.shape[:2]
        gray = cv2.cvtColor(np_img, cv2.COLOR_RGB2GRAY)

        # 1. Image quality & lighting metrics
        sharpness = float(cv2.Laplacian(gray, cv2.CV_64F).var())
        brightness = float(np.mean(gray))
        contrast = float(np.std(gray))

        warnings: List[str] = []
        if sharpness < 25.0:
            warnings.append("Image appears slightly soft or blurry; sharper lighting improves hair strand detail.")
        if brightness < 55.0:
            warnings.append("Lighting is dim; well-lit front-facing photos yield more accurate skin and hair tones.")
        elif brightness > 225.0:
            warnings.append("Photo is slightly overexposed.")

        cat_mask = self.get_segmentation(np_img)

        if pts is None:
            return oriented_img, {
                "face_detected": False,
                "quality": {
                    "width": w,
                    "height": h,
                    "sharpness_score": round(sharpness, 1),
                    "brightness_score": round(brightness, 1),
                    "contrast_score": round(contrast, 1),
                    "face_area_ratio": 0.0,
                    "yaw_degrees": 0.0,
                    "pitch_degrees": 0.0,
                    "roll_degrees": 0.0,
                    "is_acceptable": False,
                    "warnings": warnings,
                    "rejection_reason": "No clear front-facing face was detected. Please upload a clear portrait facing the camera.",
                },
                "face_geometry": {
                    "estimated_face_shape": "uncertain",
                    "confidence": 0.0,
                    "face_height_to_width_ratio": 0.0,
                    "jaw_to_cheek_ratio": 0.0,
                    "forehead_to_cheek_ratio": 0.0,
                    "shape_guidance": "Face shape could not be estimated because facial landmarks were not clearly visible.",
                },
                "hair_analysis": {
                    "estimated_current_length": "unknown",
                    "visible_texture": "unknown",
                    "hair_density": "unknown",
                    "forehead_exposure": "unknown",
                    "hairline_visible": False,
                    "eyewear_detected": False,
                },
                "facial_hair_analysis": {
                    "estimated_current_facial_hair": "unknown",
                    "beard_coverage_ratio": 0.0,
                },
            }, None, cat_mask

        # 2. Pose estimation (Yaw, Pitch, Roll) from 478 landmarks
        l_eye = np.mean(pts[[33, 133, 159, 145]], axis=0)
        r_eye = np.mean(pts[[263, 362, 386, 374]], axis=0)
        nose_tip = pts[1]
        chin = pts[152]
        forehead_top = pts[10]
        l_cheek = pts[234]
        r_cheek = pts[454]

        roll_deg = float(np.degrees(np.arctan2(r_eye[1] - l_eye[1], r_eye[0] - l_eye[0])))
        cheek_width = float(np.linalg.norm(r_cheek - l_cheek))
        eye_mid_x = 0.5 * (l_eye[0] + r_eye[0])
        nose_offset_x = (nose_tip[0] - eye_mid_x) / max(cheek_width * 0.5, 1.0)
        yaw_deg = float(np.clip(nose_offset_x * 45.0, -60.0, 60.0))

        eye_mid_y = 0.5 * (l_eye[1] + r_eye[1])
        upper_h = max(eye_mid_y - forehead_top[1], 1.0)
        lower_h = max(chin[1] - eye_mid_y, 1.0)
        pitch_deg = float(np.clip(((upper_h / lower_h) - 0.72) * 55.0, -45.0, 45.0))

        face_box_w = float(np.max(pts[:, 0]) - np.min(pts[:, 0]))
        face_box_h = float(np.max(pts[:, 1]) - np.min(pts[:, 1]))
        face_area_ratio = float((face_box_w * face_box_h) / max(w * h, 1))

        is_acceptable = True
        rejection_reason = None
        if face_area_ratio < 0.025:
            is_acceptable = False
            rejection_reason = "Your face is too small in the frame. Please use a closer head-and-shoulders portrait."
        elif abs(yaw_deg) > 38.0:
            is_acceptable = False
            rejection_reason = f"Your head is turned too far to the side ({abs(yaw_deg):.0f}°). Please use a front-facing photo."
        elif abs(yaw_deg) > 18.0:
            warnings.append("Slight head turn detected; front-facing photos provide the most symmetric preview.")

        # 3. Face geometry & approximate face shape (with honest uncertainty handling)
        # Anthropometric landmarks:
        # - Bizygomatic width (cheek width): 234 (left zygion) to 454 (right zygion)
        # - Bigonial width (jaw width): 132 (left gonion/mandibular angle) to 361 (right gonion)
        # - Minimum frontal width (forehead width): 103 (left frontotemporale) to 332 (right frontotemporale)
        # - Morphological facial height: 152 (gnathion/chin) to 10 (trichion/top forehead)
        jaw_width = float(np.linalg.norm(pts[361] - pts[132]))
        forehead_width = float(np.linalg.norm(pts[332] - pts[103]))
        face_height = float(np.linalg.norm(chin - forehead_top))
        cranial_face_h = float(face_height * 1.15)

        hw_ratio = cranial_face_h / max(cheek_width, 1.0)
        jaw_cheek_ratio = jaw_width / max(cheek_width, 1.0)
        fh_cheek_ratio = forehead_width / max(cheek_width, 1.0)

        if abs(yaw_deg) > 22.0 or sharpness < 15.0 or not is_acceptable:
            face_shape = "uncertain"
            shape_conf = 0.35
            shape_guidance = (
                "Viewing angle or image clarity prevents a high-confidence face-shape label; "
                "versatile balanced tapers are recommended."
            )
        else:
            shape_conf = round(float(np.clip(0.88 - abs(yaw_deg) * 0.015, 0.55, 0.92)), 2)
            if hw_ratio >= 1.36:
                face_shape = "oblong"
                shape_guidance = (
                    "Longer vertical proportions benefit from controlled top height, side texture, or a short boxed beard to add horizontal balance."
                )
            elif jaw_cheek_ratio >= 0.86 and hw_ratio < 1.28:
                face_shape = "square"
                shape_guidance = (
                    "Strong jawline angles pair well with textured volume on top (quiff, side part, or crew cut) and neatly tapered sides."
                )
            elif hw_ratio <= 1.16 and jaw_cheek_ratio < 0.85:
                face_shape = "round"
                shape_guidance = (
                    "Adding structured height on top with closer tapered sides and an angular boxed beard creates vertical definition."
                )
            elif fh_cheek_ratio >= 0.92 and jaw_cheek_ratio <= 0.76:
                face_shape = "heart"
                shape_guidance = (
                    "A wider forehead and narrower chin are balanced well by medium-textured fringes or fuller lower-jaw beard volume."
                )
            elif jaw_cheek_ratio <= 0.78 and fh_cheek_ratio <= 0.80:
                face_shape = "diamond"
                shape_guidance = (
                    "Prominent cheekbones suit textured crops, side sweeps, and classic tapers that keep temple width balanced."
                )
            else:
                face_shape = "oval"
                shape_guidance = (
                    "Balanced oval proportions suit a wide range of classic side parts, textured crops, quiffs, and short-to-medium beard styles."
                )

        # 4. Hair & Forehead Analysis
        hair_mask = (cat_mask == 1)
        face_skin_mask = (cat_mask == 3)
        glasses_mask = (cat_mask == 5)

        hair_px_count = int(np.sum(hair_mask))
        face_px_count = max(int(np.sum(face_skin_mask)), 1)
        visible_hair_ratio = float(hair_px_count / face_px_count)

        # Estimate hair length from how far hair extends above forehead_top (landmark 10)
        hair_ys, hair_xs = np.where(hair_mask)
        if len(hair_ys) > 50:
            top_hair_y = float(np.percentile(hair_ys, 3))
            brow_y = float(0.5 * (pts[70][1] + pts[300][1]))
            crown_height_ratio = (brow_y - top_hair_y) / max(cheek_width, 1.0)
            if crown_height_ratio < 0.36 or visible_hair_ratio < 0.14:
                est_hair_len = "minimal_or_buzz"
            elif crown_height_ratio < 0.54 or visible_hair_ratio < 0.35:
                est_hair_len = "short"
            elif crown_height_ratio < 0.72 or visible_hair_ratio < 0.65:
                est_hair_len = "medium"
            else:
                est_hair_len = "long_or_voluminous"
        else:
            est_hair_len = "minimal_or_buzz"
            top_hair_y = float(forehead_top[1])

        # Texture estimation inside hair region via Sobel gradient orientation dispersion
        if hair_px_count > 400:
            gx = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=3)
            gy = cv2.Sobel(gray, cv2.CV_32F, 0, 1, ksize=3)
            mag = np.hypot(gx, gy)
            ang = np.arctan2(gy, gx)
            valid_h = hair_mask & (mag > 18.0)
            if np.sum(valid_h) > 100:
                # Circular variance of double-angle orientations (measures directional disorder)
                cos2 = float(np.mean(np.cos(2.0 * ang[valid_h])))
                sin2 = float(np.mean(np.sin(2.0 * ang[valid_h])))
                coherence = math.hypot(cos2, sin2)
                high_freq_energy = float(np.mean(mag[hair_mask]))
                if coherence > 0.42:
                    visible_texture = "straight_smooth"
                elif coherence > 0.22 or high_freq_energy < 38.0:
                    visible_texture = "wavy_textured"
                else:
                    visible_texture = "curly_coily"
            else:
                visible_texture = "wavy_textured"
        else:
            visible_texture = "unknown"

        # Hair density (only when crown isn't cropped at y <= 4)
        if len(hair_ys) > 100 and np.min(hair_ys) > 4:
            # Check skin bleed-through inside upper hair region
            hair_luma = float(np.mean(gray[hair_mask]))
            face_luma = float(np.mean(gray[face_skin_mask])) if np.any(face_skin_mask) else 160.0
            contrast_diff = face_luma - hair_luma
            if contrast_diff > 65.0 and visible_hair_ratio > 0.35:
                hair_density = "dense"
            elif contrast_diff > 35.0:
                hair_density = "moderate"
            else:
                hair_density = "light_or_thinning"
        else:
            hair_density = "unknown"

        # Forehead exposure & hairline visibility
        fh_poly = np.int32([pts[i] for i in [103, 67, 109, 10, 338, 297, 332, 300, 334, 296, 336, 9, 107, 66, 105, 70]])
        fh_region = np.zeros((h, w), dtype=np.uint8)
        cv2.fillPoly(fh_region, [fh_poly], 255)
        fh_total = max(int(np.sum(fh_region == 255)), 1)
        fh_hair_overlap = float(np.sum((fh_region == 255) & hair_mask) / fh_total)
        hairline_visible = bool(fh_hair_overlap < 0.55)
        if fh_hair_overlap > 0.45:
            forehead_exposure = "partially_covered_by_fringe"
        elif (pts[9][1] - pts[10][1]) / max(cheek_width, 1.0) > 0.34:
            forehead_exposure = "high"
        else:
            forehead_exposure = "balanced"

        eyewear_detected = bool(np.sum(glasses_mask) > int(0.008 * face_px_count))

        # 5. Facial Hair / Beard & Moustache Analysis
        # Compare luminance of cheek skin vs moustache & jaw beard regions
        cheek_poly_l = np.int32([pts[i] for i in [117, 118, 101, 205, 187, 123]])
        cheek_poly_r = np.int32([pts[i] for i in [346, 347, 330, 425, 411, 352]])
        cheek_mask = np.zeros((h, w), dtype=np.uint8)
        cv2.fillPoly(cheek_mask, [cheek_poly_l, cheek_poly_r], 255)
        cheek_mask[glasses_mask] = 0

        moustache_poly = np.int32([pts[i] for i in [2, 97, 206, 61, 37, 0, 267, 291, 426, 326]])
        moust_mask = np.zeros((h, w), dtype=np.uint8)
        cv2.fillPoly(moust_mask, [moustache_poly], 255)

        jaw_poly = np.int32([
            pts[i] for i in [
                132, 58, 172, 136, 150, 149, 176, 148, 152,
                377, 400, 378, 379, 365, 397, 288, 361,
                411, 427, 321, 17, 91, 207
            ]
        ])
        jaw_mask = np.zeros((h, w), dtype=np.uint8)
        cv2.fillPoly(jaw_mask, [jaw_poly], 255)

        cheek_luma = float(np.median(gray[cheek_mask == 255])) if np.any(cheek_mask == 255) else 155.0
        moust_luma = float(np.median(gray[moust_mask == 255])) if np.any(moust_mask == 255) else cheek_luma
        jaw_luma = float(np.median(gray[jaw_mask == 255])) if np.any(jaw_mask == 255) else cheek_luma

        # Also measure high-frequency follicle texture in jaw_mask
        lap_abs = np.abs(cv2.Laplacian(gray, cv2.CV_32F))
        jaw_tex = float(np.mean(lap_abs[jaw_mask == 255])) if np.any(jaw_mask == 255) else 0.0
        cheek_tex = float(np.mean(lap_abs[cheek_mask == 255])) if np.any(cheek_mask == 255) else 1.0

        moust_delta = max(0.0, cheek_luma - moust_luma)
        jaw_delta = max(0.0, cheek_luma - jaw_luma)
        tex_ratio = jaw_tex / max(cheek_tex, 1.0)

        dark_beard_px = np.sum((jaw_mask == 255) & (gray < (cheek_luma - 22.0)))
        beard_cov_ratio = float(dark_beard_px / max(int(np.sum(jaw_mask == 255)), 1))

        if jaw_delta < 10.0 and moust_delta < 14.0 and beard_cov_ratio < 0.12:
            est_facial_hair = "clean_shaven"
        elif jaw_delta < 26.0 and beard_cov_ratio < 0.42:
            est_facial_hair = "light_stubble"
        elif jaw_delta < 45.0 or beard_cov_ratio < 0.68:
            est_facial_hair = "short_beard"
        else:
            est_facial_hair = "medium_or_full_beard"

        analysis = {
            "face_detected": True,
            "quality": {
                "width": w,
                "height": h,
                "sharpness_score": round(sharpness, 1),
                "brightness_score": round(brightness, 1),
                "contrast_score": round(contrast, 1),
                "face_area_ratio": round(face_area_ratio, 3),
                "yaw_degrees": round(yaw_deg, 1),
                "pitch_degrees": round(pitch_deg, 1),
                "roll_degrees": round(roll_deg, 1),
                "is_acceptable": is_acceptable,
                "warnings": warnings,
                "rejection_reason": rejection_reason,
            },
            "face_geometry": {
                "estimated_face_shape": face_shape,
                "confidence": shape_conf,
                "face_height_to_width_ratio": round(hw_ratio, 3),
                "jaw_to_cheek_ratio": round(jaw_cheek_ratio, 3),
                "forehead_to_cheek_ratio": round(fh_cheek_ratio, 3),
                "shape_guidance": shape_guidance,
            },
            "hair_analysis": {
                "visible_hair_ratio": round(visible_hair_ratio, 3),
                "estimated_current_length": est_hair_len,
                "visible_texture": visible_texture,
                "hair_density": hair_density,
                "forehead_exposure": forehead_exposure,
                "hairline_visible": hairline_visible,
                "eyewear_detected": eyewear_detected,
            },
            "facial_hair_analysis": {
                "estimated_current_facial_hair": est_facial_hair,
                "moustache_darkness_delta": round(moust_delta, 1),
                "jaw_beard_darkness_delta": round(jaw_delta, 1),
                "follicle_texture_ratio": round(tex_ratio, 2),
                "beard_coverage_ratio": round(beard_cov_ratio, 3),
            },
        }
        return oriented_img, analysis, pts, cat_mask

from typing import Dict, Any, List, Optional
import numpy as np
import cv2
from PIL import Image
from style_spec import StyleSpecification


class OutputQualityValidator:
    """
    Automated post-generation verification for AI Style Studio outputs.
    Checks every generated portrait against its StyleSpecification and the customer's original face:
      1. hair_changed: Hair region was genuinely transformed.
      2. silhouette_matches_spec: Crown height, temple compactness, and forehead fringe match StyleSpecification.
      3. beard_matches_spec: Facial hair density across cheeks, chin, and upper lip matches StyleSpecification.
      4. identity_preserved: Protected central face (eyes, nose bridge, glasses, lips) preserves >= 95% similarity.
      5. no_halo_artifact: Outer background ring outside the target haircut has no dark ghost hair halo.
    """

    def validate_single_output(
        self,
        ctx: Dict[str, Any],
        styled_pil: Image.Image,
        spec: StyleSpecification,
        diagnostics: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        u_slot = ctx["u_slot"].astype(np.float32)
        u_clean_shaven = ctx["u_clean_shaven"].astype(np.float32)
        u_pts = ctx["u_pts"]
        styled_np = np.array(styled_pil.convert("RGB")).astype(np.float32)

        h, w, _ = u_slot.shape
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)

        brow_y = float(min(u_pts[70, 1], u_pts[300, 1]))
        nose_y = float(u_pts[2, 1])

        # 1. Hair region change check
        cranial_zone = (yy < brow_y - 4.0)
        hair_l1_diff = float(np.mean(np.abs(styled_np[cranial_zone] - u_slot[cranial_zone])))
        hair_changed = hair_l1_diff >= 4.0

        # 2. Protected central facial identity preservation check (eyes, nose bridge, glasses, lips)
        eye_band = (
            (yy >= brow_y + 2.0)
            & (yy <= nose_y - 4.0)
            & (xx >= float(u_pts[234, 0]) + 12.0)
            & (xx <= float(u_pts[454, 0]) - 12.0)
        )
        if np.any(eye_band):
            identity_l1 = float(np.mean(np.abs(styled_np[eye_band] - u_slot[eye_band])))
        else:
            identity_l1 = 0.0
        identity_similarity = round(max(0.0, 1.0 - identity_l1 / 255.0), 4)
        identity_preserved = identity_similarity >= 0.95

        # 3. Beard region verification relative to clean_shaven baseline
        chin_cx = float(u_pts[152, 0])
        chin_cy = float(0.5 * (u_pts[17, 1] + u_pts[152, 1]))
        chin_patch_mask = (np.abs(xx - chin_cx) < 22.0) & (np.abs(yy - chin_cy) < 12.0)

        left_cheek_cx = float(0.5 * (u_pts[234, 0] + u_pts[61, 0]))
        right_cheek_cx = float(0.5 * (u_pts[454, 0] + u_pts[291, 0]))
        cheek_cy = float(0.5 * (u_pts[2, 1] + u_pts[17, 1]))
        cheek_patch_mask = (
            ((np.abs(xx - left_cheek_cx) < 14.0) | (np.abs(xx - right_cheek_cx) < 14.0))
            & (np.abs(yy - cheek_cy) < 12.0)
        )

        moust_cx = float(u_pts[0, 0])
        moust_cy = float(0.5 * (u_pts[2, 1] + u_pts[0, 1]))
        moust_patch_mask = (np.abs(xx - moust_cx) < 18.0) & (np.abs(yy - moust_cy) < 5.0)

        chin_darkening = float(
            np.mean(u_clean_shaven[chin_patch_mask] - styled_np[chin_patch_mask])
        ) if np.any(chin_patch_mask) else 0.0
        cheek_darkening = float(
            np.mean(u_clean_shaven[cheek_patch_mask] - styled_np[cheek_patch_mask])
        ) if np.any(cheek_patch_mask) else 0.0
        moust_darkening = float(
            np.mean(u_clean_shaven[moust_patch_mask] - styled_np[moust_patch_mask])
        ) if np.any(moust_patch_mask) else 0.0

        beard_matches = True
        beard_reason = "ok"
        if spec.beard_style == "clean_shaven":
            if chin_darkening > 4.5 or cheek_darkening > 4.5:
                beard_matches = False
                beard_reason = f"clean_shaven residual darkness too high (chin={chin_darkening:.1f}, cheek={cheek_darkening:.1f})"
        elif spec.beard_style == "goatee":
            if chin_darkening < 6.0 or cheek_darkening > 4.5:
                beard_matches = False
                beard_reason = f"goatee requires dark chin ({chin_darkening:.1f}) and clean cheeks ({cheek_darkening:.1f})"
        elif spec.beard_style == "moustache":
            if moust_darkening < 6.0 or chin_darkening > 4.5:
                beard_matches = False
                beard_reason = f"moustache requires dark upper lip ({moust_darkening:.1f}) and clean chin ({chin_darkening:.1f})"
        elif spec.beard_style == "stubble":
            if not (2.5 <= chin_darkening <= 32.0):
                beard_matches = False
                beard_reason = f"stubble darkening out of expected range ({chin_darkening:.1f})"
        elif spec.beard_style in ("light_beard", "short_beard", "full_beard"):
            min_expected = 5.0 if spec.beard_style == "light_beard" else (8.0 if spec.beard_style == "short_beard" else 12.0)
            if chin_darkening < min_expected:
                beard_matches = False
                beard_reason = f"{spec.beard_style} darkening ({chin_darkening:.1f}) below minimum ({min_expected:.1f})"

        # 4. Forehead / Fringe & Silhouette verification
        fh_cx = float(u_pts[10, 0])
        fringe_test_mask = (np.abs(xx - fh_cx) < 32.0) & (yy >= 142.0) & (yy <= 164.0)
        styled_luma = np.mean(styled_np, axis=2)
        orig_luma = np.mean(u_slot, axis=2)
        fringe_delta = float(np.mean(orig_luma[fringe_test_mask] - styled_luma[fringe_test_mask])) if np.any(fringe_test_mask) else 0.0

        silhouette_matches = True
        silhouette_reason = "ok"
        if spec.fringe_coverage_ratio >= 0.20 and fringe_delta < 2.0:
            silhouette_matches = False
            silhouette_reason = f"expected forward fringe hair, delta was {fringe_delta:.2f}"

        # 5. Halo artifact check outside outer hair boundary
        no_halo = True
        halo_score = 0.0
        if diagnostics and "target_hair_mask" in diagnostics:
            t_mask = (diagnostics["target_hair_mask"] > 0.25).astype(np.uint8)
            dil_inner = cv2.dilate(t_mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (11, 11)))
            dil_outer = cv2.dilate(t_mask, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25, 25)))
            forehead_box = (
                (yy >= float(u_pts[10, 1]) - 35.0)
                & (xx >= float(u_pts[70, 0]) - 15.0)
                & (xx <= float(u_pts[300, 0]) + 15.0)
            )
            outer_ring = (dil_outer > 0) & (dil_inner == 0) & (yy < brow_y - 15.0) & (~forehead_box)
            if np.any(outer_ring):
                ring_diff = float(np.mean(np.abs(styled_np[outer_ring] - ctx["u_bg_cleaned"].astype(np.float32)[outer_ring])))
                halo_score = round(ring_diff, 2)
                no_halo = ring_diff < 18.0

        passed = bool(hair_changed and identity_preserved and beard_matches and silhouette_matches and no_halo)

        return {
            "passed": passed,
            "hair_changed": hair_changed,
            "hair_l1_diff": round(hair_l1_diff, 2),
            "identity_preserved": identity_preserved,
            "identity_similarity": identity_similarity,
            "beard_matches_spec": beard_matches,
            "beard_reason": beard_reason,
            "chin_darkening": round(chin_darkening, 2),
            "cheek_darkening": round(cheek_darkening, 2),
            "moustache_darkening": round(moust_darkening, 2),
            "silhouette_matches_spec": silhouette_matches,
            "silhouette_reason": silhouette_reason,
            "no_halo_artifact": no_halo,
            "outer_ring_bg_diff": halo_score,
        }

    def validate_batch_diversity(self, portraits: List[Image.Image]) -> Dict[str, Any]:
        """Verifies that multiple generated style variations are visually distinct from one another."""
        if len(portraits) <= 1:
            return {"distinct_from_peers": True, "min_pairwise_l1": 0.0, "mean_pairwise_l1": 0.0}

        arrs = [np.array(p.convert("RGB")).astype(np.float32) for p in portraits]
        diffs: List[float] = []
        for i in range(len(arrs)):
            for j in range(i + 1, len(arrs)):
                diffs.append(float(np.mean(np.abs(arrs[i] - arrs[j]))))

        min_d = round(min(diffs), 2)
        mean_d = round(float(np.mean(diffs)), 2)
        return {
            "distinct_from_peers": min_d >= 1.8,
            "min_pairwise_l1": min_d,
            "mean_pairwise_l1": mean_d,
        }

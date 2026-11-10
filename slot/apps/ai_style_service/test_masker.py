import unittest
import numpy as np
from PIL import Image
from masker import FacialMaskManager


class TestFacialMaskManager(unittest.TestCase):
    def setUp(self):
        self.mgr = FacialMaskManager()
        self.h, self.w = 512, 512
        # Deterministic synthetic test image
        np.random.seed(42)
        self.orig_np = np.random.randint(50, 220, (self.h, self.w, 3), dtype=np.uint8)
        self.gen_np = np.random.randint(0, 255, (self.h, self.w, 3), dtype=np.uint8)

    def test_bit_exact_preservation_outside_mask(self):
        """Verifies 100% bit-exact equality for every pixel outside the approved edit mask."""
        # Create an elliptical edit mask in upper section
        mask = np.zeros((self.h, self.w), dtype=np.uint8)
        cv2_mask = cv2_circle = np.zeros((self.h, self.w), dtype=np.uint8)
        cv2_circle[100:250, 150:350] = 255

        composite = FacialMaskManager.composite_with_exact_preservation(
            original_np=self.orig_np,
            generated_np=self.gen_np,
            binary_mask=cv2_circle,
            protected_mask=None,
            blur_ksize=11,
        )

        unaltered_zone = (cv2_circle == 0)
        # Every single pixel outside cv2_circle must equal orig_np bit for bit
        diff = np.abs(composite[unaltered_zone].astype(int) - self.orig_np[unaltered_zone].astype(int))
        self.assertEqual(np.max(diff), 0, "Pixels outside approved mask must be 100% bit-exact to original!")

    def test_protected_region_immunity(self):
        """Verifies that protected pixels are preserved bit-exactly even if inside the edit mask bounding area."""
        edit_mask = np.zeros((self.h, self.w), dtype=np.uint8)
        edit_mask[100:300, 100:300] = 255

        # Protected region placed inside the edit mask
        protected_mask = np.zeros((self.h, self.w), dtype=np.uint8)
        protected_mask[180:220, 180:220] = 255

        composite = FacialMaskManager.composite_with_exact_preservation(
            original_np=self.orig_np,
            generated_np=self.gen_np,
            binary_mask=edit_mask,
            protected_mask=protected_mask,
            blur_ksize=11,
        )

        # Protected zone must equal orig_np bit for bit
        diff = np.abs(composite[protected_mask == 255].astype(int) - self.orig_np[protected_mask == 255].astype(int))
        self.assertEqual(np.max(diff), 0, "Protected facial region pixels must never be altered!")

    def test_bounded_feathering_never_expands(self):
        """Verifies that inner-bounded feathering never leaks outside the binary mask boundary."""
        mask = np.zeros((self.h, self.w), dtype=np.uint8)
        mask[100:200, 100:200] = 255

        feathered = FacialMaskManager.compute_bounded_feathered_mask(mask, blur_ksize=15)
        outside = (mask == 0)

        # Max alpha outside binary mask must be exactly 0.0
        max_leak = np.max(feathered[outside])
        self.assertEqual(max_leak, 0.0, "Feathered alpha must be strictly 0 outside the binary mask!")

    def test_mask_validation(self):
        """Verifies safe rejection of empty or excessively large masks."""
        empty_mask = np.zeros((self.h, self.w), dtype=np.uint8)
        self.assertFalse(self.mgr.validate_mask(empty_mask, min_area_ratio=0.01))

        full_mask = np.full((self.h, self.w), 255, dtype=np.uint8)
        self.assertFalse(self.mgr.validate_mask(full_mask, max_area_ratio=0.85))

        valid_mask = np.zeros((self.h, self.w), dtype=np.uint8)
        valid_mask[50:200, 50:200] = 255
        self.assertTrue(self.mgr.validate_mask(valid_mask))


if __name__ == "__main__":
    unittest.main()

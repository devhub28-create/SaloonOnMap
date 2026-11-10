import os
import sys
import unittest
from PIL import Image

sys.path.append(os.path.dirname(__file__))
from pipeline import AiStyleEngine, STYLE_PROMPTS

class TestAiStylePipeline(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        models_dir = os.path.join(os.path.dirname(__file__), "models")
        cls.engine = AiStyleEngine.get_instance(models_dir=models_dir)

    def test_01_models_loaded(self):
        self.assertIsNotNone(self.engine.segmenter, "MediaPipe segmenter should be loaded")
        self.assertIsNotNone(self.engine.landmarker, "MediaPipe landmarker should be loaded")
        self.assertIsNotNone(self.engine.inpaint_pipe, "Diffusers inpaint pipeline should be loaded")

    def test_02_image_normalization(self):
        test_img = Image.new("RGB", (800, 600), color=(200, 150, 100))
        norm_img, orig_size = self.engine.normalize_image(test_img, target_size=512)
        self.assertEqual(norm_img.size, (512, 512))
        self.assertEqual(orig_size, (800, 600))

    def test_03_style_prompts_configured(self):
        required_styles = [
            "textured_crop", "classic_side_part", "fade", "curly_style", "medium_length", "buzz_cut",
            "clean_shaven", "stubble", "short_beard", "full_beard", "goatee", "moustache"
        ]
        for style in required_styles:
            self.assertIn(style, STYLE_PROMPTS, f"Style '{style}' must be present in STYLE_PROMPTS")
            self.assertTrue(len(STYLE_PROMPTS[style]["prompt"]) > 10)

    def test_04_mask_extraction(self):
        test_img = Image.new("RGB", (512, 512), color=(180, 140, 110))
        masks = self.engine.extract_masks(test_img)
        self.assertIn("hair", masks)
        self.assertIn("beard", masks)
        self.assertIn("combined", masks)
        self.assertEqual(masks["hair"].size, (512, 512))

if __name__ == "__main__":
    unittest.main()

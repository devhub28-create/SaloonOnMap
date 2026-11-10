import os
import base64
import hashlib
from PIL import Image
from pipeline import AiStyleEngine


def test_dynamic_ai_style_studio():
    models_dir = os.path.join(os.path.dirname(__file__), "models")
    engine = AiStyleEngine.get_instance(models_dir=models_dir)

    # 1. Verify no static template assets exist
    assets_dir = os.path.join(os.path.dirname(__file__), "assets")
    assert not os.path.exists(os.path.join(assets_dir, "storyboard_template.jpg")), "Static template must not exist"
    assert not os.path.exists(os.path.join(assets_dir, "side_1.png")), "Static side_1.png must not exist"

    # 2. Verify invalid / blank photo is rejected honestly
    blank_img = Image.new("RGB", (400, 400), (220, 220, 220))
    blank_analysis = engine.analyze_photo(blank_img)
    assert blank_analysis["face_detected"] is False
    assert blank_analysis["quality"]["is_acceptable"] is False
    assert blank_analysis["face_geometry"]["estimated_face_shape"] == "uncertain"

    # 3. Verify real portrait analysis & dynamic preference-driven ranking
    sample_path = "/Users/manishdubey/.gemini/antigravity/brain/aad37d72-35ae-4411-b5ce-5e319350d0d6/.user_uploaded/media_1791869599296.jpg"
    if os.path.exists(sample_path):
        portrait = Image.open(sample_path)
        analysis = engine.analyze_photo(portrait)
        assert analysis["face_detected"] is True
        assert analysis["quality"]["is_acceptable"] is True
        assert analysis["hair_analysis"]["eyewear_detected"] is True

        # Preference Set A: Low maintenance + Short beard
        res_a = engine.generate_personalized_styles(
            portrait,
            preferences={"maintenance_level": "low", "beard_pref": "short_beard"},
            count=6,
        )
        # Preference Set B: Clean shaven + Professional
        res_b = engine.generate_personalized_styles(
            portrait,
            preferences={"beard_pref": "clean_shaven", "style_vibe": "professional"},
            count=4,
        )

        assert len(res_a["variations"]) == 6
        assert len(res_b["variations"]) == 4

        # Verify dynamic top recommendation changes based on customer preferences
        assert res_a["best_option"]["archetype_id"] != res_b["best_option"]["archetype_id"]
        assert res_b["best_option"]["archetype_id"] == "executive_side_part_clean"

        # Verify honest side/back view handling when only front photo is uploaded
        for v in res_a["variations"]:
            assert v["side_view_available"] is False
            assert v["back_view_available"] is False
            assert v["side_image_base64"] is None
            assert v["back_image_base64"] is None

        # Verify all 6 generated variation portraits are distinct images
        hashes = set()
        for v in res_a["variations"]:
            raw_bytes = base64.b64decode(v["image_base64"])
            hashes.add(hashlib.sha256(raw_bytes).hexdigest())
        assert len(hashes) == 6, "All 6 generated variations must have distinct pixel outputs"

    print("ALL DYNAMIC AI STYLE STUDIO TESTS PASSED!")


if __name__ == "__main__":
    test_dynamic_ai_style_studio()

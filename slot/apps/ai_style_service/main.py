import os
import io
import time
import base64
import asyncio
import psutil
import logging
from typing import Optional, List, Dict, Any
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from PIL import Image

from pipeline import AiStyleEngine, STYLE_CATALOG, COLOR_MODIFIERS

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("ai_style_service")

app = FastAPI(
    title="SLOT AI Style Studio Service",
    description="Dynamic Face-Based Hairstyle & Beard Analysis, StyleSpecification, and Multi-Stage Image Generation Service",
    version="4.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

engine: Optional[AiStyleEngine] = None
generation_semaphore = asyncio.Semaphore(1)


@app.on_event("startup")
async def startup_event():
    global engine
    models_dir = os.path.join(os.path.dirname(__file__), "models")
    logger.info("Initializing Dynamic AI Style Studio Engine v4.0 on startup...")
    engine = AiStyleEngine.get_instance(models_dir=models_dir)
    logger.info("Dynamic AI Style Studio Engine v4.0 initialized and ready.")


class VariationResult(BaseModel):
    id: str
    archetype_id: Optional[str] = None
    option_number: Optional[int] = None
    image_base64: str
    side_image_base64: Optional[str] = None
    back_image_base64: Optional[str] = None
    side_view_available: bool = False
    back_view_available: bool = False
    style_label: str
    hair_style: Optional[str] = None
    beard_style: Optional[str] = None
    header_hex: Optional[str] = None
    hair_length_cm: Optional[str] = None
    beard_length_mm: Optional[str] = None
    hair_desc: Optional[str] = None
    beard_desc: Optional[str] = None
    look_desc: Optional[str] = None
    why_it_suits: Optional[str] = None
    suitability_score: Optional[int] = None
    maintenance_level: Optional[str] = None
    styling_products: Optional[str] = None
    barber_instructions: Optional[List[str]] = None
    style_spec: Optional[Dict[str, Any]] = None
    validation: Optional[Dict[str, Any]] = None
    is_recommended: Optional[bool] = False
    seed: int
    elapsed_seconds: float


class GenerationResponse(BaseModel):
    success: bool
    analysis: Optional[Dict[str, Any]] = None
    preferences: Optional[Dict[str, Any]] = None
    storyboard_image_base64: Optional[str] = None
    variations: List[VariationResult]
    barber_notes: Optional[List[str]] = None
    best_option: Optional[Dict[str, Any]] = None
    total_time_seconds: float


@app.get("/api/v1/health")
async def health():
    mem = psutil.virtual_memory()
    return {
        "status": "healthy",
        "service": "SLOT AI Style Studio Service",
        "version": "4.0.0",
        "device": engine.device if engine else "not_loaded",
        "dtype": str(engine.dtype) if engine else "not_loaded",
        "models_loaded": {
            "diffusers_inpaint": engine.inpaint_pipe is not None if engine else False,
            "mediapipe_segmenter": engine.segmenter is not None if engine else False,
            "mediapipe_landmarker": engine.landmarker is not None if engine else False,
        },
        "memory": {
            "total_gb": round(mem.total / (1024**3), 2),
            "available_gb": round(mem.available / (1024**3), 2),
            "used_percent": mem.percent,
        },
        "architecture": "Multi-Stage StyleSpecification + Cranial Silhouette & Directional Strand Synthesis + OutputQualityValidator",
        "paid_api_used": False,
    }


@app.get("/api/v1/options")
async def get_options():
    return {
        "hairStyles": [
            {"id": "classic_side_part", "label": "Classic Side Part"},
            {"id": "textured_crop", "label": "Short Textured Crop"},
            {"id": "classic_taper", "label": "Classic Taper"},
            {"id": "modern_quiff", "label": "Quiff Style"},
            {"id": "buzz_cut", "label": "Crew Cut"},
            {"id": "textured_fringe", "label": "Textured Fringe"},
            {"id": "ivy_league", "label": "Ivy League Taper"},
            {"id": "medium_length", "label": "Layered Medium Flow"},
            {"id": "fade", "label": "High Skin Fade Crop"},
            {"id": "curly_style", "label": "Structured Pompadour"},
        ],
        "beardStyles": [
            {"id": "clean_shaven", "label": "Clean Shaven"},
            {"id": "stubble", "label": "Light Stubble (2–3 mm)"},
            {"id": "light_beard", "label": "Light Beard (3–5 mm)"},
            {"id": "short_beard", "label": "Short Boxed Beard (4–6 mm)"},
            {"id": "full_beard", "label": "Well-Groomed Beard (5–8 mm)"},
            {"id": "goatee", "label": "Tailored Goatee"},
            {"id": "moustache", "label": "Chevron Moustache"},
        ],
        "preferenceOptions": {
            "maintenanceLevels": [
                {"id": "any", "label": "Any Maintenance"},
                {"id": "low", "label": "Low Maintenance"},
                {"id": "medium", "label": "Medium Maintenance"},
                {"id": "high", "label": "High Styling Effort"},
            ],
            "styleVibes": [
                {"id": "any", "label": "All Vibes"},
                {"id": "professional", "label": "Professional / Executive"},
                {"id": "modern", "label": "Modern & Trendy"},
                {"id": "casual", "label": "Casual Everyday"},
                {"id": "classic", "label": "Timeless Classic"},
            ],
            "hairLengthPrefs": [
                {"id": "any", "label": "Keep Flexible"},
                {"id": "short", "label": "Go Shorter / Taper"},
                {"id": "medium", "label": "Medium Structured"},
                {"id": "long", "label": "Keep Volume / Flow"},
            ],
            "beardPrefs": [
                {"id": "any", "label": "Recommend Best"},
                {"id": "clean_shaven", "label": "Clean Shaven"},
                {"id": "stubble", "label": "Light Stubble"},
                {"id": "light_beard", "label": "Light Beard"},
                {"id": "short_beard", "label": "Short Boxed Beard"},
                {"id": "full_beard", "label": "Well-Groomed Beard"},
                {"id": "goatee", "label": "Tailored Goatee"},
                {"id": "moustache", "label": "Chevron Moustache"},
            ],
        },
        "catalogCount": len(STYLE_CATALOG),
        "colors": list(COLOR_MODIFIERS.keys()),
    }


@app.post("/api/v1/analyze")
async def analyze_photo(image: UploadFile = File(...)):
    """Analyzes an uploaded portrait photo for quality, face geometry, hair, eyewear, and facial hair."""
    if not engine:
        raise HTTPException(status_code=503, detail="AI engine not ready")
    try:
        contents = await image.read()
        raw_img = Image.open(io.BytesIO(contents))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image file: {e}")

    analysis = engine.analyze_photo(raw_img)
    return {
        "success": analysis.get("face_detected", False) and analysis.get("quality", {}).get("is_acceptable", False),
        "analysis": analysis,
    }


@app.post("/api/v1/mask-preview")
async def mask_preview(image: UploadFile = File(...)):
    if not engine:
        raise HTTPException(status_code=503, detail="Engine not initialized")
    try:
        contents = await image.read()
        pil_img = Image.open(io.BytesIO(contents))
        norm_img, _ = engine.normalize_image(pil_img)
        masks = engine.extract_masks(norm_img)

        def to_b64(img: Image.Image) -> str:
            buf = io.BytesIO()
            img.save(buf, format="PNG")
            return base64.b64encode(buf.getvalue()).decode("utf-8")

        return {
            "hair_mask_base64": to_b64(masks["hair"]),
            "beard_mask_base64": to_b64(masks["beard"]),
            "combined_mask_base64": to_b64(masks["combined"]),
        }
    except Exception as e:
        logger.error(f"Mask preview failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/generate", response_model=GenerationResponse)
async def generate(
    image: UploadFile = File(...),
    side_image: Optional[UploadFile] = File(None),
    back_image: Optional[UploadFile] = File(None),
    hair_style: Optional[str] = Form(None),
    beard_style: Optional[str] = Form(None),
    hair_color: Optional[str] = Form(None),
    beard_color: Optional[str] = Form(None),
    maintenance_level: Optional[str] = Form("any"),
    style_vibe: Optional[str] = Form("any"),
    hair_length_pref: Optional[str] = Form("any"),
    beard_pref: Optional[str] = Form("any"),
    variations_count: int = Form(6),
    steps: int = Form(18),
    mode: str = Form("storyboard"),
):
    if not engine:
        raise HTTPException(status_code=503, detail="AI engine not ready")

    try:
        contents = await image.read()
        raw_img = Image.open(io.BytesIO(contents))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Invalid image file: {e}")

    side_pil: Optional[Image.Image] = None
    back_pil: Optional[Image.Image] = None
    if side_image is not None:
        try:
            side_pil = Image.open(io.BytesIO(await side_image.read()))
        except Exception:
            side_pil = None
    if back_image is not None:
        try:
            back_pil = Image.open(io.BytesIO(await back_image.read()))
        except Exception:
            back_pil = None

    preferences = {
        "maintenance_level": maintenance_level or "any",
        "style_vibe": style_vibe or "any",
        "hair_length_pref": hair_length_pref or "any",
        "beard_pref": beard_pref or "any",
        "hair_style": hair_style,
        "beard_style": beard_style,
        "hair_color": hair_color,
        "beard_color": beard_color,
    }

    async with generation_semaphore:
        try:
            res = await asyncio.to_thread(
                engine.generate_personalized_styles,
                raw_image=raw_img,
                preferences=preferences,
                count=max(1, min(6, variations_count)),
                steps=steps,
                side_image=side_pil,
                back_image=back_pil,
            )
        except ValueError as ve:
            raise HTTPException(status_code=422, detail=str(ve))
        except Exception as e:
            logger.exception(f"Style generation failed: {e}")
            raise HTTPException(status_code=500, detail=f"Style generation failed: {e}")

    return GenerationResponse(
        success=True,
        analysis=res["analysis"],
        preferences=res["preferences"],
        storyboard_image_base64=res["storyboard_image_base64"],
        variations=[VariationResult(**v) for v in res["variations"]],
        barber_notes=res["barber_notes"],
        best_option=res["best_option"],
        total_time_seconds=res["total_time_seconds"],
    )


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)

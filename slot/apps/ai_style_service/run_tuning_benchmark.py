import os
import sys
import time
import json
import logging
from typing import Dict, Any, List
import numpy as np
from PIL import Image
import torch
import psutil

sys.path.append(os.path.dirname(__file__))
from pipeline import AiStyleEngine
from masker import FacialMaskManager

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("benchmark")

BENCH_OUT_DIR = os.path.join(os.path.dirname(__file__), "benchmark_outputs")
os.makedirs(BENCH_OUT_DIR, exist_ok=True)


def get_memory_mb() -> float:
    process = psutil.Process(os.getpid())
    return process.memory_info().rss / (1024 * 1024)


def run_benchmark(input_image_path: str) -> Dict[str, Any]:
    logger.info("==================================================")
    logger.info("AI STYLE STUDIO - TUNING & QUALITY BENCHMARK SUITE")
    logger.info("==================================================")

    init_t0 = time.time()
    models_dir = os.path.join(os.path.dirname(__file__), "models")
    engine = AiStyleEngine.get_instance(models_dir=models_dir)
    init_time = round(time.time() - init_t0, 3)
    logger.info(f"Engine Initialization Time: {init_time}s | Device: {engine.device}")

    raw_img = Image.open(input_image_path)
    orig_w, orig_h = raw_img.size

    # Stage 1: Face Analysis Timing
    ana_t0 = time.time()
    oriented_img, analysis, pts, cat_mask = engine.analyzer.analyze(raw_img)
    ana_time = round(time.time() - ana_t0, 4)
    logger.info(f"Facial Analysis Time: {ana_time}s | Detected: {analysis['face_detected']} | Shape: {analysis['face_geometry']['estimated_face_shape']}")

    # Stage 2: Mask Extraction Timing
    norm_img, _ = engine.normalize_image(oriented_img, target_size=512)
    norm_np = np.array(norm_img)

    mask_t0 = time.time()
    masks = engine.extract_masks(norm_img)
    mask_time = round(time.time() - mask_t0, 4)
    logger.info(f"Mask Extraction Time: {mask_time}s (Scalp Hair, Beard, Protected Facial Region)")

    # Save debug overlay
    debug_overlay = masks.get("debug_overlay")
    if debug_overlay:
        debug_overlay.save(os.path.join(BENCH_OUT_DIR, "debug_mask_overlay.png"))
        logger.info(f"Saved debug mask overlay to: {BENCH_OUT_DIR}/debug_mask_overlay.png")

    # Benchmark Matrix
    # Steps: 8, 10, 15
    # Guidance: 4.5, 6.0, 7.5
    configurations = [
        {"name": "Fast_8_Steps_G6.0", "steps": 8, "guidance": 6.0, "style": "textured_crop", "beard": "stubble", "roi": True},
        {"name": "Standard_10_Steps_G6.5", "steps": 10, "guidance": 6.5, "style": "textured_crop", "beard": "stubble", "roi": True},
        {"name": "High_15_Steps_G7.5", "steps": 15, "guidance": 7.5, "style": "textured_crop", "beard": "stubble", "roi": True},
        {"name": "FullFrame_10_Steps_G6.5", "steps": 10, "guidance": 6.5, "style": "textured_crop", "beard": "stubble", "roi": False},
        {"name": "BeardOnly_10_Steps_ShortBeard", "steps": 10, "guidance": 6.5, "style": None, "beard": "short_beard", "roi": True},
        {"name": "HairOnly_10_Steps_ClassicTaper", "steps": 10, "guidance": 6.5, "style": "classic_taper", "beard": None, "roi": True},
    ]

    benchmark_records = []
    latencies = []

    for idx, cfg in enumerate(configurations):
        logger.info(f"\n--- Running Test [{idx + 1}/{len(configurations)}]: {cfg['name']} ---")
        mem_before = get_memory_mb()
        gen_t0 = time.time()

        styled = engine.generate_variation(
            image=norm_img,
            hair_style=cfg["style"],
            beard_style=cfg["beard"],
            hair_color="natural_black",
            seed=424242,
            steps=cfg["steps"],
            precomputed_masks=masks,
        )

        gen_elapsed = round(time.time() - gen_t0, 3)
        latencies.append(gen_elapsed)
        mem_after = get_memory_mb()

        # Save output image
        out_filename = f"{cfg['name']}.png"
        out_path = os.path.join(BENCH_OUT_DIR, out_filename)
        styled.save(out_path)

        # Mathematical Bit-Exact Verification:
        styled_np = np.array(styled)
        active_mask_key = "combined" if (cfg["style"] and cfg["beard"]) else ("hair" if cfg["style"] else "beard")
        active_mask_np = np.array(masks[active_mask_key])
        unaltered_zone = (active_mask_np == 0)

        diff = np.abs(styled_np[unaltered_zone].astype(int) - norm_np[unaltered_zone].astype(int))
        max_outside_diff = int(np.max(diff))
        bit_exact_pass = (max_outside_diff == 0)

        # Protected zone check
        prot_np = np.array(masks["protected"])
        prot_diff = np.abs(styled_np[prot_np == 255].astype(int) - norm_np[prot_np == 255].astype(int))
        max_prot_diff = int(np.max(prot_diff)) if np.any(prot_np == 255) else 0
        prot_exact_pass = (max_prot_diff == 0)

        record = {
            "config": cfg,
            "latency_seconds": gen_elapsed,
            "memory_mb": round(mem_after, 1),
            "memory_delta_mb": round(mem_after - mem_before, 1),
            "bit_exact_outside_mask": bit_exact_pass,
            "max_outside_diff": max_outside_diff,
            "protected_face_unaltered": prot_exact_pass,
            "max_protected_diff": max_prot_diff,
            "output_path": out_path,
        }
        benchmark_records.append(record)

        logger.info(
            f"Latency: {gen_elapsed}s | Mem: {mem_after:.1f} MB | "
            f"Bit-Exact Outside: {bit_exact_pass} (max_diff={max_outside_diff}) | "
            f"Protected Features Intact: {prot_exact_pass}"
        )

    median_lat = float(np.median(latencies))
    p95_lat = float(np.percentile(latencies, 95))

    report = {
        "device": engine.device,
        "dtype": str(engine.dtype),
        "initialization_time_seconds": init_time,
        "facial_analysis_time_seconds": ana_time,
        "mask_extraction_time_seconds": mask_time,
        "median_latency_seconds": round(median_lat, 2),
        "p95_latency_seconds": round(p95_lat, 2),
        "peak_process_memory_mb": round(get_memory_mb(), 1),
        "benchmark_records": benchmark_records,
    }

    report_path = os.path.join(BENCH_OUT_DIR, "benchmark_report.json")
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2)

    logger.info("\n==================================================")
    logger.info("BENCHMARK SUMMARY:")
    logger.info(f"Median Generation Latency: {median_lat:.2f}s | P95 Latency: {p95_lat:.2f}s")
    logger.info(f"Report saved to: {report_path}")
    logger.info("==================================================")
    return report


if __name__ == "__main__":
    sample_path = "uploads/orig_1791893679615_gd2tgb.jpg"
    backend_sample = os.path.join(os.path.dirname(__file__), "../backend/uploads/ai-styles/originals/orig_1791893679615_gd2tgb.jpg")
    
    if os.path.exists(backend_sample):
        sample_path = backend_sample
    elif not os.path.exists(sample_path):
        # Fallback to test image
        img = Image.new("RGB", (512, 512), (180, 150, 120))
        img.save("temp_bench.jpg")
        sample_path = "temp_bench.jpg"

    run_benchmark(sample_path)

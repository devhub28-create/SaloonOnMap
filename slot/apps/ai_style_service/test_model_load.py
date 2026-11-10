import os
import sys
import time
import torch
from diffusers import StableDiffusionInpaintPipeline, DPMSolverMultistepScheduler
from PIL import Image, ImageDraw

def test_pipeline():
    print("Testing Stable Diffusion Inpainting pipeline on MPS/CPU...")
    device = "mps" if torch.backends.mps.is_available() else "cpu"
    dtype = torch.float16 if device == "mps" else torch.float32
    print(f"Target device: {device}, dtype: {dtype}")

    model_id = "stable-diffusion-v1-5/stable-diffusion-inpainting"
    print(f"Loading {model_id} (fp16)...")
    start = time.time()
    pipe = StableDiffusionInpaintPipeline.from_pretrained(
        model_id,
        torch_dtype=dtype,
        variant="fp16" if dtype == torch.float16 else None,
        safety_checker=None
    )
    pipe.scheduler = DPMSolverMultistepScheduler.from_config(pipe.scheduler.config)
    pipe.to(device)
    load_time = time.time() - start
    print(f"Model loaded successfully in {load_time:.2f}s!")

    # Create dummy 512x512 image and mask
    image = Image.new("RGB", (512, 512), color=(180, 160, 140))
    mask = Image.new("L", (512, 512), color=0)
    draw = ImageDraw.Draw(mask)
    draw.rectangle([100, 100, 412, 300], fill=255)

    prompt = "handsome man with textured crop modern fade haircut, realistic, 8k"
    print("Running test inference with 15 steps...")
    gen_start = time.time()
    result = pipe(
        prompt=prompt,
        image=image,
        mask_image=mask,
        num_inference_steps=15,
        guidance_scale=7.5
    ).images[0]
    gen_time = time.time() - gen_start
    print(f"Test inference completed in {gen_time:.2f}s!")
    os.makedirs("test_output", exist_ok=True)
    result.save("test_output/test_inpaint_result.png")
    print("Saved test output to test_output/test_inpaint_result.png")

if __name__ == "__main__":
    test_pipeline()

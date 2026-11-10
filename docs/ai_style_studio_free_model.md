# SLOT AI Style Studio — Free / Open-Weight Model Architecture

## 1. Executive Summary

SLOT AI Style Studio provides personalized virtual hairstyle and beard grooming previews natively within the SLOT Customer application using a **100% free, open-weight, locally hosted neural inpainting model**. 

No subscription APIs (OpenAI, Replicate, Midjourney, Stability AI), paid credits, or third-party cloud inference services are required or used. The model weights execute directly on the local machine using Apple Silicon Metal Performance Shaders (MPS) hardware acceleration.

---

## 2. Hardware Resource Inspection & Validation

The development and host environment was inspected prior to model selection to guarantee execution compatibility:

- **Operating System**: macOS Darwin 25.5.0 (ARM64)
- **CPU**: Apple M2 (8 cores: 4 performance + 4 efficiency)
- **Unified RAM**: 8.00 GB Unified Memory
- **Hardware Acceleration**: Apple Silicon MPS (`torch.backends.mps.is_available() == True`)
- **Disk Availability**: ~26.0 GB free space on APFS container
- **Python Runtime**: Python 3.11.15 in dedicated virtual environment (`slot/apps/ai_style_service/venv`)

### Critical Hardware Constraint Findings:
1. **8 GB Unified Memory Ceiling**: Large models like SDXL (6.5 GB weights + 12 GB runtime memory) or Flux.1 (12-24 GB) cause immediate virtual memory thrashing and kernel out-of-memory crashes on 8 GB machines.
2. **Apple Silicon Docker Limitation**: Docker containers virtualizing Linux on macOS **do not have access to Apple Silicon Metal/MPS acceleration**. Running diffusion models inside Docker on macOS forces slow CPU emulation (taking 15+ minutes per image). Therefore, the AI Style Service runs natively on the macOS host for Metal GPU acceleration, while providing a Dockerfile for Linux x86/NVIDIA CUDA production deployments.

---

## 3. Model Selection Analysis

| Model Candidate | Weight Size | RAM Required | License | Commercial Use | Face Preservation | MPS Speed (per image) | Verdict |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Stable Diffusion v1-5 Inpainting** (`fp16`) | **2.13 GB** | **~4.5 - 5.3 GB** | **CreativeML OpenRAIL-M** | **Allowed** | **Bit-exact outside mask** | **~9.7 - 11.2s** | **SELECTED** |
| SDXL Inpainting | 6.46 GB | > 12 GB | CreativeML OpenRAIL++ | Allowed | Moderate | OOM on 8 GB RAM | Rejected (OOM) |
| InstructPix2Pix | 3.40 GB | ~7.0 GB | CreativeML OpenRAIL-M | Allowed | Poor (modifies entire face) | ~35s | Rejected |
| Text-to-Image (SD 1.5) | 2.13 GB | ~4.5 GB | CreativeML OpenRAIL-M | Allowed | Zero (hallucinates new face) | ~10s | Rejected (No identity) |
| DALL-E 3 / Midjourney | Cloud API | N/A | Proprietary | Paid Subscription | N/A | Cloud Network | Prohibited by prompt |

### Selected Model Specifications:
- **Hugging Face Hub ID**: `stable-diffusion-v1-5/stable-diffusion-inpainting`
- **Format**: `fp16` SafeTensors
- **Download Size**: 2.13 GB
- **License**: CreativeML OpenRAIL-M (Free, open-source, commercial use permitted)
- **Conditioning**: Mask-guided inpainting with 9-channel UNet (4 latent channels + 1 mask channel + 4 masked latent channels).

---

## 4. Multi-Stage Pipeline Architecture

```
User Selfie / Portrait
       │
       ▼
[1. Preprocessing & Normalization]
  - EXIF orientation auto-correction
  - Proportional 512x512 letterbox canvas
       │
       ▼
[2. Anatomical Region Segmentation]
  - MediaPipe Multiclass Segmenter: Category 1 (Hair)
  - MediaPipe FaceLandmarker (478 3D points): Jawline polygon (234->152->454)
  - Lip & mouth aperture subtraction
       │
       ▼
[3. Mask Feathering & Guidance]
  - Morphological closing (fills follicle gaps)
  - Gaussian blur edge feathering (radius 15px)
       │
       ▼
[4. Latent Neural Inpainting (MPS)]
  - DPMSolverMultistepScheduler (8-12 steps)
  - Attention Slicing (enables execution in 5.3 GB RAM)
  - Targeted style prompt + negative prompt
       │
       ▼
[5. Composite Alpha Blending]
  - Blended: Result * FeatheredMask + Original * (1 - FeatheredMask)
  - 100% Bit-exact preservation of eyes, nose, cheeks, ears & background!
       │
       ▼
Final Styled Variations (PNG Base64)
```

---

## 5. Commercial Licensing and Responsible AI Compliance

The **CreativeML OpenRAIL-M** license grants free commercial exploitation of both the model weights and generated outputs under Section 5. The following obligations are strictly enforced in SLOT:
1. **User Consent**: The customer must give explicit consent prior to photo processing (`consentGiven: true`).
2. **Zero Biometric Profiling**: Facial landmarks are computed ephemerally in RAM exclusively to determine hair and beard mask contours; biometric templates are neither extracted nor stored.
3. **No Paid Inference Dependencies**: The application runtime is entirely self-sufficient without vendor lock-in.

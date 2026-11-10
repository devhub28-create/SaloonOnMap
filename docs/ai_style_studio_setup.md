# SLOT AI Style Studio — Installation & Operations Setup Guide

This guide details how to launch and operate the local AI Style Studio inference service and its integration with the SLOT NestJS backend and Flutter Customer App.

---

## 1. Prerequisites

- **macOS** (Apple Silicon M1/M2/M3/M4 recommended for MPS acceleration) OR **Linux** with NVIDIA GPU (CUDA 11.8+).
- **Python 3.11** installed.
- **Node.js 20+** with PostgreSQL 15+.
- **Flutter 3.22+** with Android/iOS SDKs.

---

## 2. Setting Up the Local Python AI Service

The AI inference service lives at `slot/apps/ai_style_service/`.

```bash
cd slot/apps/ai_style_service

# 1. Create a Python 3.11 virtual environment
python3.11 -m venv venv
source venv/bin/activate

# 2. Install dependencies
pip install --no-cache-dir -r requirements.txt

# 3. Ensure MediaPipe models are in models/ directory
mkdir -p models
curl -L "https://storage.googleapis.com/mediapipe-models/image_segmenter/selfie_multiclass_256x256/float32/latest/selfie_multiclass_256x256.tflite" -o models/selfie_multiclass.tflite
curl -L "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task" -o models/face_landmarker.task

# 4. Run the FastAPI service on port 8000
uvicorn main:app --host 127.0.0.1 --port 8000
```

### Validating Service Health:
```bash
curl http://127.0.0.1:8000/api/v1/health
```
Expected output:
```json
{
  "status": "healthy",
  "service": "SLOT AI Style Studio Service",
  "device": "mps",
  "dtype": "torch.float16",
  "models_loaded": {
    "diffusers_inpaint": true,
    "mediapipe_segmenter": true,
    "mediapipe_landmarker": true
  },
  "open_source_model": "stable-diffusion-v1-5/stable-diffusion-inpainting",
  "license": "CreativeML OpenRAIL-M (Free for Commercial Use)",
  "paid_api_used": false
}
```

---

## 3. NestJS Backend Integration

The backend proxies requests and persists jobs securely without exposing the internal Python port to the public network.

In `slot/apps/backend/.env`:
```env
AI_STYLE_SERVICE_URL=http://127.0.0.1:8000
```

Start the backend:
```bash
cd slot/apps/backend
npm run start:dev
```

Test proxy health:
```bash
curl http://localhost:3000/api/v1/ai-style/health
```

---

## 4. Mobile Device ADB Reverse (Physical Device / Emulator)

When testing with a physical Android phone connected via USB:
```bash
adb reverse tcp:3000 tcp:3000
```
This allows the Flutter app running on the physical phone to reach `http://127.0.0.1:3000/api/v1` on your local host computer directly.

---

## 5. Docker Deployment (Linux / Cloud GPU Server)

For cloud or on-prem Linux servers with NVIDIA GPUs:
```bash
cd slot/apps/ai_style_service
docker build -t slot-ai-style:latest .
docker run --gpus all -p 8000:8000 slot-ai-style:latest
```
*(Note: On Apple Silicon macOS, run directly on host using Python venv rather than Docker to utilize Apple Metal GPU acceleration).*

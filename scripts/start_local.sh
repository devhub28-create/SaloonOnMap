#!/usr/bin/env bash
set -e

echo "🚀 Starting SLOT Local Environment..."

# 1. Setup ADB Reverse Proxy for connected Android device if available
if command -v adb >/dev/null 2>&1; then
  DEVICE_ID=$(adb devices | grep -v "List" | grep "device" | head -n 1 | awk '{print $1}')
  if [ -n "$DEVICE_ID" ]; then
    echo "📱 Mapping ADB port 3000 to device $DEVICE_ID..."
    adb -s "$DEVICE_ID" reverse tcp:3000 tcp:3000
  fi
fi

# 2. Start Docker Stack
cd "$(dirname "$0")/../slot"
docker compose up -d --build

echo "🌱 Seeding Database..."
docker compose exec -T backend node dist/src/seed.js

echo "✅ Backend Stack Ready at http://localhost:3000/api/v1"
echo "📚 Swagger API Docs: http://localhost:3000/api/v1/docs"

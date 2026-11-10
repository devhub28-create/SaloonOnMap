#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../slot/apps/customer_app"
DEVICE_ID=$(adb devices | grep -v "List" | grep "device" | head -n 1 | awk '{print $1}')

if [ -z "$DEVICE_ID" ]; then
  echo "❌ No physical Android device connected. Please connect your device via USB."
  exit 1
fi

echo "📱 Launching Customer App on device $DEVICE_ID..."
flutter run -d "$DEVICE_ID"

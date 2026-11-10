#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../slot/apps/partner_app"
DEVICE_ID=$(adb devices | grep -v "List" | grep "device" | head -n 1 | awk '{print $1}')

if [ -n "$DEVICE_ID" ]; then
  echo "📱 Launching Partner App on device $DEVICE_ID..."
  flutter run -d "$DEVICE_ID"
else
  echo "🌐 Launching Partner App in Chrome..."
  flutter run -d chrome
fi

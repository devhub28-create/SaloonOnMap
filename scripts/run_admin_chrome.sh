#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../slot/apps/admin_panel"
echo "🌐 Launching Admin Panel in Chrome..."
flutter run -d chrome

#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/../slot"
echo "🛑 Stopping Docker containers..."
docker compose down
echo "✅ Stopped."

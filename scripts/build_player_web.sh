#!/usr/bin/env bash
# Build player web app and append push handler to the service worker.
# Use for local deploy when you want push to work when the app is closed.
# Run from repo root: ./scripts/build_player_web.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "Building player web (release)..."
(cd apps/player && flutter build web --release)

echo "Appending push handler to service worker..."
node scripts/append_push_to_sw.js

echo "Done. Output: apps/player/build/web"
echo "Deploy with: firebase deploy --only hosting"

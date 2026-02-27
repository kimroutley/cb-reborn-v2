#!/usr/bin/env bash
# Generate VAPID keys for Web Push and print next steps.
# Run from repo root: ./scripts/setup_push_vapid.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "Installing functions dependencies..."
(cd functions && npm install --silent)

echo "Generating VAPID keys..."
(cd functions && npx web-push generate-vapid-keys)

echo ""
echo "=== Copy the Public Key and Private Key from above ==="
echo ""
echo "Then run (replace PASTE_PUBLIC_KEY and PASTE_PRIVATE_KEY):"
echo '  firebase functions:config:set vapid.public_key="PASTE_PUBLIC_KEY" vapid.private_key="PASTE_PRIVATE_KEY"'
echo ""
echo "Edit apps/player/lib/services/push_subscription_register.dart:"
echo "  const String vapidPublicKeyBase64 = 'PASTE_PUBLIC_KEY';"
echo ""
echo "Deploy:"
echo "  firebase deploy --only functions"
echo ""
echo "Full runbook: docs/operations/LETS_DO_IT_RUNBOOK.md Section 2"

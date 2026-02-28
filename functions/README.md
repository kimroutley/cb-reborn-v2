# Club Blackout Reborn – Cloud Functions (Push Notifications)

This directory contains Firebase Cloud Functions that send **Web Push** notifications when game state or private state changes in Firestore. Players receive notifications for role assignment, game start, phase changes, new bulletin messages, and rematch.

## Prerequisites

- Node.js >= 18
- Firebase CLI: `npm install -g firebase-tools`
- Project: `cb-reborn` (or your Firebase project)

---

## One-time setup checklist

Do these once per environment (or when you rotate VAPID keys):

| Step | Action |
|------|--------|
| 1 | **Install dependencies:** `cd functions && npm install` |
| 2 | **Generate VAPID keys:** `npx web-push generate-vapid-keys` (copy both keys from output) |
| 3 | **Set Firebase config:** `firebase functions:config:set vapid.public_key="PUBLIC_KEY" vapid.private_key="PRIVATE_KEY"` (use the keys from step 2; keep the private key secret) |
| 4 | **Set player app key:** In `apps/player/lib/services/push_subscription_register.dart`, set `vapidPublicKeyBase64` to the **same public key** as in step 3 |
| 5 | **Deploy Cloud Functions:** From repo root, `firebase deploy --project cb-reborn --only functions` |
| 6 | **Deploy Firestore rules** (if not already done): `firebase deploy --project cb-reborn --only firestore:rules` |
| 7 | **(Optional) Deploy player web:** So the latest key and push handler are live. From repo root: `.\scripts\deploy_firebase.ps1 -HostingOnly` (omit `-SkipBuild` to build and append the push handler first) |

After this, push works when players tap “Enable” in the notifications banner and the host updates game/private state.

---

## 1. Install dependencies

```bash
cd functions
npm install
```

## 2. VAPID keys (required for Web Push)

Web Push uses VAPID keys to authenticate the server. Generate a key pair once and use it in both the Cloud Functions config and the player web app.

### Generate keys

```bash
npx web-push generate-vapid-keys
```

You will get output like:

```
Public Key:  BP2O8P3Tj8N4Z5PtSUaFi_vRq8F_jHEGtaQqRcZlbDK6Ddzbnmqfu3nXa9DEUr7za8m6ghctcy11EhcPCXXw9Vo
Private Key: xyz123...
```

### Set Firebase Functions config

Set the **private** and **public** key in Firebase (used by the Cloud Functions):

```bash
firebase functions:config:set vapid.public_key="YOUR_PUBLIC_KEY_BASE64URL" vapid.private_key="YOUR_PRIVATE_KEY_BASE64URL"
```

Use the exact strings from the generator (they are already base64url).

### Set the public key in the Player app

The player web app needs the **public** key only (to create a push subscription).

1. Open `apps/player/lib/services/push_subscription_register.dart`.
2. Set the constant `vapidPublicKeyBase64` to your **public** key string (same value as `vapid.public_key` in Firebase config).

Example:

```dart
const String vapidPublicKeyBase64 =
    'BP2O8P3Tj8N4Z5PtSUaFi_vRq8F_jHEGtaQqRcZlbDK6Ddzbnmqfu3nXa9DEUr7za8m6ghctcy11EhcPCXXw9Vo';
```

**Important:** The key in the player app must match the public key in Firebase config. Otherwise push subscriptions will not work.

## 3. Deploy Cloud Functions

From the **repository root** (so Firebase sees both `firebase.json` and `functions/`):

```bash
firebase deploy --project cb-reborn --only functions
```

Or deploy a single function:

```bash
firebase deploy --project cb-reborn --only functions:onGameUpdated,functions:onPrivateStateUpdated
```

## 4. What gets deployed

| Function | Trigger | Purpose |
|----------|---------|--------|
| `onGameUpdated` | `games/{joinCode}` updated | Sends push on phase change (setup/night/day), rematch offered, new bulletin. |
| `onPrivateStateUpdated` | `games/{joinCode}/private_state/{playerId}` updated | Sends push to that player when `roleId` is set (role assigned). |

Notifications are sent only to players who have registered a push subscription (via the in-app “Enable” button in the notifications banner). Subscriptions are stored in `games/{joinCode}/push_subscriptions/{playerId}`.

## 5. Player web app (push when app is closed)

For notifications to show when the browser tab or PWA is closed:

1. Build the player web app: `cd apps/player && flutter build web --release`
2. Append the push handler: from repo root, `node scripts/append_push_to_sw.js`
3. Deploy hosting (e.g. `.\scripts\deploy_firebase.ps1 -HostingOnly -SkipBuild` if you already ran the steps above).

The standard deploy script `scripts/deploy_firebase.ps1` (without `-SkipBuild`) runs the append step automatically after the Flutter build.

## 6. Troubleshooting

- **No notifications:** Ensure VAPID keys are set (`firebase functions:config:get`), the player has clicked “Enable” in the app, and the service worker was built with the push handler appended.
- **410/404 from web-push:** The subscription expired or was invalid; the user may need to re-enable notifications in the app.
- **Functions config:** Run `firebase functions:config:get` to verify `vapid.private_key` and `vapid.public_key` are set.

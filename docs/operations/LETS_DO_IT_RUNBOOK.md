# Let’s Do It – Runbook

One place to unblock CI deploy, enable push notifications, and run real-device validation.

---

## Quick start

1. **Unblock deploy** → Add the 3 GitHub secrets (Section 1). Push to `main` or re-run the workflow. **Verify:** “Deploy to Firebase” job succeeds.
2. **Push (optional)** → Run the VAPID setup script, then follow the printed steps (Section 2). **Verify:** Player can enable notifications in lobby/game; test with app closed.
3. **Device QA** → Run the smoke checklist (Section 3). **Verify:** Execution log filled with date, devices, pass/fail.

---

## 1. Firebase CI deploy (unblock GitHub Actions)

Deploy to Firebase Hosting and Firestore rules currently fails until these **repository secrets** exist.

**Where:** GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.  
**Checklist:** [GITHUB_SECRETS_CHECKLIST.md](GITHUB_SECRETS_CHECKLIST.md) — tick as you add each secret.

| Secret name | What to put |
|-------------|-------------|
| `FIREBASE_SERVICE_ACCOUNT` | **Full JSON** of your Firebase service account key. In [Firebase Console](https://console.firebase.google.com) → Project Settings → Service accounts → Generate new private key. Paste the entire file contents (one line or pretty-printed). |
| `FIREBASE_PROJECT_ID` | Your Firebase project ID (e.g. `cb-reborn-xxxx`). Found in Project Settings → General. |
| `FIREBASE_TOKEN` | CI token: run `firebase login:ci` locally, sign in, then paste the printed token. |

After adding all three, push to `main` (or re-run the workflow). The **Deploy to Firebase** job will validate and deploy.

**Verify:** In GitHub Actions, the “Deploy to Firebase” job completes without “Missing required secret” errors. Hosting and Firestore rules are updated.

---

## 2. Push notifications (VAPID + service worker)

So players get notifications when the browser/app is closed.

### 2.1 Generate VAPID keys (script)

From repo root:

**PowerShell (Windows):**
```powershell
.\scripts\setup_push_vapid.ps1
```

**Bash (macOS/Linux):**
```bash
./scripts/setup_push_vapid.sh
```

The script installs dependencies, runs `npx web-push generate-vapid-keys`, and prints the exact next steps. Copy the **public** and **private** key strings from the output.

**Manual alternative:** From repo root:
```bash
cd functions
npm install
npx web-push generate-vapid-keys
```

### 2.2 Configure Firebase Functions

If you see a deprecation error, run once: `firebase experiments:enable legacyRuntimeConfigCommands`

```bash
firebase functions:config:set vapid.public_key="PASTE_PUBLIC_KEY" vapid.private_key="PASTE_PRIVATE_KEY"
```

### 2.3 Set public key in the player app

Edit **`apps/player/lib/services/push_subscription_register.dart`**:

```dart
const String vapidPublicKeyBase64 = 'PASTE_PUBLIC_KEY_HERE';
```

Use the **same** public key string from step 2.1.

### 2.4 Deploy Cloud Functions

```bash
firebase deploy --only functions
```

### 2.5 Service worker (web build)

- **CI:** The GitHub Actions workflow already runs `node scripts/append_push_to_sw.js` after the player web build, so every deploy to Firebase Hosting includes the push handler.
- **Local deploy:** Use one of:
  - **`scripts/build_player_web.ps1`** (Windows) or **`scripts/build_player_web.sh`** (macOS/Linux) — builds web and appends the push handler; then deploy `apps/player/build/web` (e.g. `firebase deploy --only hosting`).
  - **`scripts/deploy_firebase.ps1`** — when you do a full deploy (without `-SkipBuild`), it builds player web and appends the push handler before deploying.

**Verify:** In the player app (web), join a cloud game, allow notifications when prompted, then close the tab. Trigger an event (e.g. host assigns role or advances phase). A push notification should appear.

---

## 3. Real-device validation

Use the **QA Smoke Checklist** and tick as you go:

- **Checklist:** [qa-smoke-checklist.md](qa-smoke-checklist.md)

Priority order:

1. **Real-device multiplayer** – Local mode (host + player), then Cloud mode (phase transitions, reconnect).
2. **Mode switching** – LOCAL ↔ CLOUD in same session, no stale roster.
3. **Deep-link + QR** – Cold/warm join, invalid link/QR handling.
4. **Host iOS email-link E2E** – Request link → open in Mail → deep-link back → confirm signed-in state; repeat sign-out/sign-in once.

Fill the **Execution log** at the bottom of the smoke checklist (date, devices, build refs, pass/fail, follow-ups).

**Verify:** Execution log is filled. All priority items ticked or explicitly skipped with a reason.

---

## 4. Quick reference

| Goal | Doc / action |
|------|----------------|
| Unblock Firebase deploy | Add 3 secrets (Section 1). |
| Enable push when app closed | Run `scripts/setup_push_vapid.ps1` or `.sh`, then Section 2.2–2.4; CI/local build already append push handler (Section 2.5). |
| Local player web build with push | `scripts/build_player_web.ps1` or `scripts/build_player_web.sh`. |
| Validate on devices | Run [qa-smoke-checklist.md](qa-smoke-checklist.md) (Section 3). |
| Host iOS email-link | Smoke checklist → “Host iOS email-link E2E”. |

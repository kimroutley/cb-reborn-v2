# Let’s Do It – Runbook

One place to unblock CI deploy, enable push notifications, and run real-device validation.

---

## 1. Firebase CI deploy (unblock GitHub Actions)

Deploy to Firebase Hosting and Firestore rules currently fails until these **repository secrets** exist.

**Where:** GitHub repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**.

| Secret name | What to put |
|-------------|-------------|
| `FIREBASE_SERVICE_ACCOUNT` | **Full JSON** of your Firebase service account key. In [Firebase Console](https://console.firebase.google.com) → Project Settings → Service accounts → Generate new private key. Paste the entire file contents (one line or pretty-printed). |
| `FIREBASE_PROJECT_ID` | Your Firebase project ID (e.g. `cb-reborn-xxxx`). Found in Project Settings → General. |
| `FIREBASE_TOKEN` | CI token: run `firebase login:ci` locally, sign in, then paste the printed token. |

After adding all three, push to `main` (or re-run the workflow). The **Deploy to Firebase** job will validate and deploy.

---

## 2. Push notifications (VAPID + service worker)

So players get notifications when the browser/app is closed.

### 2.1 Generate VAPID keys

From repo root:

```bash
cd functions
npm install
npx web-push generate-vapid-keys
```

Copy the **public** and **private** key strings.

### 2.2 Configure Firebase Functions

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

After every **player web build**, append the push handler so push works when the tab is closed:

```bash
cd apps/player
flutter build web
cd ../..
node scripts/append_push_to_sw.js
```

Then deploy the contents of `apps/player/build/web` (e.g. via the CI deploy above, or `firebase deploy --only hosting`).  
If you use CI, add a step to run `node scripts/append_push_to_sw.js` after the web build and before uploading the artifact.

---

## 3. Real-device validation

Use the **QA Smoke Checklist** and tick as you go:

- **Checklist:** [`docs/operations/qa-smoke-checklist.md`](qa-smoke-checklist.md)

Priority order:

1. **Real-device multiplayer** – Local mode (host + player), then Cloud mode (phase transitions, reconnect).
2. **Mode switching** – LOCAL ↔ CLOUD in same session, no stale roster.
3. **Deep-link + QR** – Cold/warm join, invalid link/QR handling.
4. **Host iOS email-link E2E** – Request link → open in Mail → deep-link back → confirm signed-in state; repeat sign-out/sign-in once.

Fill the **Execution log** at the bottom of the smoke checklist (date, devices, build refs, pass/fail, follow-ups).

---

## 4. Quick reference

| Goal | Doc / action |
|------|----------------|
| Unblock Firebase deploy | Add 3 secrets (Section 1). |
| Enable push when app closed | VAPID + `vapidPublicKeyBase64` + deploy functions + append script after web build (Section 2). |
| Validate on devices | Run [qa-smoke-checklist.md](qa-smoke-checklist.md) (Section 3). |
| Host iOS email-link | Smoke checklist → “Host iOS email-link E2E”. |

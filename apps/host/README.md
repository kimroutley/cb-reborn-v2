# cb_host (Host App)

Host/dashboard app for Club Blackout Reborn.

## What this app does

- Creates/hosts a session (local WebSocket or cloud sync)
- Runs the game loop (lobby → setup → night/day cycles → endgame)
- Provides tactical monitoring + God Mode tools
- Generates Games Night recaps and displays stats/history

## Firebase Auth Setup (Email Link)

Host uses **Firebase Email Link (passwordless)** sign-in.

- Firebase Console → Authentication → Sign-in method: enable **Email/Password**.
- Firebase Console → Authentication → Sign-in method: enable **Email link (passwordless sign-in)**.
- Ensure authorized domains include `cb-reborn.web.app`.
- Continue URL used by Host auth gate: `https://cb-reborn.web.app/email-link-signin?app=host`.
- Current `ActionCodeSettings` app IDs:
  - Android: `com.clubblackout.cb_host`
  - iOS: `com.clubblackout.cbHost`
- For iOS email-link completion, Runner must include Associated Domains: `applinks:cb-reborn.web.app`.

If your Firebase project uses different package/bundle IDs, update Host auth settings before release.

## Firebase Auth Preflight (Quick Check)

Before testing Host sign-in, confirm all 5 are true:

- [ ] **Email/Password** provider is enabled.
- [ ] **Email link (passwordless)** provider is enabled.
- [ ] `cb-reborn.web.app` is listed in Authentication authorized domains.
- [ ] Continue URL matches Host flow: `https://cb-reborn.web.app/email-link-signin?app=host`
- [ ] Host IDs match Firebase app registration (`com.clubblackout.cb_host` for Android, `com.clubblackout.cbHost` for iOS).

## Firebase Email Link Troubleshooting

- `auth/invalid-action-code`: request a new Host sign-in link and use only the latest email.
- `auth/unauthorized-continue-uri`: add `cb-reborn.web.app` (or your domain) to Firebase Authentication authorized domains.
- `auth/operation-not-allowed`: ensure both **Email/Password** and **Email link (passwordless)** are enabled.
- Link opens but Host does not sign in: verify Host `ActionCodeSettings` IDs match Firebase app registration (`com.clubblackout.cb_host` on Android, `com.clubblackout.cbHost` on iOS), and verify iOS Associated Domains includes `applinks:cb-reborn.web.app`.

## Run

```powershell
cd apps/host
flutter run
```

## Build + Install (Android, Windows)

PowerShell note: use `;` to chain commands.

### Debug APK

```powershell
cd apps/host
flutter build apk --debug
adb install -r "build\app\outputs\flutter-apk\app-debug.apk"
```

### Release APK

```powershell
cd apps/host
flutter build apk --release
adb install -r "build\app\outputs\flutter-apk\app-release.apk"
```

## Persistence note (important)

Host startup must run `Hive.initFlutter()` before `PersistenceService.init()`.

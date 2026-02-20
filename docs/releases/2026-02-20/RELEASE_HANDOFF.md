# Release Handoff — 2026-02-20

## Scope

This handoff captures today’s production-ready build/deploy outputs for:

- Player web app (Firebase Hosting)
- Host release APK

## Repository State

- Repository: `kimroutley/cb-reborn`
- Branch: `main`
- Date: 2026-02-20

## Build/Deploy Outcomes

### 1) Player Web (Firebase)

- Build target: `apps/player/build/web`
- Deployment target: Firebase Hosting project `cb-reborn`
- Hosting URL: <https://cb-reborn.web.app>
- Deploy status: ✅ Successful

### 2) Host Android APK (Release)

- Build target: `apps/host`
- Output artifact: `apps/host/build/app/outputs/flutter-apk/app-release.apk`
- Approx. size: `177.4 MB`
- Build status: ✅ Successful

## Notable Fix Applied During Release

A compile blocker in shared UI package was resolved:

- File: `packages/cb_theme/lib/src/widgets/chat_bubble.dart`
- Change: Restored missing `timestamp` field/constructor param in `CBMessageBubble`.
- Reason: Player app compile/tests and web build were failing due to references to `timestamp` in bubble rendering.

## Host APK Packaging Note (Gradle)

Initial host APK build failed at `:app:packageRelease` due to a missing baseline profiles output directory.

Workaround used successfully:

- Created directory:
  - `apps/host/build/app/outputs/apk/release/baselineProfiles`
- Re-ran release APK build.

Result after workaround: build succeeded and produced `app-release.apk`.

## Credentials / Deployment Context

- Firebase deploy used service account from:
  - `C:\Club Blackout Reborn\.secrets\firebase-adminsdk.json`
- Deploy script path:
  - `scripts/deploy_firebase.ps1`

## Recommended Follow-up

1. Commit the `CBMessageBubble` `timestamp` restoration change.
2. (Optional) Add a durable Gradle-side fix so `baselineProfiles` directory creation is not required manually for future release builds.
3. Tag this release after smoke verification on:
   - Player web at `https://cb-reborn.web.app`
   - Host APK install/run sanity check on target device.

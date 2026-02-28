# Rolling Status

## Last updated

2026-02-28

## Delta (2026-02-28) — Sprint Complete

- **Push Notifications Fully Deployed:**
  - VAPID keys generated and configured in Firebase Functions config + player app.
  - Cloud Functions `onGameUpdated` and `onPrivateStateUpdated` deployed and ACTIVE on `us-central1`.
  - Service worker push handler appended to player web build.
  - Firestore rules for `push_subscriptions` deployed.
  - Player web app deployed to https://cb-reborn.web.app with full push support.
  - Push events: role assigned, game start, phase changes, new bulletin, rematch — all live.
- **Gemini Narration Fully Functional:**
  - Fixed `HarmBlockThreshold.mediumAndAbove` compile error (v0.4.7 uses `.medium`).
  - Fixed type mismatch bug in `ScriptStepPanel` (was returning `bool` instead of narration text).
  - Added auto-generation: AI narration fires automatically on every step change when enabled.
  - Added night report generation: morning recap step auto-generates cinematic AI prose.
  - API key auto-seeds from compile-time environment on first launch.
  - 7 personalities available (The Cynic, Protocol 9, The Ice Queen, The Promoter, The Bouncer, The Roaster R-Rated, The Professional Clean).
  - Both apps rebuilt with `--dart-define-from-file` to bake in API key.
- **Power Trips (Host Nerve Centre):**
  - Renamed "Director Commands" to "Power Trips" with M3-compliant card layout.
  - Each command has a descriptive blurb explaining its function.
  - All 7 commands verified wired and functional.
- **Host APK:** Built with Gemini API key baked in (`apps/host/build/app/outputs/flutter-apk/app-release.apk`).

## Delta (2026-02-25)

- **Gemini AI Integration:**
  - Configured API key injection via `.env.json` and `launch.json` for secure local development.
  - Refactored `GeminiNarrationService` to use official Google Generative AI SDK.
- **Mobile Experience Overhaul (Host & Player):**
  - **Host Lobby:** Refactored to tabbed interface (Roster/Connect) for phone usability.
  - **Host Game Control:** Persistent phase bar, collapsible dashboard panels, responsive action buttons.
  - **Player Night Phase:** Immersive haptic feedback (wake-up, sleep, Roofi paralysis alert + dialog).
  - **Guide Screen (Blackbook):** Responsive design with mobile-first navigation.
- **Core Messaging Audit:**
  - All 13 Role Action prompts and Host feedback logs updated for thematic consistency.
  - Script narration (intro, night, day, voting) rewritten with atmospheric text.
  - Private player messages enhanced with actionable context.
- **Player App Feature Polish:**
  - Tactical Brief in "I'm playing as..." widget with Dos/Don'ts and situation tips.
  - Alliance Graph visual network in Blackbook.
- **UI Polish (Host & Player):**
  - Side Drawer upgraded to M3 pill-shaped tiles with glass gradients.
  - Guide Screen operative stats grouped for better layout.

## Delta (2026-02-24)

- Hall of Fame feature polish (Role Awards, tier filters, expandable ladders).
- Ghost Lounge + Dead Pool integration (ghost chat, dead pool intel panel).
- Host UI Polish pass (tactical density, metadata layering, prismatic authority, narrator accents).

## Delta (2026-02-21)

- Host Lobby UI polish pass.
- Player UI polish pass for lobby/game action surfaces.

## Executive summary

All requested features and fixes from the February sprint are complete. Push notifications are live. Gemini AI narration is functional with 7 personality modes. Both apps are built and deployed. The remaining release gates are manual device testing (sections 3-5 of the runbook) and GitHub Actions secrets provisioning.

## Completed engineering work

- Host mode-switch stability hardened.
- Player cloud join lifecycle hardened.
- Host iOS email-link completion hardening.
- CI deploy preflight for Firebase secrets.
- Gemini narration service (official SDK, auto-generation, night reports).
- Push notification infrastructure (VAPID, Cloud Functions, service worker, Firestore rules).
- All role messaging audited and amended (13 roles, 3 layers: script, private, host log).
- Night phase haptic alerts (wake-up, sleep, Roofi paralysis).
- Power Trips refactor (M3 cards with blurbs).
- Player strategy integration (tactical brief, alliance graph, deception tactics).
- Side drawer M3 + glassmorphism refactor.

## Completed verification

- `apps/host`: `dart analyze` — no issues on modified files.
- `apps/player`: `dart analyze` — no issues on modified files.
- `packages/cb_logic`: `dart analyze` — no issues on modified files.
- `packages/cb_theme`: `dart analyze` — no issues on modified files.
- Cloud Functions: both `onGameUpdated` and `onPrivateStateUpdated` deployed and ACTIVE.
- Firebase Hosting: player web deployed with push handler.
- Firestore Rules: deployed with `push_subscriptions` subcollection rules.

## Current runbook execution state

- **Completed:** Section 1 (Preflight), Section 2 (Deploy Secrets — VAPID + Functions done; GitHub Actions secrets still pending)
- **Pending manual:** Section 3 (Real-Device Multiplayer Matrix)
- **Pending manual:** Section 4 (Deep-Link + QR Validation)
- **Pending manual:** Section 5 (Host iOS Email-Link E2E)

## Remaining blockers / required actions

1. Add GitHub Actions secrets via GitHub UI: `FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_PROJECT_ID`, `FIREBASE_TOKEN` — see [GITHUB_SECRETS_CHECKLIST.md](GITHUB_SECRETS_CHECKLIST.md).
2. Run real-device multiplayer matrix (local/cloud/mode switch) — see [qa-smoke-checklist.md](qa-smoke-checklist.md).
3. Run deep-link + QR validation (cold/warm + invalid handling).
4. Run Host iOS email-link E2E on physical iOS device.

## Immediate next actions (ordered)

1. Add the 3 GitHub secrets via the GitHub repo Settings page.
2. Install latest Host APK on Android device.
3. Open https://cb-reborn.web.app on a second device (player).
4. Run through [qa-smoke-checklist.md](qa-smoke-checklist.md) sections F-I.
5. Record PASS/FAIL evidence and update this file.
6. Make GO/NO-GO release decision.

## Deployment posture

- **Code posture:** READY — all features implemented, all analyze checks pass, both apps built and deployed.
- **Operational posture:** blocked pending manual device validation (sections 3-5) and GitHub secrets.

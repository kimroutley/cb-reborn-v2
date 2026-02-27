# Rolling Status

## Last updated

2026-02-24

## Delta (2026-02-25)

- **Gemini AI Integration:**
  - Configured API key injection via `.env.json` and `launch.json` for secure local development.
  - Updated `ScriptStep` logic to support AI variations (ready for runtime implementation).
- **Mobile Experience Overhaul (Host & Player):**
  - **Host Lobby:** Refactored to tabbed interface (Roster/Connect) for better phone usability.
  - **Host Game Control:** Implemented persistent phase bar, collapsible dashboard panels, and responsive action buttons for mobile "Command Center" feel.
  - **Player Night Phase:** Added immersive haptic feedback (wake-up vibration, sleep confirmation, Roofi paralysis alert + dialog).
  - **Guide Screen (Blackbook):** Refactored for responsive design with mobile-first navigation (bottom nav, modal sheets).
- **Core Messaging Audit:**
  - Audited and updated all 13 Role Action prompts and Host feedback logs for thematic consistency and clarity.
- **Player App Feature Polish:**
  - **Tactical Brief:** Added "Dos and Don'ts" and situation tips to the "I'm playing as..." widget (`BiometricIdentityHeader`), revealing a summarized strategy guide on long-press.
  - **Alliance Graph:** Added a visual network graph (`AllianceGraphView`) to the `RoleStrategySheet` (Blackbook), replacing the text list of allies/threats.
- **UI Polish (Host & Player):**
  - **Side Drawer:** Upgraded to Material 3 pill-shaped tiles with refined glass gradients.
  - **Guide Screen:** Grouped operative stats in `CBGuideScreen` for better layout and alignment.
- **Backend / AI:**
  - **Gemini Runtime:** Refactored `GeminiNarrationService` to use the official Google Generative AI SDK, implemented robust error handling, safety settings, and prompt logic.
- **Documentation:**
  - Created comprehensive `docs/INDEX.md` mapping the entire repository.
  - Created `packages/cb_comms/README.md`.

## Delta (2026-02-24)

- **Hall of Fame feature polish completed:**
  - Rebuilt `HostHallOfFameScreen` from simple StatsView wrapper to full-featured Role Awards screen with overview stats, role/tier filters, and expandable award ladders with unlock status + tier-colored `CBMiniTag` indicators.
  - Upgraded Player `HallOfFameScreen` role award cards with tap-to-expand award ladder UI (lock/unlock icons, tier colors, award descriptions).
  - Fixed `DropdownButtonFormField` parameter bug (changed `initialValue` to `value`) in Player HoF filters.
  - Added Role Awards count to Host `StatsView` overview header.
- **Ghost Lounge + Dead Pool integration completed:**
  - Added Ghost Chat UI panel to `GhostLoungeView` (text input + message list for dead-player-to-dead-player chat).
  - Wired `sendGhostChat` bridge action through `GhostLoungeContent` in the Player app.
  - Created `DeadPoolIntelPanel` for Host Nerve Center dashboard showing active bets grouped by target, bettor names, and ghost comms intercept preview.
  - Upgraded `HostChatView` to tabbed interface: LIVE FEED + GHOST COMMS with badge count, ghost message parsing, and `CBMiniTag(GHOST)` indicators.
  - Wired `DeadPoolIntelPanel` into `DashboardView` (auto-hides when no dead players).
- **Host UI Polish pass completed:**
  - Implemented Tactical Information Density in Host Feed via `isCompact: true`.
  - Added Live Metadata Layering using `CBMiniTag` in Host Feed (GHOSTED, DEAD, SIN BIN, MUTED).
  - Enforced Prismatic Authority for system messages using `isPrismatic`.
  - Enabled Direct Action Integration with `showMessageContextActions` inside the Feed.
  - Added Narrator-Specific Accents (color shifting based on active `hostPersonalityId`).
  - Enhanced Phase Dividers using `CBFeedSeparator(isCinematic: true)`.

## Delta (2026-02-21)

- Host Lobby UI polish pass completed (visual hierarchy, QR usability, bottom controls, micro-motion).
- New targeted QA artifact added: `docs/operations/host-lobby-ui-qa-2026-02-21.md`.
- Host verification rerun: `apps/host -> flutter analyze .` ✅ (no issues).
- Player UI polish pass completed for lobby/game action surfaces (status panel, action bars, readability tune).
- Player connect/claim entry surfaces received follow-up polish (uplink status, identity selection clarity).
- New targeted QA artifact added: `docs/operations/player-ui-polish-qa-2026-02-21.md`.
- Player verification rerun: `apps/player -> flutter analyze .` ✅ (no issues).

## Executive summary

Runbook execution continued in this workspace and compile drift was remediated. Host and player test suites now pass locally. Remaining release blockers are operational/manual gates (GitHub secrets provisioning + real-device validations).

## Completed engineering work

- Host mode-switch stability hardened (defensive bridge reset strategy).
- Player cloud join lifecycle hardened (first-snapshot gating + timeout path).
- Host iOS email-link completion hardening added (latest-link tracking + timeout).
- CI deploy preflight added for required Firebase secrets.

## Completed verification

- Operational runbook and reporting templates created:
  - `docs/operations/TODAYS_RUNBOOK_2026-02-20.md`
  - `docs/operations/STATUS_UPDATE_TEMPLATE_2026-02-20.md`
- Runbook execution log captured:
  - `docs/operations/runbook-execution-2026-02-20.md`
- Preflight baseline executed:
  - branch: `main` (pass)
  - sync: `origin/main...HEAD = 0 0` (pass)
  - clean workspace: fail (dirty tree)
- Local verification executed (current workspace state):
  - `apps/host`: `flutter test` pass ✅
  - `apps/player`: `flutter test` pass ✅
  - `apps/player`: analyze now down to informational/deprecation items (no compile errors)

## Current runbook execution state

- **Completed:** Section 1 (Preflight, partial fail due dirty tree)
- **Blocked:** Section 2 (Deploy Secrets Provisioning; `gh` CLI unavailable in this environment)
- **Not started:** Sections 3–5 (multiplayer matrix, deep-link/QR, Host iOS email-link E2E)

## Remaining blockers / required actions

1. Restore clean/compilable workspace state (shared + app compile drift): ✅ resolved in-session.
2. Provision missing deploy secrets: `FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_PROJECT_ID`, `FIREBASE_TOKEN`.
3. Run real-device multiplayer matrix (local/cloud/mode switch).
4. Run deep-link + QR validation (cold/warm + invalid handling).
5. Run Host iOS email-link E2E on physical iOS device.

## Immediate next actions (ordered)

1. Compile gate rerun: ✅ complete (`flutter test` passes in both apps).
2. **Follow [LETS_DO_IT_RUNBOOK.md](LETS_DO_IT_RUNBOOK.md)** for: secrets provisioning, VAPID/push setup, and real-device validation.
3. Complete secrets provisioning (GitHub UI or machine with `gh`) and rerun CI preflight.
4. Execute runbook Sections 3–5 with device evidence capture via `STATUS_UPDATE_TEMPLATE_2026-02-20.md`.

## Deployment posture

- **Code posture:** unblocked for local test gate (host/player test suites passing).
- **Operational posture:** blocked pending secrets provisioning and manual validation.
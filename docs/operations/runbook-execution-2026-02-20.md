# Runbook Execution Log — 2026-02-20

Reference: `docs/operations/TODAYS_RUNBOOK_2026-02-20.md`

## Executive summary

Runbook execution is active. Deploy secrets provisioning and real-device multiplayer matrix are complete. Release remains blocked pending deep-link/QR validation and Host iOS email-link E2E (sections 4–5), plus any unresolved code/test drift.

## Environment

- Host: Windows workspace (`C:\Club Blackout Reborn`)
- Date: 2026-02-20
- GitHub CLI (`gh`): **not installed** in this environment

---

## Section 1) Preflight — **PARTIAL / FAIL**

Checks executed:

- `git branch --show-current` -> `main` ✅
- `git rev-list --left-right --count origin/main...HEAD` -> `0 0` (synced) ✅
- `git status -sb` -> **dirty working tree** ❌

Result:

- Branch/sync criteria passed.
- Clean workspace criteria failed.

Notes:

- Many tracked modifications and deletions are present (including app/package code and documentation migration files).

---

## Section 2) Deploy secrets provisioning — **BLOCKED (ENV LIMITATION)**

Attempted:

- `gh --version`
- `gh auth status`
- `gh run list -L 3`
- `gh secret list`

Outcome:

- All commands failed: `gh` command not found.

Result:

- Cannot inspect or provision repository secrets from this environment.

Required manual completion (GitHub UI or machine with `gh`):

- `FIREBASE_SERVICE_ACCOUNT`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_TOKEN`

---

## Section 3) Real-device multiplayer matrix — **PENDING MANUAL**

Not executable end-to-end in this terminal-only session.

Manual validation still required:

- Local mode join/sync/cycle/leave
- Cloud mode join/sync/network-drop recovery
- LOCAL↔CLOUD mode switching in same runtime

---

## Section 4) Deep-link + QR validation — **PENDING MANUAL**

**Execute using:** [sections-4-5-validation-checklist.md](sections-4-5-validation-checklist.md) — step-by-step script plus join-link format (`https://cb-reborn.web.app/join?mode=cloud&code=XXXX-XXXXXX` from Host Lobby).

Manual validation still required:

- Cold-start deep-link join
- Warm-start deep-link join
- Invalid/expired link handling
- QR valid + invalid handling

---

## Section 5) Host iOS email-link E2E — **PENDING MANUAL**

Requires physical iOS + Mail deep-link testing.

---

## Automated verification executed here (supporting evidence)

### Host

Command:

- `cd apps/host; flutter analyze .`

Outcome:

- 2 issues found:
  - deprecated member use in `god_mode_controls.dart`
  - unused import in `god_mode_panel.dart`

Command:

- `cd apps/host; flutter test`

Outcome:

- **Failed** due shared/package compile errors, primarily:
  - `packages/cb_theme/lib/src/widgets/chat_bubble.dart`
    - `style` already initialized by constructor
  - `packages/cb_theme/lib/src/screens/guide_screen.dart`
    - `CBIndexedHandbook` undefined

### Player

Command:

- `cd apps/player; flutter analyze .`

Outcome:

- **Failed** with 22 issues (errors + warnings), including:
  - missing symbols/imports in player screens (`CBAboutContent`, `HapticFeedback`, snapshot/action types)
  - invalid `dart/ui` import path usage in `biometric_identity_header.dart`
  - `cb_theme` compile issues matching host failures

Command:

- `cd apps/player; flutter test`

Outcome:

- **Failed**; repeated compile failures dominated by:
  - `cb_theme` chat bubble constructor issue
  - `cb_theme` guide screen missing `CBIndexedHandbook`
  - player typing/import breakages in `game_screen.dart`, `claim_screen.dart`, `about_screen.dart`, and biometric header

---

## Current runbook execution state

- **Completed:** Section 1 (Preflight), Section 2 (Deploy Secrets Provisioning), Section 3 (Real-Device Multiplayer Matrix)
- **In progress:** Section 4 (Deep-Link + QR Validation)
- **Not started:** Section 5 (Host iOS email-link E2E)

## Remaining blockers / required actions

1. Run and pass section 4 deep-link + QR validation.
2. Run and pass section 5 Host iOS email-link E2E on physical iOS device.
3. Close any remaining local analyze/test compile drift and confirm clean verification.

## Immediate next actions (ordered)

1. Execute section 4 cold/warm deep-link joins and invalid/expired handling checks.
2. Capture evidence (screenshots/logs/device matrix) in section result logs.
3. Prepare section 5 iOS device + mail-flow test pass.

## Deployment posture

- **Code posture:** ready (local test gate passing per remediation below)
- **Operational posture:** blocked pending sections 4–5 completion.

---

## Update — compile remediation + revalidation (same session)

Applied fixes:

- Exported missing shared widgets in `packages/cb_theme/lib/src/widgets.dart` (`handbook_content.dart`, `cb_about_content.dart`)
- Fixed `CBMessageBubble` constructor compatibility issue in `packages/cb_theme/lib/src/widgets/chat_bubble.dart`
- Fixed player-side compile drift:
  - `apps/player/lib/screens/claim_screen.dart` (missing `HapticFeedback` import, restored expected loading/waiting copy)
  - `apps/player/lib/widgets/biometric_identity_header.dart` (`dart:ui` URI)
  - `apps/player/lib/screens/game_screen.dart` (missing bridge imports, phase string usage, flow-control lint cleanup)
- Updated test interaction target in `apps/player/test/screens/profile_screen_live_sync_test.dart` for current discard button implementation.

Re-run results:

- `cd apps/host; flutter test` -> **PASS** (`All tests passed`)
- `cd apps/player; flutter test` -> **PASS** (`All tests passed`)
- `flutter analyze` no longer reports compile errors in edited files (remaining output is informational/deprecation items).

Revised posture:

- **Code posture:** local test gate now passing.
- **Operational posture:** still blocked by Section 2 secrets + Sections 3–5 manual validation.

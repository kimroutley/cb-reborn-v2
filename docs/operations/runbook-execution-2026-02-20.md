# Runbook Execution Log — 2026-02-20

Reference: `docs/operations/TODAYS_RUNBOOK_2026-02-20.md`

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

Not executable end-to-end in this terminal-only session.

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

## Current release posture from this execution

- **Code posture:** at risk in current workspace state (analyze/test failures observed)
- **Operational posture:** blocked (manual matrix + iOS E2E + secrets provisioning)

---

## Immediate next actions

1. Restore clean working tree baseline (or split/stash non-release edits).
2. Fix shared `cb_theme` compile blockers first:
   - `chat_bubble.dart` constructor style assignment
   - `guide_screen.dart` `CBIndexedHandbook` reference
3. Fix player compile/type/import drift next:
   - `about_screen.dart`, `claim_screen.dart`, `game_screen.dart`, `biometric_identity_header.dart`
4. Re-run:
   - `cd apps/host; flutter analyze .; flutter test`
   - `cd apps/player; flutter analyze .; flutter test`
5. Execute manual runbook Sections 3–5 on real devices.
6. Provision deploy secrets via GitHub UI.

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

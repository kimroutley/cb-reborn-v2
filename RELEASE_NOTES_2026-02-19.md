# Release Notes — 2026-02-19

## Highlights

This release delivers the complete role-awards follow-through plus profile/navigation hardening across Host and Player, with deterministic award progression, safer profile editing flows, and stronger UI test coverage.

## Included Changes

### Role Awards foundation + progression hardening

- Implemented canonical role-award ladders and catalog coverage for all roles.
- Added deterministic role-award progress rebuild/query flows in persistence.
- Added Host + Player Hall of Fame role-award surfaces and unlock summaries.
- Added role/tier award filters in Hall of Fame for both apps.
- Introduced role-specific unlock profiles (`gamesPlayed`, `wins`, `survivals`) replacing one global threshold pattern.
- Added icon-source guardrails in award catalog tests (unknown sources now fail tests).

### Player startup/auth + About surfaces

- Added neutral auth boot state (`SYNCING SESSION...`) to reduce startup flash.
- Added bootstrap progress meter with step/status progression.
- Added shared release-notes model and recent-builds metadata feed.
- Added shared About content component used by Host + Player.

### Profile UX and drawer navigation safety

- Refined Host + Player profile forms with stronger sanitization/validation flows.
- Added shared profile action button components (Save/Discard/Reload).
- Added unsaved-edit dirty-state guard providers for Host + Player.
- Updated Host + Player drawers to prompt before leaving Profile with unsaved changes.

### Test and docs coverage

- Added Hall-of-Fame access tests for both Host and Player.
- Added drawer unsaved-changes widget tests for both Host and Player.
- Added profile action button widget tests (Player).
- Updated planning/context documentation and consolidated PR summary.

## Commit Train (feature slice)

- `a402bcd` feat(awards): implement role award ladders, progress tracking, and hall of fame coverage
- `d7bd7d7` feat(awards): add role/tier filters and role-specific unlock profiles
- `64ee509` feat(player): improve bootstrap/auth loading and add shared about release notes
- `7880314` refactor(awards): simplify icon metadata seed handling
- `2cef390` feat(profile): harden form validation and refresh host/player profile UX
- `8553e0c` feat(theme): make about updates expandable and add widget coverage
- `ffc379b` feat(awards): add icon-source guardrails and update rollout docs
- `a8643d1` test(docs): add hall-of-fame access coverage and refresh PR summary
- `ee224e6` feat(profile): guard unsaved edits in drawers and add action-button components

## Validation Snapshot

- Full app verification
  - `apps/host`: `flutter analyze .` ✅, `flutter test` ✅
  - `apps/player`: `flutter analyze .` ✅, `flutter test` ✅

- Focused package checks
  - `packages/cb_models`: award catalog + release-notes tests ✅
  - `packages/cb_comms`: profile form validation tests ✅
  - `packages/cb_theme`: about widget tests ✅

- Focused regression checks
  - Host/Player Hall-of-Fame access tests ✅
  - Host/Player drawer unsaved-change guard tests ✅

## Notes

- About screens continue to source recent build metadata from structured package data.
- Latest updates presentation remains intentionally capped to recent entries for readability.
- Award icon-source metadata now has explicit guardrails to prevent silent catalog drift.

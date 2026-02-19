# 🏆 Role Awards + Profile UX + About Surface Consolidation

## Summary

This PR completes the role-awards follow-through and folds in adjacent UX hardening for Profile, About, and Hall-of-Fame access paths across Host + Player.

Primary outcomes:

- filterable Role Awards experience in Hall of Fame,
- deterministic role-specific unlock profiles with icon-source guardrails,
- improved Player startup/auth loading transitions,
- upgraded Host/Player Profile forms with stronger validation and save semantics,
- shared About/release-notes presentation with widget coverage,
- direct Hall-of-Fame access actions verified by dedicated app tests.

## What Changed

### 1) Role Awards progression, filtering, and metadata guards

- Host + Player Hall of Fame role-award views now support:
  - role filter,
  - tier filter,
  - filtered count/unlock summaries.
- Role ladders use role-specific deterministic unlock profiles (`gamesPlayed`, `wins`, `survivals`) instead of one global threshold profile.
- Added icon-source guardrail helpers in `role_award_catalog`:
  - known-source validation,
  - test-failing detection for unknown icon sources.
- Docs updated to reflect metadata automation and guard expectations.

### 2) Player startup/auth flow polish

- `AuthNotifier` startup behavior now transitions through explicit loading for existing authenticated sessions.
- `PlayerAuthScreen` includes a neutral boot state (`SYNCING SESSION...`) for `AuthStatus.initial`.
- `PlayerBootstrapGate` adds visible progress (units, percentage, and incremental status updates).

### 3) Profile workflow hardening (Host + Player + comms)

- Added shared form validation utility:
  - `packages/cb_comms/lib/src/profile_form_validation.dart`
- Exported validation utility from comms barrels.
- Profile screens (Host + Player) now include:
  - richer field validation and sanitization,
  - dirty-state awareness with save/discard UX,
  - better focus/input behavior,
  - profile style/avatar interactions with enabled/disabled semantics while saving.
- Repository updates in `ProfileRepository` now properly delete optional profile fields when cleared.

### 4) About/release-notes surface and test coverage

- Shared About content widget now uses expandable updates presentation.
- Added widget test coverage for `CBAboutContent` behavior and update list constraints.

### 5) Hall-of-Fame entry-point access tests

- Added app-level tests verifying Hall-of-Fame navigation entry points:
  - Host Home quick action -> Hall of Fame destination
  - Player Stats action -> Hall of Fame destination

## Commits Included

- `d7bd7d7` feat(awards): add role/tier filters and role-specific unlock profiles
- `64ee509` feat(player): improve bootstrap/auth loading and add shared about release notes
- `7880314` refactor(awards): simplify icon metadata seed handling
- `2cef390` feat(profile): harden form validation and refresh host/player profile UX
- `8553e0c` feat(theme): make about updates expandable and add widget coverage
- `ffc379b` feat(awards): add icon-source guardrails and update rollout docs

## Validation

- Analyze
  - `apps/player`: `flutter analyze .` -> **No issues found**
  - `apps/host`: `flutter analyze .` -> **No issues found**

- Focused tests
  - `apps/player/test/onboarding_loading_states_test.dart` ✅
  - `apps/player/test/player_home_shell_navigation_test.dart` ✅
  - `apps/host/test/hall_of_fame_access_test.dart` ✅
  - `apps/player/test/hall_of_fame_access_test.dart` ✅
  - `packages/cb_models/test/role_award_catalog_test.dart` ✅
  - `packages/cb_models/test/app_release_notes_test.dart` ✅
  - `packages/cb_comms/test/profile_form_validation_test.dart` ✅
  - `packages/cb_theme/test/widgets/cb_about_content_test.dart` ✅

## Why This Matters

- Improves visibility and control over award progression while preserving deterministic computation.
- Adds safety rails to prevent icon metadata drift as the catalog evolves.
- Reduces startup/auth visual churn for players.
- Strengthens profile data integrity and UX consistency across Host/Player.
- Consolidates About/release-note rendering and testing in shared layers.


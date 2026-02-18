# 🏆 Role Awards Filters + Player Bootstrap/Auth/About UX Polish

## Summary

This PR ships the follow-up iteration after the role-awards foundation:

- adds **Role/Tier filters** to Host + Player Hall of Fame role-award views,
- introduces **role-specific deterministic unlock profiles** for award ladders,
- improves Player startup UX with a **neutral auth boot state** and **bootstrap progress meter**,
- adds shared **About + release notes** surfaces for Host and Player,
- and finalizes a small awards metadata refactor for cleaner catalog seeding.

## What Changed

### 1) Role Awards: filtering + profile-based progression

- Host and Player Hall of Fame now support:
  - role filter (`All roles` or a specific role),
  - tier filter (`All tiers`, `Rookie`, `Pro`, `Legend`, `Bonus`),
  - filtered role counts and filtered unlock counts.
- Role award cards now reflect current filter state (including a no-match message).
- `packages/cb_models/lib/src/data/role_award_catalog.dart` now uses per-role unlock profiles (metric + threshold) instead of one global threshold pattern.
- Rule-driven descriptions are generated from the unlock metric (`gamesPlayed`, `wins`, `survivals`) to remain deterministic and consistent.

### 2) Player startup/auth UX hardening

- `AuthNotifier` now returns/loading-transitions through a clearer startup sequence when an authenticated user already exists.
- `PlayerAuthScreen` now has a neutral **boot splash state** (`SYNCING SESSION...`) for `AuthStatus.initial`, avoiding login UI flash.
- `PlayerBootstrapGate` now tracks bootstrap progress with:
  - total/completed unit accounting,
  - visual progress bar + percentage,
  - incremental asset warmup progress text.

### 3) Shared About + release notes experience

- Added shared release-notes model + parser:
  - `packages/cb_models/lib/src/app_release_notes.dart`
  - `packages/cb_models/lib/src/data/app_recent_builds.json`
- Added shared themed About content widget:
  - `packages/cb_theme/lib/src/widgets/cb_about_content.dart`
- Integrated About screens:
  - Host `about_screen` now uses shared content + dynamic package/release data.
  - Player now has an About destination/screen with the same shared content pattern.

### 4) Small awards metadata refactor

- Simplified icon metadata seeding path in role-award catalog:
  - removed unused optional seed-level icon author/attribution/url fields,
  - normalized source URL usage,
  - kept attribution behavior deterministic for license-driven paths.

## Commits Included

- `d7bd7d7` feat(awards): add role/tier filters and role-specific unlock profiles
- `64ee509` feat(player): improve bootstrap/auth loading and add shared about release notes
- `7880314` refactor(awards): simplify icon metadata seed handling

## Validation

- `apps/player`: `flutter analyze .` → **No issues found**
- `apps/host`: `flutter analyze .` → **No issues found**
- `apps/player` tests:
  - `test/onboarding_loading_states_test.dart` ✅
  - `test/player_home_shell_navigation_test.dart` ✅
- `packages/cb_models` tests:
  - `test/role_award_catalog_test.dart` ✅
  - `test/app_release_notes_test.dart` ✅

## Why This Matters

- Gives Host/Player operators practical ways to inspect award progression by role and difficulty tier.
- Makes award progression more expressive without sacrificing deterministic replay/rebuild behavior.
- Removes startup/auth jank in Player by replacing transient UI flashes with explicit loading intent.
- Centralizes About/release-note rendering in shared packages, reducing future drift between Host and Player.

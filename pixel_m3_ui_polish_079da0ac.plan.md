---
name: Pixel M3 UI Polish
overview: Audit identified a handful of high-impact screens with Material 3 consistency and phone-layout polish opportunities. This plan focuses on replacing legacy Scaffold patterns, tightening responsiveness, and improving accessibility-sized touch/typography for Pixel 10 Pro.
todos:
  - id: migrate-legacy-scaffolds
    content: Migrate legacy screens to CBPrismScaffold for consistent M3/themed shell.
    status: completed
  - id: adaptive-bars
    content: Refactor host setup/lobby row bars to adaptive layouts without overflow.
    status: completed
  - id: dialog-sheet-unification
    content: Convert ad-hoc dialogs/sheets to themed helpers and consistent panel styles.
    status: completed
  - id: type-touch-polish
    content: Increase tiny label readability and enforce tap target minimums.
    status: completed
  - id: pixel-qa-pass
    content: Run targeted Pixel 10 Pro viewport QA across host/player critical screens.
    status: completed
isProject: false
---

# Pixel 10 Pro M3 Polish Plan

## Priority 1: Replace legacy screen shells with themed scaffolds

- Migrate legacy `Scaffold + AppBar + CBNeonBackground` screens to `CBPrismScaffold` for visual/system consistency:
  - [apps/player/lib/screens/connect_screen.dart](apps/player/lib/screens/connect_screen.dart)
  - [apps/player/lib/screens/games_night_screen.dart](apps/player/lib/screens/games_night_screen.dart)
  - [apps/player/lib/screens/games_night_recap_screen.dart](apps/player/lib/screens/games_night_recap_screen.dart)
  - [apps/player/lib/screens/host_overview_screen.dart](apps/player/lib/screens/host_overview_screen.dart)
  - [apps/host/lib/screens/games_night_recap_screen.dart](apps/host/lib/screens/games_night_recap_screen.dart)
  - [apps/host/lib/screens/dj_booth_view.dart](apps/host/lib/screens/dj_booth_view.dart)
  - [apps/host/lib/screens/guides/role_detail_screen.dart](apps/host/lib/screens/guides/role_detail_screen.dart)

## Priority 2: Fix responsive overflow risks in setup/lobby bars

- Refactor narrow-width `Row` layouts that can compress badly on phone widths with long localized labels and badges.
- Convert badge+CTA rows to `Wrap` or adaptive stacked layouts in:
  - [apps/host/lib/screens/host_game_setup_screen.dart](apps/host/lib/screens/host_game_setup_screen.dart) (`_RoleActionsBar`, `_SetupLaunchBar`)
  - [apps/host/lib/screens/host_lobby_screen.dart](apps/host/lib/screens/host_lobby_screen.dart) (`_LaunchBar`, `_NetworkBar`)

## Priority 3: Align dialogs and sheets with M3 + theme primitives

- Replace ad-hoc `AlertDialog` styling with themed dialog helper + panel components where appropriate.
- Update in:
  - [apps/player/lib/screens/game_screen.dart](apps/player/lib/screens/game_screen.dart) (`_showRoofiedDialog`)
  - [apps/host/lib/screens/settings_screen.dart](apps/host/lib/screens/settings_screen.dart) (`showModalBottomSheet` personality picker; add safe-area/drag/shape consistency with themed bottom sheet helper)

## Priority 4: Improve readability and touch ergonomics

- Increase very small UI text where possible (`fontSize` around 8-9) for status chips/progress bars on high-density devices.
- Ensure key tap targets are >=44dp for icon-only controls (notably compact icon rows in lobby/join cards).
- Focus areas:
  - [apps/host/lib/screens/host_game_screen.dart](apps/host/lib/screens/host_game_screen.dart) (`_RoleConfirmationBar` labels/chips)
  - [apps/host/lib/screens/host_lobby_screen.dart](apps/host/lib/screens/host_lobby_screen.dart) (`_GlassIconButton` compact tap targets)
  - [apps/host/lib/screens/host_game_setup_screen.dart](apps/host/lib/screens/host_game_setup_screen.dart) (small badge text in setup/launch bars)

## Priority 5: Scanner/connect visual consistency

- In scanner mode, replace hardcoded black/white typography treatment with theme-semantic surface/on-surface tones and existing themed containers where feasible.
- Keep QR scanning behavior unchanged while improving style cohesion in:
  - [apps/player/lib/screens/connect_screen.dart](apps/player/lib/screens/connect_screen.dart)

## Verification

- Run targeted visual QA on Pixel-sized viewport (portrait):
  - host lobby, host setup, host game tabs, player connect, player lobby, role reveal, recap screens.
- Check for:
  - No horizontal overflow warnings
  - Comfortable button/icon touch targets
  - Consistent themed surfaces and typography hierarchy
  - No regressions in existing join/setup/reveal/game flows.


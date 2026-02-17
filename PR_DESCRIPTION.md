# 🎭 Day Resolution Pipeline + Player Shell Navigation Guard

## Summary

This PR continues the role-mechanics parity hardening by moving more day-phase behavior into modular strategy handlers, adding explicit reactive-choice support for exiled reactive roles, and strengthening navigation regression coverage on the Player app shell.

## What Changed

### 1) Day resolution strategy and handler contracts (cb_logic)

- Expanded `DayResolutionContext` to carry explicit choice maps:

  - `predatorRetaliationChoices`
  - `teaSpillerRevealChoices`
  - `dramaQueenSwapChoices`

- Updated handlers/resolvers to consume these explicit host selections.
- `DayResolutionStrategy` now:

  - always includes the exile victim in `deathTriggerVictimIds`
  - deduplicates returned death-trigger IDs
  - preserves ordered handler execution with documented order contract

### 2) Provider orchestration cleanup (cb_logic)

- `game_provider.dart` now builds scoped reactive day steps for exiled:

  - Tea Spiller reveal
  - Drama Queen vendetta
  - Predator retaliation

- Choices are collected from `actionLog` and fed into `DayResolutionContext`.
- Removed duplicate in-provider exiled death-trigger scan and now relies on strategy output.
- Wallflower observation flow updated so:

  - `PEEKED` stores private dealer-target intel to Wallflower
  - `GAWKED` behavior remains state-driven and clears appropriately after resolution

### 3) Regression test expansion

- Added/updated tests for:

  - day strategy aggregation and handler order
  - explicit reactive target selection behavior (Tea Spiller / Drama Queen / Predator)
  - dead-pool settlement clear + win/loss outcomes
  - exiled player inclusion in death-trigger propagation
  - Wallflower observation intel and gawked reset behavior

### 4) Player app navigation guard

- Added `apps/player/test/player_home_shell_navigation_test.dart` to verify

  phase-driven destination syncing in `PlayerHomeShell` via active bridge state transitions.

### 5) Agent context docs

- Updated `AGENT_CONTEXT.md` with:

  - day-resolution barrel import guidance
  - reactive day choice step conventions
  - handler-order testing contract

## Commits Included (origin/main..HEAD)

- `cb3ab74` chore(cb_theme): clear remaining analyzer infos
- `4b8f0eb` feat: migrate host/player shell navigation and modularize day resolution engine
- `d65f1c5` fix(player): stabilize shell navigation and active bridge tests
- `987c235` refactor(cb_logic): modularize day resolution handlers
- `a64971a` test(player): add home shell phase-to-destination navigation coverage
- `fefe386` docs(agent): update context with day-resolution and shell architecture notes

## Validation

- Focused cb_logic suite: **85 passed, 0 failed**
- Full cb_logic suite: **305 passed, 0 failed**
- Additional local build checks (from session):

  - `apps/player` web build completed successfully
  - `apps/host` release APK build completed successfully

## Why This Matters

- Reduces provider-level brittleness by centralizing day-resolution behavior in dedicated strategy handlers.
- Makes reactive exiled-role outcomes explicit, testable, and easier to extend for future roles.
- Adds UI navigation guardrails to prevent regression in state-driven Player shell transitions.

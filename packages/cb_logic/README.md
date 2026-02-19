# cb_logic

The `cb_logic` package contains the core game engine and state transitions for Club Blackout Reborn.

## Features

### Core game logic

- Role assignment with balance constraints and required-role handling.
- Night resolution pipeline for blocks, protection, kills, and reactive role effects.
- Day vote resolution, exile outcomes, and win-condition checks.

### Scripting and narration

- Dynamic host script generation for setup, night, and day phases.
- Role-specific host prompts (including reactive/passive role support).
- Optional Gemini narration integration for themed recap output.

### State management

- `Game` provider for active match lifecycle.
- `GamesNight` provider for multi-game sessions.
- Chat/recap/analytics service integrations used by host/player apps.

### Utilities

- Player matching and lobby helpers.
- Recap/event formatting helpers.
- Strategy hint generation.

## Getting started

This package is intended to be used from the monorepo workspace.

Prerequisites:

- Flutter SDK version aligned with repository tooling docs.
- Dependencies installed from the repository root.

Typical workflow:

1. Open the monorepo root.
2. Install dependencies (`flutter pub get`).
3. Run tests from `packages/cb_logic`.

If model shapes or generated serialization code change, regenerate in the documented order:

1. `packages/cb_models`
2. `packages/cb_logic`
3. apps (`apps/host`, `apps/player`) as needed

## Usage

Use `GameResolutionLogic` for deterministic phase resolution from a `GameState`.

```dart
final result = GameResolutionLogic.resolveNightActions(gameState);
final playersAfterNight = result.players;
final hostReport = result.report;
```

## Additional information

For architecture and contribution context, see:

- `AGENT_CONTEXT.md`
- `COMPREHENSIVE_ROLE_MECHANICS.md`
- `packages/cb_logic/test/` for executable behavior examples

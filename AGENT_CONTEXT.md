# Club Blackout Reborn: Agent Context & Technical Reference

> **Authoritative Source for AI Agents & Developers**
> **Last Updated:** February 13, 2026

This document provides the deep technical context required to work on the Club Blackout Reborn monorepo without causing regressions. It supplements the `PROJECT_DEVELOPER_HANDBOOK.md` by focusing on architectural constraints, specific implementation patterns, and "gotchas".

---

## 1. Monorepo Structure & Environment

### Directory Layout
The project is a **Flutter Monorepo** structured as follows:

*   **`apps/`**: End-user applications.
    *   `host/`: The "Command Center" (Flutter Windows/Tablet).
    *   `player/`: The "Companion App" (Flutter Mobile/Web).
*   **`packages/`**: Shared local packages. **Strict dependency order matters.**
    *   `cb_models`: Core data models (Freezed), Enums, Role definitions. (Base)
    *   `cb_theme`: Design system, UI components, Assets. (Depends on `cb_models`)
    *   `cb_comms`: Networking, Firebase/WebSocket bridges. (Depends on `cb_models`)
    *   `cb_logic`: Game engine, State management, Riverpod providers. (Depends on `cb_models`, `cb_comms`)

### Build Environment
*   **Flutter SDK**: `3.35.0` or higher.
*   **Dart SDK**: `3.9.0` or higher.
*   **Code Generation**: Required for `freezed`, `json_serializable`, and `riverpod`.

### ⚠️ Critical Build Order
When modifying models or logic, you **must** run `build_runner` in the correct dependency order to avoid type errors in dependent packages.

1.  `packages/cb_models`: `dart run build_runner build --delete-conflicting-outputs`
2.  `packages/cb_logic`: `dart run build_runner build --delete-conflicting-outputs`
3.  `apps/host`: `dart run build_runner build --delete-conflicting-outputs`

*Note: `apps/player` does not currently use `build_runner` extensively but relies on the generated code from packages.*

---

## 2. Key Architectural Patterns

### State Management: Riverpod & Freezed
*   **Providers**: We use Riverpod 3.x.
*   **Immutability**: All game state is immutable via `freezed`.
*   **Updates**: Use `.copyWith()` for updates.
    *   **Sentinel Pattern**: In `PlayerGameState.copyWith`, use the `_undefined` sentinel object to distinguish between "keep existing value" (missing argument) and "clear value" (explicit `null`).

### Role Definitions: `RoleIds`
*   **Centralization**: Do **not** use magic strings for role IDs.
*   **Usage**: Use `RoleIds.medic`, `RoleIds.dealer`, etc., defined in `packages/cb_models`.
*   **Catalog**: `hostPersonalities` is a top-level constant in `cb_models`.

### Networking: The "Bridge" Pattern
The app supports dual-mode networking (Local WebSocket + Cloud Firestore), abstracted via `GameBridge` interfaces.

*   **CloudHostBridge (Host App)**:
    *   **Optimization**: Calculates a hash of the game state using `DeepCollectionEquality` and compares it with `_lastPublishedHash`.
    *   **Write Prevention**: Only writes to Firestore if the hash has changed to save costs and reduce latency.
*   **FirebaseBridge (Comms Package)**:
    *   **Batching**: Implements manual chunking (limit 500 operations) for large updates (e.g., `deleteGame`).
    *   **Atomicity**: `publishState` uses a single `WriteBatch` to commit public and private state updates simultaneously.

### Bot Simulation Architecture
*   **Model**: The `Player` model includes an `isBot` boolean field.
*   **Creation**: Bots are instantiated via `Game.addBot()` with unique IDs prefixed with `bot_` and robot-themed names.
*   **Execution**:
    *   **`Game.simulateBotTurns()`**: The central method for bot logic. It checks the current `ScriptStep`.
    *   **Voting**: If the step is `day_vote`, all eligible bots cast a random vote (or abstain) via `_simulateDayVotesForBots`.
    *   **Actions**: If the step targets a specific bot role (e.g., `medic_act_bot_1`), or a group role containing bots, `_performRandomStepAction` is triggered.
    *   **Constraint**: Bots respects game rules (silenced, sin-binned) just like human players.

---

## 3. Testing Strategy

### Unit Testing Constraints
*   **No Internet**: The sandbox has no internet access. You cannot run `flutter pub get` reliably. Rely on pre-installed dependencies.
*   **Execution**: Run tests from the **package root** (e.g., `cd packages/cb_logic; flutter test`).

### Mocking & Fakes
*   **Manual Mocks**: We mostly use manual mocks because `mockito` generation can be flaky in this complex monorepo setup.
*   **`visibleForTesting`**:
    *   `PlayerBridge` has a `mockClientFactory` static field. Set this to a function returning a `MockPlayerClient` before running tests.
    *   `CloudHostBridge` has a `debugFirebase` field for injecting a `MockFirebaseBridge`.

### Specific Test Cases
*   **HostOverviewScreen**: When testing widgets dependent on `playerBridgeProvider`, your `MockPlayerBridge` must extend `PlayerBridge` and override `build` to return a valid `PlayerGameState`, not `void`.
*   **Freezed Serialization**: When testing `fromJson`/`toJson` for complex nested lists (like `GameState`), use `jsonDecode(jsonEncode(obj.toJson()))` to verify full serialization cycles.

---

## 4. Known Issues & "Gotchas"

### Linting Strictness
*   **`duplicate_ignore`**: The CI fails if you have a file-level `// ignore_for_file: rule` AND a specific `// ignore: rule` on a line.
    *   *Action*: Remove the specific line ignore if the file-level ignore is present.
*   **Analyzer Errors**: "Target of URI doesn't exist" in `cb_models` often means stale build artifacts. Run `rm -rf packages/cb_models/build` if this persists.

### `json_serializable` Quirks
*   Nested lists of objects in `freezed` classes sometimes fail to cast correctly from `List<dynamic>` to `List<MyObject>` during `fromJson`.
*   *Workaround*: Ensure generated `.g.dart` files are up to date and clean.

---

## 5. Universal Interactive Role Framework (Mar 2026)

The game logic now uses a **Priority-Based Strategy Pattern** for resolving night actions. This replaced the monolithic and hardcoded `resolveNight` implementation.

### Key Components

*   **`NightResolutionContext`**: A mutable container passed through each action strategy. It collects reports, deaths, and redirects.
*   **`NightActionStrategy`**: An interface implemented by each role (e.g., `MedicAction`, `BartenderAction`).
*   **Scoped Interaction IDs**: All script step and action IDs follow the format `{role/step}_act_{playerId}_{dayCount}`. This prevents action "bleeding" between nights and allows for precise historical tracking.
*   **`DeathResolutionStrategy`**: A dedicated post-processing step that handles primary deaths (murder) and secondary chain reactions (Broken Heart, Second Wind, Medic Revives).

### ⚠️ Implementation Guidelines for New Roles

1.  **ID Parsing**: Always use `Game._extractScopedPlayerId(stepId)` in `game_provider.dart` to extract the actor from a scoped ID.
2.  **Action Keys**: Ensure the key generated in `role_logic.dart` (`buildStep`) matches the key checked in the `ActionStrategy` (packages/cb_logic).
3.  **Death Handling**: If adding a new role with death-prevention or reaction-on-death logic, implement a `DeathHandler` and register it in `DeathResolutionStrategy`.

---

## 6. Current Status Checklist (Feb 13, 2026)

### Verified (Stable)
- [x] **Universal Framework**: All roles transitioned to the new priority-based resolution engine.
- [x] **Stabilization Sweep**: Resolved logic regressions in Medic Revival, Clinger Bonds, and ID parsing for Day 1+ and Night 1+.
- [x] **Static Analysis**: `apps/host`, `apps/player`, and all `packages/` have 0 analyzer errors.
- [x] **Bot Simulation**: `addBot` and `simulateBotTurns` verified in `cb_logic`.
- [x] **Auth & Nav**: Streamlined flows and `NavigationDrawer` implemented.

### Pending Validation (Manual)
- [ ] **Cross-Device Multiplayer**: Verify Local vs Cloud mode switching on real devices.
- [ ] **Deep Links**: Verify "Join via URL" robustly handles app cold starts vs warm resumes.
- [ ] **Host Parity**: Ghost Lounge and Dead Pool integration needs UI polish.

---

## 7. Agent Directives

1.  **Read Context First**: Before starting any task, verify your understanding against this document.
2.  **Verify, Don't Assume**: After editing code, run `flutter test` in the relevant package.
3.  **Respect the Architecture**: Do not bypass `RoleIds` or direct Firestore calls outside the Bridges.
4.  **Update This Doc**: If you discover a new pattern or fix a critical bug, update this file.

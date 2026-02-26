# Club Blackout Reborn: Agent Context & Technical Reference

> **Authoritative Source for AI Agents & Developers**
> **Last Updated:** February 19, 2026 (UI Overhaul + Release Hardening)

This document provides the deep technical context required to work on the Club Blackout Reborn monorepo without causing regressions. It supplements the `PROJECT_DEVELOPER_HANDBOOK.md` by focusing on architectural constraints, specific implementation patterns, and "gotchas".

---

## 1. Visual Standards (The "Design Bible")

> **STOP:** Before writing any UI code, read **[`STYLE_GUIDE.md`](./style-guide.md)**.

*   **Do not use raw colors**: Always use `Theme.of(context).colorScheme` or `CBColors` from `cb_theme`.
*   **Do not use raw widgets**: Use shared components like `CBGlassTile`, `CBPanel`, and `CBPrismScaffold`.
*   **Aesthetic**: The app enforces a strict "Radiant Neon" terminal look. All screens must be dark, glassmorphic, and haptic-rich.

---

## 2. Monorepo Structure & Environment

### Directory Layout
The project is a **Flutter Monorepo** structured as follows:

*   **`apps/`**: End-user applications.
		*   `host/`: The "Command Center" (Flutter Phone/Android — benchmarked on Google Pixel 10 Pro).
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

## 3. Key Architectural Patterns

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

## 4. Testing Strategy

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

## 5. Known Issues & "Gotchas"

### Linting Strictness
*   **`duplicate_ignore`**: The CI fails if you have a file-level `// ignore_for_file: rule` AND a specific `// ignore: rule` on a line.
		*   *Action*: Remove the specific line ignore if the file-level ignore is present.
*   **Analyzer Errors**: "Target of URI doesn't exist" in `cb_models` often means stale build artifacts. Run `rm -rf packages/cb_models/build` if this persists.

### `json_serializable` Quirks
*   Nested lists of objects in `freezed` classes sometimes fail to cast correctly from `List<dynamic>` to `List<MyObject>` during `fromJson`.
*   *Workaround*: Ensure generated `.g.dart` files are up to date and clean.

---

## 6. Universal Interactive Role Framework (Mar 2026)

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

## 7. Current Status Checklist (Feb 19, 2026)

### Verified (Stable)
- [x] **Universal Framework**: All roles transitioned to the new priority-based resolution engine.
- [x] **Stabilization Sweep**: Resolved logic regressions in Medic Revival, Clinger Bonds, and ID parsing for Day 1+ and Night 1+.
- [x] **Static Analysis**: `apps/host`, `apps/player`, and all `packages/` have 0 analyzer errors.
- [x] **Package Health**: `packages/cb_logic` and `packages/cb_theme` full analyze + tests pass.
- [x] **Bot Simulation**: `addBot` and `simulateBotTurns` verified in `cb_logic`.
- [x] **Auth & Nav**: Streamlined flows and `NavigationDrawer` implemented.
- [x] **UI Polish**: Full implementation of "Radiant Neon" style guide.

### Pending Validation (Manual)
- [ ] **Cross-Device Multiplayer**: Verify Local vs Cloud mode switching on real devices.
- [ ] **Deep Links**: Verify "Join via URL" robustly handles app cold starts vs warm resumes.
- [ ] **Host Parity**: Ghost Lounge and Dead Pool integration needs UI polish.

---

## 8. Day Resolution Strategy & Wallflower Framework (Feb 18, 2026)

Following the success of the Night Resolution engine, the Day Resolution logic has been refactored into a **Strategy Pattern** to handle complex role interactions like Predator Retaliation and Drama Queen Swaps.

### Key Components

* **`DayResolutionStrategy`**: Coordinates a sequence of `DayResolutionHandler` objects.
* **Handlers**: Specialized logic for `DeadPool`, `TeaSpiller`, `DramaQueen`, and `Predator`.
* **`day_resolution.dart` barrel**: Prefer importing `src/day_actions/resolution/day_resolution.dart` when consuming strategy + context types to avoid scattered low-level imports.
* **Wallflower Framework**: The Wallflower role now has a specialized "Host Observation" step. The Host observes if the Wallflower "Peeked" or "Gawked" during the murder, leading to state-driven exposure (`isExposed`) and night report entries.
* **Reactive Choice Steps**: Exiled reactive roles may now insert scoped day prompts before final day resolution. `TeaSpiller` uses `tea_spiller_reveal_{playerId}_{day}`, `DramaQueen` uses `drama_queen_vendetta_{playerId}_{day}`, and `Predator` uses `predator_retaliation_{playerId}_{day}`; selections are collected from `actionLog` and fed into `DayResolutionContext`.

### ⚠️ Implementation Guidelines

1. **State Cleanliness**: Handlers should return a `DayResolutionResult` that explicitly signals if auxiliary state (like `deadPoolBets`) should be cleared.
2. **Chaining**: The order of handlers in `DayResolutionStrategy` matters. Drama Queen swaps should happen before Predator retaliation to ensure the correct "new" roles are targeted.
3. **Order Contract**: Keep handler-order behavior documented in `day_resolution_strategy.dart` and protected by `test/day_resolution_strategy_test.dart` when adding/reordering handlers.

---

## 9. Navigation & Shell Architecture (Feb 18, 2026)

Both Host and Player apps have migrated from imperative `Navigator.push` calls to a **State-Driven Shell Architecture**.

### The "Shell" Pattern

* **`HostHomeShell` / `PlayerHomeShell`**: These root widgets wrap a single `Scaffold` and `Drawer`.
* **Navigation Provider**: An enum-based StateNotifier (`HostNavigation` / `PlayerNavigation`) determines the active screen.
* **Reactive Transitions**: Screens switch automatically using `AnimatedSwitcher` when the navigation state or game phase changes.
* **Drawer Integration**: The `NavigationDrawer` (Host) and `CustomDrawer` (Player) now update the provider state instead of calling `Navigator`.

### The "ActiveBridge" Utility (Player App)

To simplify cross-mode development, the Player app uses `activeBridgeProvider`.

* **Abstraction**: It automatically watches either `cloudPlayerBridgeProvider` (Firestore) or `playerBridgeProvider` (WebSocket) and provides a unified interface.
* **Usage**: Screens like `GameScreen` and `LobbyScreen` should watch `activeBridgeProvider` to avoid redundant logic for checking connection modes.

---

## 10. Player Startup Cache & Resume (Feb 18, 2026)

The Player app now restores recent session state before login to reduce
reconnect friction and avoid re-downloading high-payload gameplay context after
an app restart.

### Key Components

* **`PlayerBootstrapGate`** (`apps/player/lib/bootstrap/player_bootstrap_gate.dart`):
	wraps `PlayerAuthScreen` and runs startup initialization before the main UI.
* **Bootstrap tasks**: initializes local persistence, applies Firestore offline
	cache settings (mobile), restores cached session state, and pre-caches
	critical visual assets.
* **`PlayerSessionCacheRepository`** (`apps/player/lib/player_session_cache.dart`):
	stores a compact `PlayerGameState` snapshot in `SharedPreferences` with an
	18-hour TTL.
* **Bridge persistence**:
	`PlayerBridge` and `CloudPlayerBridge` persist cache snapshots on join/state
	updates and clear cache on `leave()`.
* **Auth cleanup**: player sign-out clears cached session data.

### Resume Flow

1. Bootstrap loads cache and hydrates the matching bridge state (local/cloud).
2. Bootstrap seeds `pendingJoinUrlProvider` with `autoconnect=1`.
3. `HomeScreen` consumes pending join URL, applies join parameters, and
	 auto-connects without user re-entry.
4. Live sync then refreshes state from host/cloud as the source of truth.

### Testing Notes

* Keep cache writes resilient in non-widget unit tests. `SharedPreferences` can
	be unavailable before Flutter bindings are initialized.
* Avoid startup timers in bootstrap widgets to prevent `flutter_test` pending
	timer failures in smoke tests.

---

## 11. Agent Directives

1. **Read Context First**: Before starting any task, verify your understanding against this document.
2. **Verify, Don't Assume**: After editing code, run `flutter test` in the relevant package.

3. **Respect the Architecture**: Do not bypass `RoleIds` or direct Firestore calls outside the Bridges.
4. **Update This Doc**: If you discover a new pattern or fix a critical bug, update this file.


## 12. Role Awards Rollout (Feb 18, 2026)

Phase 0/1 scaffolding for Role Awards is now in place.

### Implemented foundation

* `packages/cb_models/lib/src/data/role_award_placeholders.dart` provides the canonical `Awards Coming Soon` placeholder registry for all canonical roles.
* `packages/cb_models/lib/src/persistence/role_awards.dart` defines the shared role-award domain models (`RoleAwardDefinition`, `PlayerRoleAwardProgress`, enums).
* `packages/cb_models/lib/src/data/role_award_catalog.dart` now provides generated baseline ladders for all canonical roles plus helper lookups (`roleAwardsForRoleId`, `hasFinalizedRoleAwards`, `roleAwardDefinitionById`).
* Role ladders now use deterministic **role-specific unlock profiles** (still based on currently supported aggregate metrics: `gamesPlayed`, `wins`, `survivals`) instead of one global threshold pattern.
* Icon metadata is now auto-populated for finalized awards: `iconUrl` is derived by icon source, and attribution fields are enforced for any future CC-BY licensed icon entries.
* `PersistenceService` now supports role-award progress rebuild + query flows (`rebuildRoleAwardProgresses`, by-player/by-role/by-tier, recent unlocks).
* Host + Player Hall of Fame screens render Role Award cards for every role and show finalized-role coverage + unlock counters.

### Maintenance rules

1. Keep role IDs canonical (`RoleIds` only), never display-name keyed.
2. If new roles are added to `role_catalog`, update both placeholder and finalized catalog coverage helpers.
3. Preserve fallback behavior: unresolved roles must display exactly `Awards Coming Soon` until finalized definitions are added.
4. Prefer adding finalized role ladders in `role_award_catalog.dart` incrementally without changing model contracts.
5. If adding a new icon source, update the icon-source URL map in `role_award_catalog.dart`; metadata tests now fail on unknown icon sources.

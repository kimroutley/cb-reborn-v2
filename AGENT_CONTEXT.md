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

### Dependency Injection (DI)
*   **GeminiNarrationService**: Accepts an optional `apiKey` in the constructor. In tests, inject a mock key or use `ProviderContainer` overrides.
*   **AnalyticsService**: Defines an abstract `AnalyticsProvider`. The concrete `FirebaseAnalyticsProvider` is injected at runtime, allowing tests to use `MockAnalyticsProvider`.

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

## 5. Current Status Checklist (Feb 13, 2026)

### Verified (Stable)
- [x] **Monorepo Structure**: Logic moved to `packages/`.
- [x] **Host App Build**: Release APK builds successfully.
- [x] **Player App Build**: Web build succeeds.
- [x] **Auth Flow**: Unified "Club Entry" flow (Google + Moniker) for both apps.
- [x] **Bot Simulation**: `addBot` and `simulateBotTurns` logic in `cb_logic`.

### Pending Validation (Manual)
- [ ] **Cross-Device Multiplayer**: Verify Local vs Cloud mode switching on real devices.
- [ ] **Deep Links**: Verify "Join via URL" robustly handles app cold starts vs warm resumes.
- [ ] **Host Parity**: Ghost Lounge and Dead Pool integration needs UI polish.

---

## 6. Agent Directives

1.  **Read Context First**: Before starting any task, verify your understanding against this document.
2.  **Verify, Don't Assume**: After editing code, run `flutter test` in the relevant package.
3.  **Respect the Architecture**: Do not bypass `RoleIds` or direct Firestore calls outside the Bridges.
4.  **Update This Doc**: If you discover a new pattern or fix a critical bug, update this file.

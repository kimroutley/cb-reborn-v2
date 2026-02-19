# Club Blackout Reborn: Actionable TODOs

This report consolidates development tasks, strategic goals, and code audit findings based on the current codebase state.

## 1. Strategic Roadmap (from README.md)

These are high-level feature requests and architectural improvements prioritized for the next release cycle.

-   **👻 Ghost Lounge + Dead Pool**
    -   **Task:** Implement a full player + host experience for eliminated players.
    -   **Status (Updated 2026-02-19):** Core flow implemented. Player dead-state now routes into a shared Ghost Lounge view with Dead Pool betting + live bet visibility, and Host dashboard surfaces active Dead Pool bets.
-   **💾 Multi-slot Save System**
    -   **Task:** Expand persistence beyond a single active recovery save.
    -   **Status (Updated):** Backend support appears implemented in `cb_logic` persistence layer; remaining work is UX surfacing/validation, not core storage.
-   **🧪 Real-device Multiplayer Validation**
    -   **Task:** Execute a validation checklist for local/cloud mode switching, deep-linking, and QR scanning on physical devices.
    -   **Status:** Manual validation required.
-   **🎭 Role Mechanics Parity Audit**
    -   **Task:** Audit `cb_logic` against `COMPREHENSIVE_ROLE_MECHANICS.md`.
    -   **Status:** In Progress (see Logic Gaps below).

## 2. QA & Validation (from PROJECT_DEVELOPER_HANDBOOK.md)

Specific validation steps required before release.

-   **Release-signing Secret Provisioning**: Ensure secrets are provisioned in GitHub environment for `main` branch enforcement.
-   **Host iOS Email Link Auth**: End-to-end verification of deep-link flow on iOS.

## 3. Logic Gaps & Audit Findings

Potential issues identified during code exploration.

-   **Drama Queen Night Death Trigger**:
    -   **Issue:** The `DramaQueen` role description states: "When killed, swap two cards...".
    -   **Finding (Updated 2026-02-19):** Implemented and validated. Added `DramaQueenDeathHandler` to night death resolution so a Drama Queen killed at night now triggers vendetta swaps.
    -   **Action:** ✅ Complete. Keep regression coverage in `packages/cb_logic/test/night_resolution_test.dart`.

-   **Passive Role Logic**:
    -   **Issue:** Verify handling of passive/reactive roles in Night Resolution.
    -   **Finding:** `DeathResolutionStrategy` correctly includes handlers for `Medic`, `SecondWind`, `SeasonedDrinker`, `AllyCat`, `Minor`, `Clinger`, and `Creep`.
    -   **Action (Updated):** `Wallflower` flow appears implemented with scripting + observation + reporting coverage; keep this as regression-watch rather than a blocking gap.

## 4. Documentation & Cleanup

Minor tasks to improve code hygiene.

-   **Package Boilerplate**:
    -   `packages/cb_logic/README.md`: ✅ Updated with concrete package guidance and usage.
    -   `packages/cb_theme/CHANGELOG.md`: ✅ Initial release notes added.
    -   **Action:** Complete.

## 5. Implicit Tasks

-   **Bot Simulation**: Ensure all new roles (e.g., `SecondWind`, `Creep`) have appropriate bot logic if `isBotFriendly` is true.

# Club Blackout Reborn: Actionable TODOs

This report consolidates development tasks, strategic goals, and code audit findings based on the current codebase state.

## 1. Strategic Roadmap (from README.md)

These are high-level feature requests and architectural improvements prioritized for the next release cycle.

-   **👻 Ghost Lounge + Dead Pool**
    -   **Task:** Implement a full player + host experience for eliminated players.
    -   **Status:** Pending. Dead players currently have limited interaction. Needs UI and logic.
-   **💾 Multi-slot Save System**
    -   **Task:** Expand persistence beyond a single active recovery save.
    -   **Status:** Pending. Backend requirement in `cb_logic`.
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
    -   **Finding:** `DramaQueenHandler` appears to be implemented only in `DayResolutionStrategy` (for exile). There is no obvious handler in `DeathResolutionStrategy` (Night). If a Drama Queen is killed at night, their ability may not trigger.
    -   **Action:** Verify if `DramaQueen` should trigger on night death and implement `DramaQueenDeathHandler` in `packages/cb_logic/lib/src/night_actions/resolution/` if needed.

-   **Passive Role Logic**:
    -   **Issue:** Verify handling of passive/reactive roles in Night Resolution.
    -   **Finding:** `DeathResolutionStrategy` correctly includes handlers for `Medic`, `SecondWind`, `SeasonedDrinker`, `AllyCat`, `Minor`, `Clinger`, and `Creep`.
    -   **Action:** Ensure `Wallflower` (witness murder) logic is correctly hooked into the murder event or notification system, as it is not a "death handler" but an information role.

## 4. Documentation & Cleanup

Minor tasks to improve code hygiene.

-   **Package Boilerplate**:
    -   `packages/cb_logic/README.md`: Contains default "TODO: List prerequisites" text.
    -   `packages/cb_theme/CHANGELOG.md`: Contains "TODO: Describe initial release".
    -   **Action:** Update or remove these placeholders.

## 5. Implicit Tasks

-   **Bot Simulation**: Ensure all new roles (e.g., `SecondWind`, `Creep`) have appropriate bot logic if `isBotFriendly` is true.

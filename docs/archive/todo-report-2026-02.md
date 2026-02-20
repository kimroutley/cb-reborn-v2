# Club Blackout Reborn: Actionable TODOs

This report consolidates development tasks, strategic goals, and code audit findings based on the current codebase state.

## 1. Strategic Roadmap (from README.md)

These are high-level feature requests and architectural improvements prioritized for the next release cycle.

-   **👻 Ghost Lounge + Dead Pool**
    -   **Task:** Implement a full player + host experience for eliminated players.
    -   **Status (Updated 2026-02-19):** Core flow implemented. Player dead-state now routes into a shared Ghost Lounge view with Dead Pool betting + live bet visibility, and Host dashboard surfaces active Dead Pool bets.
-   **💾 Multi-slot Save System**
    -   **Task:** Expand persistence beyond a single active recovery save.
    -   **Status (Updated 2026-02-19):** Implemented in host flow. `apps/host/lib/screens/save_load_screen.dart` now surfaces fixed save slots (`slot_1..slot_3`) with save/load/clear handling and slot integrity messaging. Treat as complete for host release scope; keep manual UX smoke validation on real devices.
-   **🧪 Real-device Multiplayer Validation**
    -   **Task:** Execute a validation checklist for local/cloud mode switching, deep-linking, and QR scanning on physical devices.
    -   **Status (Updated 2026-02-19):** First physical pass surfaced issues (mode switch instability and cloud connectivity glitches). Mitigations applied in `apps/host/lib/sync_mode_runtime.dart` (defensive stop-both-then-start bridge reset) and `apps/player/lib/cloud_player_bridge.dart` (wait for first cloud snapshot before join success + timeout error path). Re-test on physical devices is required before sign-off.
-   **🎭 Role Mechanics Parity Audit**
    -   **Task:** Audit `cb_logic` against `docs/architecture/role-mechanics.md`.
    -   **Status (Updated 2026-02-19):** Complete for current release scope. Verified against scripted setup/night/day flows plus passive/reactive handlers (`all_roles_script_audit_test.dart` + `night_resolution_test.dart` passing).

## 2. QA & Validation (from PROJECT_DEVELOPER_HANDBOOK.md)

Specific validation steps required before release.

-   **Release-signing Secret Provisioning**: Ensure secrets are provisioned in GitHub environment for `main` branch enforcement. **Status (Updated 2026-02-19):** Verified missing by operator (none present). This is a release blocker for `deploy-firebase` until `FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_PROJECT_ID`, and `FIREBASE_TOKEN` are added. CI now includes an explicit preflight secret validation step in `.github/workflows/ci-cd.yml` so failure is immediate and actionable.
-   **Host iOS Email Link Auth**: End-to-end verification of deep-link flow on iOS. **Status (Updated 2026-02-19):** Field report indicated post-login hang. Mitigation patch applied in `apps/host/lib/auth/phone_auth_gate.dart` (latest-link tracking + completion timeout/error handling). Physical iOS re-test/sign-off pending.

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

- **Bot Simulation**: Ensure all new roles (e.g., `SecondWind`, `Creep`) have appropriate bot logic if `isBotFriendly` is true. **Status (Updated 2026-02-19):** Expanded to full-role coverage — role catalog no longer excludes bot assignment for Whore/Lightweight/Messy Bitch/Clinger, and `simulateBotTurns` is now regression-tested across actor-scoped night actions plus setup/reactive prompts (Medic choice, Creep/Clinger setup, Wallflower observe, Second Wind convert, Tea Spiller reveal, Predator retaliation, Drama Queen setup/vendetta, Bartender). Added automated coverage guardrail in dedicated file: `packages/cb_logic/test/bot_simulation_audit_test.dart` (`bot audit: generated interactive role steps are simulatable`), which derives interactive steps from script generation and fails if bot simulation cannot execute them.

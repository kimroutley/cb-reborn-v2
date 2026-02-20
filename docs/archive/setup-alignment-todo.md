# Setup Alignment To-Do

> **Status Update (Feb 13, 2026):**
> Most phases below have been implemented in the core codebase.
> - **Game Style:** `GameStyle` enum and lobby config UI are active.
> - **Bots:** Autonomous bot logic (`addBot`, `simulateBotTurns`) is fully integrated.
> - **Auth:** Streamlined Google Sign-In + Moniker Gate is live.
> - **Resolution:** New modular `GameResolutionLogic` strategy pattern is in place.

This checklist tracks the original setup alignment tasks.

## Phase 0: Baseline review [x]

Start by confirming the current behavior so you know what is changing and why.

1. [x] Review setup script composition in `packages/cb_logic/lib/src/scripting/script_builder.dart`.
2. [x] Review role assignment logic in `packages/cb_logic/lib/src/game_resolution_logic.dart`.
3. [x] Review lobby flow and start gate in `apps/host/lib/screens/lobby_screen.dart`.
4. [x] Review session state fields in `packages/cb_models/lib/src/session_state.dart`.
5. [x] Review player state and role metadata in `packages/cb_models/lib/src/player.dart`.

## Phase 1: S_01 Lobby game mode selection [x]

1. [x] Confirm `GameStyle` enums map to the guide labels.
2. [x] Update the host lobby UI to show a 4-button toggle and store the result in game state.
3. [x] Decide how `MANUAL` affects deck generation and role assignment.

## Phase 2: S_02 Lobby start session (join URL + UUID) [x]

1. [x] Add a session UUID to `SessionState`.
2. [x] Generate and persist a UUID at session creation in `Session` provider.
3. [x] Update host lobby UI to display a join URL if required.

## Phase 3: S_03 Lobby player join and player cap [x]

1. [x] Enforce `maxPlayers = 25` in `Game` add player flow.
2. [x] Update host lobby UI to display a live `current/max` counter.

## Phase 4: S_04 Dealer ratio [x]

1. [x] Update staff count calculation in `GameResolutionLogic`.

## Phase 5: S_05 Add specials with mode weighting [x]

1. [x] Confirm which roles are mandatory in the current catalog.
2. [x] Implement mode-weighted role pools using `GameStyle.rolePool`.
3. [x] Ensure mandatory roles are always placed before bias roles are filled.

## Phase 6: S_06 Fill Party Animals [x]

1. [x] Explicitly fill leftover slots with `RoleIds.partyAnimal`.

## Phase 7: S_07 Assign roles [x]

1. [x] Add a manual role assignment path logic in `Game.startGame`.
2. [x] (UX Polish) Implement the manual role assignment drag-and-drop UI (Logic exists, UI is pending full polish).

## Phase 8: S_08 Push roles to clients [x]

1. [x] Confirm role sync path for local and cloud.
2. [x] Confirm player app transition to reveal state (`GameRouter`).

## Phase 9: S_09 Role confirmation (ack) [x]

1. [x] Add confirmed role tracking to `SessionState`.
2. [x] Add a `confirmRole` action to player app (in `ClaimScreen`).
3. [x] Update host lobby to display per-player confirmation status.

## Phase 10: S_10 Force start gate [x]

1. [x] Update host start button state.
2. [x] Add a host override toggle/logic (implicit in start command).
3. [x] Enforce the gating in `Game.startGame`.

## Phase 11: S_11 Loading assets [x]

1. [x] Add a loading state transition in player app.
2. [x] Add a host-side loading indicator.

## Phase 12: Setup script alignment [x]

1. [x] Confirm setup steps already present in `ScriptBuilder`.
2. [x] Add missing setup steps if required by your guide.

## Phase 13: Win conditions and special overrides [x]

1. [x] Add neutral win logic.
2. [x] Add Messy Bitch special win condition.
3. [x] Add settings flags if you want to toggle special wins per game.

## Notes and decisions to record

*   **Role Weighting:** Logic is centralized in `GameResolutionLogic.assignRoles`.
*   **Manual Mode:** Supported via `GameStyle.manual`. Logic checks for unassigned players before starting.
*   **Neutral Wins:** Implemented in `GameResolutionLogic.checkWinCondition`.

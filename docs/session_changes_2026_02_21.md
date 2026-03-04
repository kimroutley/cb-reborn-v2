# Session Changelog - Host/Player Integration & Override (2026-02-21)

This document catalogs the changes made in the current session to ensure regression safety.

## 1. Core Data Models & Bridges (Bot & Validation Support)

### `packages/cb_models/lib/src/player_snapshot.dart`
- **Added** `bool isBot` field to the `PlayerSnapshot` class.
- **Updated** `PlayerSnapshot.fromMap` to parse `isBot` (defaults to `false`).

### `apps/host/lib/cloud_host_bridge.dart`
- **Updated** `_publishStateInternal` (implied by logic, verified in file) to include `isBot` in the public `players` list payload.
- **Added** Validation in `_actionSub` listener: Checks if incoming actions have a valid `playerId`. Logs a warning if missing to prevent null/empty voter IDs in logic.

### `apps/player/lib/cloud_player_bridge.dart`
- **Updated** `_applyPrivateState` to ensure `isBot` is preserved when merging private data (along with `isAlive`, `deathDay`, etc.).
- **Verified** `_applyPublicState` parses the new `isBot` field via `PlayerSnapshot.fromMap`.

## 2. Player App - Lobby & Role Reveal

### `apps/player/lib/widgets/full_role_reveal_content.dart`
- **Created** new widget `FullRoleRevealContent`.
- **Function**: Displays large Role Avatar (breathing), Name, Alliance, Description, and an "ACKNOWLEDGE IDENTITY" button.
- **Usage**: Used in `LobbyScreen` for inline confirmation and inside the Role Reveal Modal.

### `apps/player/lib/screens/lobby_screen.dart`
- **Added** `_buildLobbyHelperCopy`: Returns context-aware instruction text based on phase (`lobby`, `setup`, confirmed status).
- **Added** Helper `CBGlassTile`: Displays the instruction text under the status card.
- **Added** Inline Role Reveal: Shows `FullRoleRevealContent` when player has a role but hasn't confirmed.
- **Added** Role Reveal Modal: Uses `ref.listen` on `myPlayerSnapshot.roleId` to trigger a dialog when a role is first assigned.
- **Updated** `_buildPlayerRoster`:
    - Now accepts `roleConfirmedPlayerIds`.
    - Shows a `check_circle` icon on chips for confirmed players.
    - Shows a `smart_toy` icon for bots.
    - Uses `CBFilterChip` (visually updated from `CBChip`) to match modern style.

## 3. Host App - Central Hub & Override

### `apps/host/lib/sheets/game_settings_sheet.dart`
- **Created** file to resolve missing import.
- **Content**: Placeholder UI for Host settings ("HOST HAS FINAL SAY", Game Limits, Visibility).
- **Status**: Skeleton implementation to prevent compile errors; logic to be fleshed out.

### `apps/host/lib/widgets/host_vote_override_dialog.dart`
- **Created** new widget `HostVoteOverrideDialog`.
- **Function**: Allows host to select a **Voter** (dropdown of alive players) and a **Target** (dropdown of players + Abstain).
- **Action**: Calls `controller.handleInteraction(stepId: 'day_vote', ...)` to force the vote.

### `apps/host/lib/widgets/vote_tally_panel.dart`
- **Updated** `build` method:
    - Checks if `StepKey.isDayVoteStep(currentStepId)`.
    - Displays a "HOST VOTE OVERRIDE" button (`CBGhostButton`) if active.
- **Updated** `_showVoteOverrideSheet`: Now opens `HostVoteOverrideDialog` instead of the inline `_VoteOverrideSheet` (which was removed/refactored).

## 4. Documentation

### `docs/host_player_communication.md`
- **Created** protocol documentation.
- **Content**: Describes the centralized Host architecture, Data Flow (Player -> Firestore -> Host Bridge -> Game), Action Types, and Host Authority (Override).

## 5. Potential Cleanup Items (Lint/Regression Risks)

- **`apps/host/lib/widgets/vote_tally_panel.dart`**: The internal class `_VoteOverrideSheet` was replaced by the external `HostVoteOverrideDialog`. Ensure `_VoteOverrideSheet` is fully removed if unused (code effectively replaced it).
- **`apps/player/lib/screens/lobby_screen.dart`**: Ensure `_buildInThisGameRow` (if it existed) is fully replaced by `_buildPlayerRoster` and not left as dead code.
- **Imports**: Check for unused imports in `lobby_screen.dart` and `vote_tally_panel.dart` after refactors.

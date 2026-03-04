# Player Join & Feed Blank Screen Fix

## Goal Description
The purpose of this change is to fix a bug where players connecting to a session mid-game (e.g., via a join URL or late code entry) are presented with a persistent "SYNCING..." blank screen. This occurs because [PlayerHomeShell](file:///c:/Users/kimro/Documents/cb-reborn-v2/apps/player/lib/screens/player_home_shell.dart#25-38) automatically routes players to the [GameScreen](file:///c:/Users/kimro/Documents/cb-reborn-v2/apps/player/lib/screens/game_screen.dart#16-22) if the game phase is active ('day', 'night', 'endGame'), but the GameScreen fails to render if the player hasn't claimed an identity (`myPlayerId` is null).

The fix is to enforce that a player must have a claimed identity (`myPlayerId != null`) before [PlayerHomeShell](file:///c:/Users/kimro/Documents/cb-reborn-v2/apps/player/lib/screens/player_home_shell.dart#25-38) transitions them to [GameScreen](file:///c:/Users/kimro/Documents/cb-reborn-v2/apps/player/lib/screens/game_screen.dart#16-22). If they don't have one, they should be routed to the [ClaimScreen](file:///c:/Users/kimro/Documents/cb-reborn-v2/apps/player/lib/screens/claim_screen.dart#8-14) to pick their identity, even if the game is already in progress.

## Proposed Changes

### Player App Screens

#### [MODIFY] [player_home_shell.dart](file:///c:/Users/kimro/Documents/cb-reborn-v2/apps/player/lib/screens/player_home_shell.dart)
Update the [_onBridgeChanged](file:///c:/Users/kimro/Documents/cb-reborn-v2/apps/player/lib/screens/player_home_shell.dart#53-108) navigation logic in [PlayerHomeShell](file:///c:/Users/kimro/Documents/cb-reborn-v2/apps/player/lib/screens/player_home_shell.dart#25-38) to check if `myPlayerId` is null when determining the next screen based on the game phase.
- If the phase is active ('day', 'night', 'resolution', 'endGame') AND `nextState.myPlayerId` is null, it should force navigation to `PlayerDestination.claim` instead of `PlayerDestination.game`.

## Verification Plan

### Automated Tests
- Run `flutter test` within the `apps/player` directory to ensure no regressions in navigation tests (if any exist).

### Manual Verification
1. Open the host app and start a game (progress past the Lobby/Setup phase to 'Day 1').
2. Open the player app.
3. Attempt to join the live game using the Host's join code.
4. Verify that instead of jumping to the "SYNCING..." Game Screen, the Player App correctly presents the **Claim Identity** screen.
5. Select a player identity. Verify that the app then successfully transitions to the Game Screen and renders the feed.

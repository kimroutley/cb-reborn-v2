# Host-Player Communication & Override Protocol

## Overview

Club Blackout uses a **centralized host model**. The **Host App** is the single source of truth for the game state. 
- **Players** write actions (votes, choices) to Firestore.
- **Host Bridge** subscribes to these actions, deduplicates them, and feeds them into the `Game` controller.
- **Host App** processes the logic and publishes the updated public state (and private player data) back to Firestore.
- **Players** read this state to update their UI.

There is no direct peer-to-peer communication between players, nor do players write directly to the game state.

## Data Flow

1. **Player Action**: Player taps a button (e.g., Vote for "Alice").
   - Writes to `/games/{code}/actions/{actionId}`.
   - Payload: `{ type: 'interaction', stepId: 'day_vote', targetId: 'alice_uid', playerId: 'bob_uid' }`.
2. **Host Bridge**: `CloudHostBridge` in Host App listens to `/actions`.
   - Deduplicates based on `actionId`.
   - Calls `gameProvider.notifier.handleInteraction(stepId, targetId, voterId)`.
3. **Game Logic**: `Game` controller updates `gameState` (e.g., `dayVotesByVoter['bob_uid'] = 'alice_uid'`).
4. **Publish**: Host publishes new state to `/games/{code}`.
   - Public doc: `{ phase: 'day', dayVoteTally: {...}, ... }`
   - Private subcollection: Each player gets their own data at `/games/{code}/players/{uid}`.

## Host Authority & Override

Because the Host App processes all inputs, the Host has **final say** and can **override** any player action.

- **Day Vote Override**: The Host can manually set a vote for any player via the `VoteTallyPanel` -> "HOST VOTE OVERRIDE". This calls `handleInteraction` directly, simulating the player's choice.
- **Script Step Override**: For night actions or other steps, the Host "Simulate" or "Manual Selection" controls in `GameBottomControls` perform the action on behalf of the active role/player.
- **Settings**: All game settings (timers, rules) are controlled by the Host via the `GameSettingsSheet`. Players cannot modify these settings.

## Action Types

| Type | Description | Required Fields |
| :--- | :--- | :--- |
| `role_confirm` | Player acknowledges their role card. | `playerId` |
| `dead_pool_bet` | Player places a bet in the Dead Pool. | `playerId`, `targetId` |
| `ghost_chat` | Dead player sends a message to Ghost Lounge. | `playerId`, `playerName`, `message` |
| `interaction` (default) | Generic game move (vote, night action). | `stepId`, `targetId` (optional), `playerId` (voter) |

## Validation

The `CloudHostBridge` performs basic validation ensuring `stepId` is present. The `Game` controller ensures the action is valid for the current game state (e.g., is the player alive? is the step active?).

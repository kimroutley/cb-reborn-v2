# 🧪 Testing Improvement: Player Bridge State Management

## 🎯 What
Addressed a significant testing gap in `apps/player/lib/player_bridge.dart` where `PlayerBridge` logic was tightly coupled to `PlayerClient`, making it difficult to unit test without real network connections.

## 📊 Coverage
The new test suite `apps/player/test/player_bridge_test.dart` covers:
- **Connection Management**: Verifies connection and disconnection state updates.
- **Message Sending**: Validates that methods like `joinWithCode`, `claimPlayer`, `vote`, and `sendAction` dispatch the correct `GameMessage` payloads via the client.
- **State Synchronization**: Tests that incoming `state_sync` messages correctly update the local `PlayerGameState` (players, phase, current step, etc.).
- **Response Handling**: Verifies correct state updates for `join_response` (accepted/rejected) and `claim_response` (success/failure).
- **Error Handling**: Tests error conditions like connection failures and join rejections.
- **Kicking Logic**: Ensures local state is reset when receiving a `player_kicked` message for the current player.
- **Reconnection**: Verifies that `player_reconnect` is sent with claimed IDs upon reconnection.

## ✨ Result
- **Testability**: `PlayerBridge` now accepts a mock `PlayerClient` via a static factory for testing, enabling deterministic unit tests.
- **Bug Fix**: Identified and fixed a bug in `PlayerGameState.copyWith` where nullable fields (like `myPlayerId`) could not be explicitly set to `null` due to the `??` operator. Implemented a `_undefined` sentinel pattern to resolve this.
- **Stability**: Fixed a compilation error in `packages/cb_theme` (`CBTextField` missing `textAlign`) that was blocking the test runner for the player app.

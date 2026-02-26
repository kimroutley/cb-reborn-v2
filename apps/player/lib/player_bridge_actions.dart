abstract class PlayerBridgeActions {
  /// Join a game session by code.
  Future<void> joinGame(String joinCode, String playerName);

  /// Claim a player identity from the roster.
  Future<void> claimPlayer(String playerId);

  /// Cast a vote during the day phase.
  Future<void> vote({required String voterId, required String targetId});

  /// Send a role-specific night action.
  Future<void> sendAction({
    required String stepId,
    required String targetId,
    String? voterId,
  });

  /// Confirm that this player has acknowledged their revealed role.
  Future<void> confirmRole({required String playerId});

  /// ── GHOST LOUNGE: PLACE BET ──
  Future<void> placeDeadPoolBet({
    required String playerId,
    required String targetPlayerId,
  });

  /// Send a message to the Ghost Lounge channel.
  Future<void> sendGhostChat({
    required String playerId,
    required String message,
    String? playerName,
  });

  /// Send a message to the public feed.
  Future<void> sendBulletin({
    required String title,
    required String floatContent,
    String? roleId,
  });

  /// Disconnect from the current session.
  Future<void> leave();
}

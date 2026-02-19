import 'package:cb_player/player_bridge_actions.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GhostLoungeContent extends StatelessWidget {
  final PlayerGameState gameState;
  final String playerId;
  final PlayerBridgeActions bridge;

  const GhostLoungeContent({
    super.key,
    required this.gameState,
    required this.playerId,
    required this.bridge,
  });

  @override
  Widget build(BuildContext context) {
    final playersById = {
      for (final p in gameState.players) p.id: p,
    };
    final aliveTargets = gameState.players
        .where((p) => p.isAlive)
        .map(
          (p) => GhostLoungeTarget(id: p.id, name: p.name),
        )
        .toList();

    final betCounts = <String, int>{};
    for (final entry in gameState.deadPoolBets.entries) {
      betCounts[entry.value] = (betCounts[entry.value] ?? 0) + 1;
    }

    final activeBets = gameState.deadPoolBets.entries
        .map(
          (entry) => GhostLoungeBet(
            bettorName: playersById[entry.key]?.name ?? entry.key,
            targetName: playersById[entry.value]?.name ?? entry.value,
            oddsCount: betCounts[entry.value] ?? 0,
          ),
        )
        .toList();

    final myBetTargetId = gameState.deadPoolBets[playerId];
    final myBetTargetName = myBetTargetId == null
        ? null
        : (playersById[myBetTargetId]?.name ?? myBetTargetId);

    return GhostLoungeView(
      aliveTargets: aliveTargets,
      activeBets: activeBets,
      currentBetTargetName: myBetTargetName,
      onPlaceBet: (targetId) {
        bridge.placeDeadPoolBet(
          playerId: playerId,
          targetPlayerId: targetId,
        );
        HapticFeedback.selectionClick();
      },
    );
  }
}

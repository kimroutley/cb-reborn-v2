import 'package:cb_models/cb_models.dart';

import 'day_resolution_handler.dart';

class DeadPoolHandler implements DayResolutionHandler {
  const DeadPoolHandler();

  @override
  DayResolutionResult handle(DayResolutionContext context) {
    final exiledPlayerId = context.exiledPlayerId;
    if (exiledPlayerId == null || exiledPlayerId.isEmpty) {
      return DayResolutionResult(players: context.players);
    }

    final exiledPlayer = context.players.firstWhere(
      (p) => p.id == exiledPlayerId,
      orElse: () => Player(
        id: '',
        name: '',
        role: roleCatalog.first,
        alliance: Team.unknown,
      ),
    );

    final updatedPlayers = context.players.map((p) {
      if (!p.isAlive && p.currentBetTargetId != null) {
        final won = p.currentBetTargetId == exiledPlayerId;
        final delta = won ? -1 : 1; // Reward: -1 drink, Penalty: +1 drink
        final outcome = won ? 'WON' : 'LOST';
        final entry =
            '[DEAD POOL] $outcome: ${p.currentBetTargetId} -> ${exiledPlayer.name}';

        return p.copyWith(
          drinksOwed: (p.drinksOwed + delta).clamp(0, 99),
          currentBetTargetId: null, // Clear bet for next round
          penalties: [...p.penalties, entry],
        );
      }
      return p;
    }).toList();

    return DayResolutionResult(
      players: updatedPlayers,
      clearDeadPoolBets: true,
    );
  }
}

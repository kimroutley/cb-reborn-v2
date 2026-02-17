import 'package:cb_models/cb_models.dart';

typedef PredatorRetaliationResolution = ({
  List<Player> players,
  List<String> lines,
  List<GameEvent> events,
  List<String> victimIds,
});

PredatorRetaliationResolution resolvePredatorRetaliation({
  required List<Player> players,
  required Map<String, String> votesByVoter,
  required int dayCount,
}) {
  var updatedPlayers = List<Player>.from(players);
  final retaliationLines = <String>[];
  final retaliationEvents = <GameEvent>[];
  final retaliationVictimIds = <String>[];

  final exiledPredators = updatedPlayers.where((p) =>
      !p.isAlive &&
      p.deathReason == 'exile' &&
      p.role.id == RoleIds.predator);

  for (final predator in exiledPredators) {
    final votersAgainst = votesByVoter.entries
        .where((e) => e.value == predator.id)
        .map((e) => e.key)
        .toList();

    String? retaliationTargetId;
    for (final voterId in votersAgainst) {
      if (voterId == predator.id) {
        continue;
      }
      final voterMatches =
          updatedPlayers.where((p) => p.id == voterId).toList();
      if (voterMatches.isEmpty) {
        continue;
      }
      if (voterMatches.first.isAlive) {
        retaliationTargetId = voterId;
        break;
      }
    }

    if (retaliationTargetId == null) {
      continue;
    }

    updatedPlayers = updatedPlayers.map((p) {
      if (p.id == retaliationTargetId) {
        return p.copyWith(
          isAlive: false,
          deathReason: 'predator_retaliation',
          deathDay: dayCount,
        );
      }
      return p;
    }).toList();

    final retaliationTarget =
        updatedPlayers.firstWhere((p) => p.id == retaliationTargetId);
    retaliationVictimIds.add(retaliationTargetId);
    retaliationLines.add(
      'Predator struck back: ${retaliationTarget.name} was taken down in retaliation.',
    );
    retaliationEvents.add(
      GameEvent.death(
        playerId: retaliationTargetId,
        reason: 'predator_retaliation',
        day: dayCount,
      ),
    );
  }

  return (
    players: updatedPlayers,
    lines: retaliationLines,
    events: retaliationEvents,
    victimIds: retaliationVictimIds,
  );
}
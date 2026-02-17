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
  Map<String, String> retaliationChoices = const {},
}) {
  var updatedPlayers = List<Player>.from(players);
  final retaliationLines = <String>[];
  final retaliationEvents = <GameEvent>[];
  final retaliationVictimIds = <String>[];

  final exiledPredators = updatedPlayers.where((p) =>
      !p.isAlive && p.deathReason == 'exile' && p.role.id == RoleIds.predator);

  for (final predator in exiledPredators) {
    final votersAgainst = votesByVoter.entries
        .where((e) => e.value == predator.id)
        .map((e) => e.key)
        .toList();

    final eligibleVoterIds = votersAgainst
        .where((voterId) => voterId != predator.id)
        .where(
          (voterId) => updatedPlayers.any((p) => p.id == voterId && p.isAlive),
        )
        .toList();

    String? retaliationTargetId = retaliationChoices[predator.id];
    if (retaliationTargetId != null &&
        !eligibleVoterIds.contains(retaliationTargetId)) {
      retaliationTargetId = null;
    }

    for (final voterId in eligibleVoterIds) {
      if (retaliationTargetId != null) {
        break;
      }
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

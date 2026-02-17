import 'package:cb_models/cb_models.dart';

typedef DramaQueenSwapResolution = ({
  List<Player> players,
  List<String> lines,
});

DramaQueenSwapResolution resolveDramaQueenSwaps({
  required List<Player> players,
  required Map<String, String> votesByVoter,
  Map<String, String> dramaQueenSwapChoices = const {},
}) {
  final lines = <String>[];
  var updatedPlayers = List<Player>.from(players);

  final exiledDramaQueens = updatedPlayers.where((p) =>
      !p.isAlive &&
      p.deathReason == 'exile' &&
      p.role.id == RoleIds.dramaQueen);

  for (final dramaQueen in exiledDramaQueens) {
    final aliveTargets = updatedPlayers
        .where((p) => p.isAlive && p.id != dramaQueen.id)
        .toList();

    if (aliveTargets.length < 2) {
      continue;
    }

    final rawSelectedSwapIds = (dramaQueenSwapChoices[dramaQueen.id] ?? '')
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && id != dramaQueen.id)
        .where((id) => aliveTargets.any((p) => p.id == id))
        .toList();

    final selectedSwapIds = rawSelectedSwapIds.length == 2 &&
            rawSelectedSwapIds[0] != rawSelectedSwapIds[1]
        ? rawSelectedSwapIds
        : const <String>[];

    final preferredTargets = [
      dramaQueen.dramaQueenTargetAId,
      dramaQueen.dramaQueenTargetBId,
    ]
        .whereType<String>()
        .where((id) => id.isNotEmpty && id != dramaQueen.id)
        .toSet()
        .where((id) => aliveTargets.any((p) => p.id == id))
        .toList();

    final votersAgainst = votesByVoter.entries
        .where((e) => e.value == dramaQueen.id)
        .map((e) => e.key)
        .where((id) => id != dramaQueen.id)
        .where((id) => aliveTargets.any((p) => p.id == id))
        .toList();

    final candidateIds = [
      ...selectedSwapIds,
      ...preferredTargets,
      ...votersAgainst,
      ...aliveTargets.map((p) => p.id),
    ].toSet().toList();

    if (candidateIds.length < 2) {
      continue;
    }

    final targetAId = candidateIds[0];
    final targetBId = candidateIds[1];

    final indexA = updatedPlayers.indexWhere((p) => p.id == targetAId);
    final indexB = updatedPlayers.indexWhere((p) => p.id == targetBId);
    if (indexA == -1 || indexB == -1) {
      continue;
    }

    final targetA = updatedPlayers[indexA];
    final targetB = updatedPlayers[indexB];

    updatedPlayers[indexA] = targetA.copyWith(
      role: targetB.role,
      alliance: targetB.alliance,
    );
    updatedPlayers[indexB] = targetB.copyWith(
      role: targetA.role,
      alliance: targetA.alliance,
    );

    lines.add(
      'Drama Queen chaos: ${targetA.name} and ${targetB.name} swapped roles.',
    );
    lines.add(
      'Drama Queen reveal: ${targetA.name} is now ${targetB.role.name}, ${targetB.name} is now ${targetA.role.name}.',
    );
  }

  return (players: updatedPlayers, lines: lines);
}

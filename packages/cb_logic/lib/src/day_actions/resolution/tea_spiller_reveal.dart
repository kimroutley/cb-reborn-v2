import 'package:cb_models/cb_models.dart';

List<String> resolveTeaSpillerReveals({
  required List<Player> players,
  required Map<String, String> votesByVoter,
}) {
  final lines = <String>[];

  final exiledTeaSpillers = players.where((p) =>
      !p.isAlive &&
      p.deathReason == 'exile' &&
      p.role.id == RoleIds.teaSpiller);

  for (final teaSpiller in exiledTeaSpillers) {
    final votersAgainst = votesByVoter.entries
        .where((e) => e.value == teaSpiller.id)
        .map((e) => e.key)
        .toList();

    if (votersAgainst.isEmpty) {
      continue;
    }

    // Deterministic reveal: first voter recorded against Tea Spiller.
    final revealedVoterId = votersAgainst.first;
    final revealedVoterMatches =
        players.where((p) => p.id == revealedVoterId).toList();
    if (revealedVoterMatches.isEmpty) {
      continue;
    }

    final revealedVoter = revealedVoterMatches.first;
    lines.add(
      'Tea Spiller exposed ${revealedVoter.name}: ${revealedVoter.role.name}.',
    );
  }

  return lines;
}
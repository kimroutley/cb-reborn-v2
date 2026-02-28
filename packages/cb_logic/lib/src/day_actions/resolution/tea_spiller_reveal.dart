import 'package:cb_models/cb_models.dart';

List<String> resolveTeaSpillerReveals({
  required List<Player> players,
  required Map<String, String> votesByVoter,
  Map<String, String> teaSpillerRevealChoices = const {},
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

    var revealedVoterId = votersAgainst.first;
    final selectedRevealId = teaSpillerRevealChoices[teaSpiller.id];
    if (selectedRevealId != null && votersAgainst.contains(selectedRevealId)) {
      revealedVoterId = selectedRevealId;
    }

    final revealedVoterMatches =
        players.where((p) => p.id == revealedVoterId).toList();
    if (revealedVoterMatches.isEmpty) {
      continue;
    }

    final revealedVoter = revealedVoterMatches.first;
    lines.add(
      'THE TEA HAS BEEN SPILLED! ${teaSpiller.name.toUpperCase()} DRAGS ${revealedVoter.name.toUpperCase()} DOWN WITH THEM: THEY ARE THE ${revealedVoter.role.name.toUpperCase()}!',
    );
  }

  return lines;
}

import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class VoteTallyPanel extends StatelessWidget {
  final List<Player> players;
  final Map<String, int> tally;
  final Map<String, String> votesByVoter;

  const VoteTallyPanel({
    super.key,
    required this.players,
    required this.tally,
    this.votesByVoter = const {},
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final sorted = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return CBPanel(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      borderColor: scheme.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBBadge(text: 'VOTE TALLY', color: scheme.secondary),
          const SizedBox(height: 8),
          for (final entry in sorted) ...[
            Text(
              '${_nameForId(entry.key)}: ${entry.value}',
              style: textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w700),
            ),
            if (votesByVoter.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                  _voterNamesFor(entry.key),
                  style: textTheme.bodySmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _voterNamesFor(String targetId) {
    final voterNames = votesByVoter.entries
        .where((e) => e.value == targetId)
        .map((e) => _nameForId(e.key))
        .toList();
    if (voterNames.isEmpty) return '';
    return 'by ${voterNames.join(", ")}';
  }

  String _nameForId(String playerId) {
    if (playerId == 'abstain') return 'Abstain';
    for (final player in players) {
      if (player.id == playerId) return player.name;
    }
    return 'Unknown';
  }
}

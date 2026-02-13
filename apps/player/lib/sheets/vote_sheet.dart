import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import '../player_bridge.dart';

class VoteSheet extends StatelessWidget {
  final List<PlayerSnapshot> players;
  final Map<String, int> voteTally;
  final Function(String) onVote;
  final VoidCallback onSkip;

  const VoteSheet({
    super.key,
    required this.players,
    required this.voteTally,
    required this.onVote,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.secondary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: CBInsets.screen,
          child: Row(
            children: [
              Text(
                'CAST VOTE',
                style: textTheme.labelLarge!.copyWith(
                  color: accent,
                ),
              ),
              const Spacer(),
              CBGhostButton(
                label: 'SKIP VOTE',
                onPressed: onSkip,
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),

        // Tally Section
        if (voteTally.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: CBSpace.x4, vertical: CBSpace.x2),
            padding: const EdgeInsets.all(CBSpace.x3),
            decoration: BoxDecoration(
              border: Border.all(
                color: accent.withValues(alpha: 0.3),
              ),
              color: accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(CBRadius.sm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CBBadge(text: 'LIVE TALLY', color: accent),
                const SizedBox(height: CBSpace.x2),
                Wrap(
                  spacing: CBSpace.x3,
                  runSpacing: CBSpace.x2,
                  children: _sortedTally().map((entry) {
                    final name = _playerNameById(entry.key);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$name: ',
                          style: textTheme.bodySmall!.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          '${entry.value}',
                          style: textTheme.labelMedium!.copyWith(
                            color: accent,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

        // Player List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: CBInsets.screen,
          itemCount: players.length,
          separatorBuilder: (_, __) => const SizedBox(height: CBSpace.x2),
          itemBuilder: (context, index) {
            final player = players[index];
            return CBPanel(
              padding: const EdgeInsets.symmetric(
                horizontal: CBSpace.x4,
                vertical: CBSpace.x3,
              ),
              borderColor: accent.withValues(alpha: 0.3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      player.name.toUpperCase(),
                      style: textTheme.bodyLarge!,
                    ),
                  ),
                  SizedBox(
                    width: 112,
                    child: CBPrimaryButton(
                      label: 'VOTE',
                      onPressed: () => onVote(player.id),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: CBSpace.x4),
      ],
    );
  }

  List<MapEntry<String, int>> _sortedTally() {
    final entries = voteTally.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String _playerNameById(String id) {
    if (id == 'skip') return 'SKIP';
    return players
        .firstWhere(
          (p) => p.id == id,
          orElse: () =>
              PlayerSnapshot(id: id, name: 'Unknown', roleId: '', roleName: ''),
        )
        .name
        .toUpperCase();
  }
}

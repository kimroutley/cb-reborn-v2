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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final accent = scheme.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CBBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              CBSpace.x5, CBSpace.x2, CBSpace.x5, CBSpace.x4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CBSpace.x2),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.how_to_vote_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: CBSpace.x3),
              Text(
                'CAST YOUR VOTE',
                style: textTheme.headlineSmall!.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  shadows: CBColors.textGlow(accent, intensity: 0.4),
                ),
              ),
              const Spacer(),
              CBGhostButton(
                label: 'SKIP',
                onPressed: () {
                  HapticService.light();
                  onSkip();
                },
                color: scheme.onSurface.withValues(alpha: 0.4),
                fullWidth: false,
              ),
            ],
          ),
        ),
        if (voteTally.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: CBSpace.x5),
            child: CBGlassTile(
              padding: const EdgeInsets.all(CBSpace.x4),
              borderColor: accent.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'LIVE TALLY PREVIEW',
                    style: textTheme.labelSmall?.copyWith(
                      color: accent.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x3),
                  Wrap(
                    spacing: CBSpace.x2,
                    runSpacing: CBSpace.x2,
                    children: _sortedTally().map((entry) {
                      final name = _playerNameById(entry.key);
                      return CBMiniTag(
                        text: '$name: ${entry.value}',
                        color: accent,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: CBSpace.x4),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
                CBSpace.x5, 0, CBSpace.x5, CBSpace.x8),
            itemCount: players.length,
            separatorBuilder: (_, __) => const SizedBox(height: CBSpace.x3),
            itemBuilder: (context, index) {
              final player = players[index];
              return CBGlassTile(
                padding: const EdgeInsets.all(CBSpace.x4),
                borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
                onTap: () {
                  HapticService.heavy();
                  onVote(player.id);
                },
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:
                                scheme.outlineVariant.withValues(alpha: 0.2)),
                      ),
                      child: Center(
                        child: Text(
                          player.name.characters.first.toUpperCase(),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: CBSpace.x4),
                    Expanded(
                      child: Text(
                        player.name.toUpperCase(),
                        style: textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ),
                    CBPrimaryButton(
                      label: 'VOTE',
                      onPressed: () {
                        HapticService.heavy();
                        onVote(player.id);
                      },
                      fullWidth: false,
                      backgroundColor: accent.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<MapEntry<String, int>> _sortedTally() {
    final entries = voteTally.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  String _playerNameById(String id) {
    if (id == 'skip' || id == 'abstain') return 'SKIP';
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

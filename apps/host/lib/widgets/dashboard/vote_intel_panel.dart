import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class VoteIntelPanel extends StatelessWidget {
  final GameState gameState;

  const VoteIntelPanel({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final playersById = {for (final p in gameState.players) p.id: p};

    final tally = gameState.dayVoteTally;
    final votesByVoter = gameState.dayVotesByVoter;
    final alivePlayers = gameState.players.where((p) => p.isAlive).toList();
    final totalVoters = alivePlayers.length;
    final votesIn = votesByVoter.length;

    if (gameState.phase != GamePhase.day) return const SizedBox.shrink();

    final sortedTally = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVotes =
        sortedTally.isNotEmpty ? sortedTally.first.value : 1;

    return CBPanel(
      borderColor: scheme.secondary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: CBSectionHeader(
                  title: 'LIVE VOTE TRACKER',
                  color: scheme.secondary,
                  icon: Icons.how_to_vote_rounded,
                ),
              ),
              CBBadge(
                text: '$votesIn/$totalVoters CAST',
                color: votesIn >= totalVoters
                    ? scheme.tertiary
                    : scheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Vote progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: totalVoters > 0 ? votesIn / totalVoters : 0,
              minHeight: 4,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation(
                votesIn >= totalVoters ? scheme.tertiary : scheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          if (sortedTally.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'NO VOTES CAST YET.',
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.3),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            )
          else
            ...sortedTally.map((entry) {
              final targetName = entry.key == 'abstain'
                  ? 'ABSTAIN'
                  : (playersById[entry.key]?.name.toUpperCase() ??
                      entry.key.toUpperCase());
              final voteCount = entry.value;
              final barFraction =
                  maxVotes > 0 ? voteCount / maxVotes : 0.0;

              final voterNames = votesByVoter.entries
                  .where((e) => e.value == entry.key)
                  .map((e) =>
                      playersById[e.key]?.name.split(' ').first.toUpperCase() ??
                      e.key.toUpperCase())
                  .toList();

              final targetPlayer = playersById[entry.key];
              final targetColor = targetPlayer != null
                  ? CBColors.fromHex(targetPlayer.role.colorHex)
                  : scheme.secondary;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            targetName,
                            style: textTheme.labelSmall!.copyWith(
                              color: targetColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          '$voteCount',
                          style: textTheme.labelLarge!.copyWith(
                            color: targetColor,
                            fontWeight: FontWeight.w900,
                            shadows:
                                CBColors.textGlow(targetColor, intensity: 0.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: barFraction,
                        minHeight: 6,
                        backgroundColor: targetColor.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(
                            targetColor.withValues(alpha: 0.7)),
                      ),
                    ),
                    if (voterNames.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'BY: ${voterNames.join(', ')}',
                        style: textTheme.labelSmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          fontSize: 7,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),

          // Last day report
          if (gameState.lastDayReport.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '// LAST DAY RESOLUTION',
              style: textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.4),
                letterSpacing: 1.5,
                fontWeight: FontWeight.w800,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 6),
            ...gameState.lastDayReport.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    line.toUpperCase(),
                    style: textTheme.labelSmall!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 8,
                      height: 1.3,
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

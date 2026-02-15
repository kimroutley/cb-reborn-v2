import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class DeadPoolPanel extends StatelessWidget {
  final GameState gameState;

  const DeadPoolPanel({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final playersById = {
      for (final player in gameState.players) player.id: player,
    };

    final activeBets = gameState.deadPoolBets.entries.toList();
    final deadBettors =
        gameState.players.where((p) => !p.isAlive).toList();

    final betCounts = <String, int>{};
    for (final entry in activeBets) {
      betCounts[entry.value] = (betCounts[entry.value] ?? 0) + 1;
    }

    return CBPanel(
      borderColor: scheme.error.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'Dead Pool Live Bets',
            color: scheme.error,
            icon: Icons.casino_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            deadBettors.isEmpty
                ? 'No eliminated players yet.'
                : activeBets.isEmpty
                    ? 'No active bets placed by ghosts.'
                    : '${activeBets.length} active bets',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (activeBets.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...activeBets.map((entry) {
              final bettor = playersById[entry.key];
              final target = playersById[entry.value];
              final oddsCount = betCounts[entry.value] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${bettor?.name ?? entry.key} → ${target?.name ?? entry.value}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    CBBadge(
                      text: '$oddsCount on target',
                      color: CBColors.alertOrange,
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

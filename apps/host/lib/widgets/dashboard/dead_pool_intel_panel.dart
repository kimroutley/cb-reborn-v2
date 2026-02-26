import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

/// Displays active Dead Pool bets and ghost chat intel in the Host dashboard.
class DeadPoolIntelPanel extends StatelessWidget {
  final GameState gameState;

  const DeadPoolIntelPanel({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final deadPlayers = gameState.players.where((p) => !p.isAlive).toList();
    final playersById = {for (final p in gameState.players) p.id: p};
    final bets = gameState.deadPoolBets;

    final betCounts = <String, int>{};
    for (final targetId in bets.values) {
      betCounts[targetId] = (betCounts[targetId] ?? 0) + 1;
    }

    final ghostMessages = <String>[];
    for (final entry in gameState.privateMessages.entries) {
      for (final msg in entry.value) {
        if (msg.startsWith('[GHOST]') && !ghostMessages.contains(msg)) {
          ghostMessages.add(msg);
        }
      }
    }

    if (deadPlayers.isEmpty) return const SizedBox.shrink();

    return CBPanel(
      borderColor: scheme.error.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBSectionHeader(
            title: 'DEAD POOL INTEL (${bets.length})',
            color: scheme.error,
            icon: Icons.whatshot_rounded,
          ),
          const SizedBox(height: 12),
          Text(
            '// SPECTATOR NETWORK ACTIVITY.',
            style: textTheme.labelSmall!.copyWith(
              color: scheme.error.withValues(alpha: 0.6),
              fontSize: 8,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          // Ghost count
          Row(
            children: [
              Icon(Icons.people_outline_rounded,
                  color: scheme.error, size: 16),
              const SizedBox(width: 8),
              Text(
                '${deadPlayers.length} GHOST${deadPlayers.length == 1 ? '' : 'S'} IN THE LOUNGE',
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              CBBadge(
                text: '${bets.length} BET${bets.length == 1 ? '' : 'S'}',
                color: scheme.error,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Active bets
          if (bets.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'NO ACTIVE DEAD POOL BETS.',
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.3),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            )
          else ...[
            // Odds board: grouped by target
            ...betCounts.entries.map((targetEntry) {
              final targetName =
                  playersById[targetEntry.key]?.name ?? targetEntry.key;
              final count = targetEntry.value;
              final bettors = bets.entries
                  .where((e) => e.value == targetEntry.key)
                  .map((e) => playersById[e.key]?.name ?? e.key)
                  .toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CBGlassTile(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  borderColor: scheme.error.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              targetName.toUpperCase(),
                              style: textTheme.labelLarge!.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w900,
                                shadows: CBColors.textGlow(scheme.error,
                                    intensity: 0.3),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PREDICTED BY: ${bettors.map((n) => n.toUpperCase()).join(', ')}',
                              style: textTheme.labelSmall!.copyWith(
                                color:
                                    scheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CBBadge(
                        text: '$count BET${count == 1 ? '' : 'S'}',
                        color: scheme.error,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          // Ghost comms preview
          if (ghostMessages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              '// GHOST COMMS INTERCEPT',
              style: textTheme.labelSmall!.copyWith(
                color: scheme.tertiary.withValues(alpha: 0.6),
                fontSize: 8,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...ghostMessages.reversed.take(5).map((msg) {
              final ghostPrefix = RegExp(r'^\[GHOST\]\s*');
              final cleaned = msg.replaceFirst(ghostPrefix, '');

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: CBMessageBubble(
                  sender: 'GHOST',
                  message: cleaned,
                  style: CBMessageStyle.whisper,
                  color: scheme.tertiary,
                  isSender: false,
                  isCompact: true,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

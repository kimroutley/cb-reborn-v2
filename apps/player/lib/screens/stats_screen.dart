import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/custom_drawer.dart';
import '../player_stats.dart';
import '../player_bridge.dart'; // Import player bridge to get current player ID

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerBridgeProvider);
    final statsNotifier = ref.read(playerStatsProvider.notifier);

    // Update the active player ID for stats calculation
    // This assumes the player has claimed an ID.
    if (playerState.myPlayerId != null) {
      statsNotifier.setActivePlayerId(playerState.myPlayerId!);
    }

    final stats = ref.watch(playerStatsProvider);
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'GAME STATS',
      drawer:
          const CustomDrawer(), // Keep as const for now, revisit drawer integration later
      body: Center(
        child: Padding(
          padding: CBInsets.panel,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CBGlassTile(
                title: "CAREER METRICS",
                subtitle: "ANALYZE YOUR PERFORMANCE",
                accentColor: scheme.primary,
                icon: Icon(Icons.show_chart_rounded,
                    size: 48, color: scheme.primary),
                content: Column(
                  children: [
                    _buildStatRow(
                      "GAMES PLAYED",
                      "${stats.gamesPlayed}",
                      scheme.secondary, // Migrated from CBColors.neonPurple
                      context,
                    ),
                    const SizedBox(height: CBSpace.x3),
                    _buildStatRow(
                      "WIN RATE",
                      "${stats.winRate.toStringAsFixed(0)}%",
                      scheme.tertiary, // Migrated from CBColors.matrixGreen
                      context,
                    ),
                    const SizedBox(height: CBSpace.x3),
                    _buildStatRow(
                      "FAVORITE ROLE",
                      stats.favoriteRole.toUpperCase(),
                      scheme
                          .primary, // Migrated from CBColors.hotPink (using primary as a general accent)
                      context,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(
      String label, String value, Color color, BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyLarge!.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: textTheme.bodyLarge!.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

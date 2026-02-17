import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../player_stats.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final stats = ref.watch(playerStatsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'GAME STATS',
          style: textTheme.titleLarge!,
        ),
        centerTitle: true,
      ),
      body: CBNeonBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: CBInsets.panel,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CBPanel(
                    borderColor: scheme.primary.withValues(alpha: 0.4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CBSectionHeader(
                          title: "CAREER METRICS",
                          icon: Icons.show_chart_rounded,
                          color: scheme.primary,
                        ),
                        const SizedBox(height: CBSpace.x4),
                        _buildStatRow(
                          "GAMES PLAYED",
                          "${stats.gamesPlayed}",
                          scheme.secondary,
                          context,
                        ),
                        const SizedBox(height: CBSpace.x3),
                        _buildStatRow(
                          "GAMES WON",
                          "${stats.gamesWon}",
                          scheme.primary,
                          context,
                        ),
                        const SizedBox(height: CBSpace.x3),
                        _buildStatRow(
                          "WIN RATE",
                          "${stats.winRate.toStringAsFixed(0)}%",
                          scheme.tertiary,
                          context,
                        ),
                        const SizedBox(height: CBSpace.x3),
                        _buildStatRow(
                          "FAVORITE ROLE",
                          stats.favoriteRole.toUpperCase(),
                          scheme.primary,
                          context,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: CBSpace.x6),
                  CBPrimaryButton(
                    label: 'VIEW HALL OF FAME',
                    onPressed: () {
                      Navigator.pushNamed(context, '/hall-of-fame');
                    },
                  ),
                ],
              ),
            ),
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

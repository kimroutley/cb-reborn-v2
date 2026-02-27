import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../player_destinations.dart';
import '../player_navigation.dart';
import '../player_stats.dart';
import '../widgets/custom_drawer.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final stats = ref.watch(playerStatsProvider);

    return CBPrismScaffold(
      title: 'GAME STATS',
      drawer: const CustomDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CBFadeSlide(
                child: CBPanel(
                  borderColor: scheme.primary.withValues(alpha: 0.4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CBSectionHeader(
                        title: "CAREER METRICS",
                        icon: Icons.show_chart_rounded,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: CBSpace.x6),
                      _buildStatRow(
                        "GAMES PLAYED",
                        "${stats.gamesPlayed}",
                        scheme.secondary,
                        context,
                      ),
                      const SizedBox(height: CBSpace.x4),
                      _buildStatRow(
                        "GAMES WON",
                        "${stats.gamesWon}",
                        scheme.primary,
                        context,
                      ),
                      const SizedBox(height: CBSpace.x4),
                      _buildStatRow(
                        "WIN RATE",
                        "${stats.winRate.toStringAsFixed(0)}%",
                        scheme.tertiary,
                        context,
                      ),
                      const SizedBox(height: CBSpace.x4),
                      _buildStatRow(
                        "FAVORITE ROLE",
                        stats.favoriteRole.toUpperCase(),
                        scheme.primary,
                        context,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: CBSpace.x8),
              CBFadeSlide(
                delay: const Duration(milliseconds: 100),
                child: CBGlassTile(
                  isPrismatic: true,
                  onTap: () {
                    ref
                        .read(playerNavigationProvider.notifier)
                        .setDestination(PlayerDestination.hallOfFame);
                  },
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events_rounded,
                          color: scheme.primary, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "VIEW HALL OF FAME",
                              style: textTheme.labelLarge!.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              "Check your awards and standing",
                              style: textTheme.bodySmall!.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: scheme.primary),
                    ],
                  ),
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
          style: textTheme.labelMedium!.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 1.1,
          ),
        ),
        Text(
          value,
          style: textTheme.headlineSmall!.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            shadows: CBColors.textGlow(color, intensity: 0.4),
          ),
        ),
      ],
    );
  }
}

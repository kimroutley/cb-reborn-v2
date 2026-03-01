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
      title: 'OPERATIVE STATS',
      drawer: const CustomDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CBFadeSlide(
                child: CBPanel(
                  borderColor: scheme.primary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CBSectionHeader(
                        title: "PERFORMANCE METRICS",
                        icon: Icons.analytics_rounded,
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 32),
                      _buildStatRow(
                        "GAMES PLAYED",
                        "${stats.gamesPlayed}",
                        scheme.secondary,
                        context,
                      ),
                      const SizedBox(height: 20),
                      _buildStatRow(
                        "GAMES WON",
                        "${stats.gamesWon}",
                        scheme.primary,
                        context,
                      ),
                      const SizedBox(height: 20),
                      _buildStatRow(
                        "WIN RATE",
                        "${stats.winRate.toStringAsFixed(0)}%",
                        scheme.tertiary,
                        context,
                      ),
                      const SizedBox(height: 20),
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
              const SizedBox(height: 32),
              CBFadeSlide(
                delay: const Duration(milliseconds: 150),
                child: CBGlassTile(
                  isPrismatic: true,
                  padding: const EdgeInsets.all(20),
                  borderColor: scheme.primary.withValues(alpha: 0.5),
                  onTap: () {
                    HapticService.medium();
                    ref
                        .read(playerNavigationProvider.notifier)
                        .setDestination(PlayerDestination.hallOfFame);
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.emoji_events_rounded,
                            color: scheme.primary, size: 28),
                      ),
                      const SizedBox(width: 20),
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
                            const SizedBox(height: 4),
                            Text(
                              "CHECK YOUR AWARDS AND RANKINGS",
                              style: textTheme.bodySmall!.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
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
            color: scheme.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1.5,
            fontWeight: FontWeight.w900,
            fontSize: 10,
          ),
        ),
        Text(
          value,
          style: textTheme.headlineSmall!.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            fontFamily: 'RobotoMono',
            shadows: CBColors.textGlow(color, intensity: 0.3),
          ),
        ),
      ],
    );
  }
}

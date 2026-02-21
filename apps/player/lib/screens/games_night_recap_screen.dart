import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_drawer.dart';

class GamesNightRecapScreen extends StatelessWidget {
  final GamesNightRecord session;
  final List<GameRecord> games;

  const GamesNightRecapScreen({
    super.key,
    required this.session,
    required this.games,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sortedGames = List<GameRecord>.from(games)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: Text(
          'SESSION RECAP',
          style: Theme.of(context).textTheme.titleLarge!,
        ),
        centerTitle: true,
      ),
      body: CBNeonBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Session Header
                CBGlassTile(
                  borderColor: scheme.primary,
                  isPrismatic: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: scheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              session.sessionName.toUpperCase(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        DateFormat('MMM dd, yyyy').format(session.startedAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.primary),
                      ),
                      const SizedBox(height: 16),
                      _buildStatsSummary(context, scheme),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Games List
                CBSectionHeader(
                  title: 'GAMES PLAYED',
                  icon: Icons.sports_esports,
                  count: sortedGames.length,
                ),
                const SizedBox(height: 16),

                if (sortedGames.isEmpty)
                  CBPanel(
                    child: Text(
                      "No games recorded for this session.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                  )
                else
                  ...sortedGames.asMap().entries.map((entry) {
                    // Since we sorted descending, the game number should probably be calculated based on original index or total - index?
                    // Or just use the original list index.
                    // If we want "Game 1" to be the first game, we should use the index from the sorted list if we want it reversed?
                    // Let's just say "Game X" where X corresponds to the order played.
                    // sortedGames is latest first. So index 0 is Game N.
                    final index = entry.key;
                    final game = entry.value;
                    final gameNumber = games.length - index;
                    return _buildGameTile(context, gameNumber, game, scheme);
                  }),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context, ColorScheme scheme) {
    final partyWins = games.where((g) => g.winner == Team.partyAnimals).length;
    final staffWins = games.where((g) => g.winner == Team.clubStaff).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            "PARTY ANIMALS",
            partyWins,
            scheme.primary, // Turquoise/Blue
            scheme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            "CLUB STAFF",
            staffWins,
            scheme.secondary, // Pink/Magenta
            scheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    int value,
    Color color,
    ColorScheme scheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: CBColors.boxGlow(color, intensity: 0.2),
      ),
      child: Column(
        children: [
          Text(value.toString(), style: CBTypography.h2.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            style: CBTypography.micro.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile(
      BuildContext context, int number, GameRecord game, ColorScheme scheme) {
    final isPartyWin = game.winner == Team.partyAnimals;
    final winColor = isPartyWin ? scheme.primary : scheme.secondary;
    final winnerName = isPartyWin ? "PARTY ANIMALS" : "CLUB STAFF";
    final duration = game.endedAt.difference(game.startedAt);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final durationStr = "${minutes}m ${seconds}s";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CBGlassTile(
        borderColor: winColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isPartyWin ? Icons.celebration : Icons.security,
                    color: winColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GAME • ${game.dayCount} ROUNDS',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'WINNER: $winnerName • $durationStr',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: winColor),
            ),
            const SizedBox(height: 12),
            Text("ROSTER (${game.playerCount})",
                style: CBTypography.labelSmall
                    .copyWith(color: scheme.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: game.roster
                  .map((p) => CBBadge(
                      text: p.name,
                      color: p.alive
                          ? scheme.primary
                          : scheme.error.withValues(alpha: 0.7)))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }
}

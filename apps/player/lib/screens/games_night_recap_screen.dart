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

    return CBPrismScaffold(
      title: 'SESSION RECAP',
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x5, vertical: CBSpace.x6),
        physics: const BouncingScrollPhysics(),
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
                          const SizedBox(width: CBSpace.x3),
                          Expanded(
                            child: Text(
                              session.sessionName.toUpperCase(),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: CBSpace.x2),
                      Text(
                        DateFormat('MMM dd, yyyy').format(session.startedAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: CBSpace.x4),
                      _buildStatsSummary(context, scheme),
                    ],
                  ),
                ),
                const SizedBox(height: CBSpace.x8),

                // Games List
                CBSectionHeader(
                  title: 'GAMES PLAYED',
                  icon: Icons.sports_esports,
                  count: sortedGames.length,
                ),
                const SizedBox(height: CBSpace.x4),

                if (sortedGames.isEmpty)
                  CBPanel(
                    child: Text(
                      "NO GAMES RECORDED FOR THIS SESSION.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                    ),
                  )
                else
                  ...sortedGames.asMap().entries.map((entry) {
                    final index = entry.key;
                    final game = entry.value;
                    final gameNumber = games.length - index;
                    return _buildGameTile(context, gameNumber, game, scheme);
                  }),

                const SizedBox(height: CBSpace.x12),
              ],
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
        const SizedBox(width: CBSpace.x4),
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
    return CBPanel(
      borderColor: color.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(CBSpace.x3),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value.toString(), style: CBTypography.h2.copyWith(
            color: color,
            shadows: CBColors.textGlow(color, intensity: 0.4),
          )),
          const SizedBox(height: CBSpace.x1),
          Text(
            label,
            style: CBTypography.micro.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
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
    final durationStr = "${minutes}M ${seconds}S";

    return Padding(
      padding: const EdgeInsets.only(bottom: CBSpace.x3),
      child: CBGlassTile(
        borderColor: winColor.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isPartyWin ? Icons.celebration : Icons.security,
                    color: winColor),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: Text(
                    'GAME $number • ${game.dayCount} ROUNDS',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CBSpace.x2),
            Text(
              'WINNER: $winnerName • $durationStr',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                    color: winColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: CBSpace.x4),
            Text("ROSTER (${game.playerCount})",
                style: CBTypography.labelSmall
                    .copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    )),
            const SizedBox(height: CBSpace.x2),
            Wrap(
              spacing: CBSpace.x2,
              runSpacing: CBSpace.x2,
              children: game.roster
                  .map((p) => CBBadge(
                      text: p.name.toUpperCase(),
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

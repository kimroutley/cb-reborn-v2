import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final totalGames = games.length;
    final wins = games.where((g) => g.winner == Team.partyAnimals).length;

    return CBPrismScaffold(
      title: 'SESSION RECAP',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // Header Stats
          CBGlassTile(
            title: session.sessionName,
            subtitle: DateFormat('MMM dd, yyyy').format(session.startedAt),
            accentColor: scheme.primary,
            isPrismatic: true,
            icon: Icon(Icons.calendar_today, color: scheme.primary),
            content: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(context, 'GAMES', '$totalGames', scheme.primary),
                  _statItem(context, 'WINS', '$wins', scheme.tertiary),
                  _statItem(
                      context, 'LOSSES', '${totalGames - wins}', scheme.error),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Games List
          CBSectionHeader(title: 'GAMES PLAYED', color: scheme.tertiary),
          const SizedBox(height: 16),

          if (games.isEmpty)
            CBPanel(
                child: Text("No games recorded for this session.",
                    style: Theme.of(context).textTheme.bodyMedium)),

          ...games.asMap().entries.map((entry) {
            final index = entry.key;
            final game = entry.value;
            return _buildGameTile(context, index + 1, game, scheme);
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _statItem(
      BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: CBTypography.h2.copyWith(color: color)),
        Text(label, style: CBTypography.micro.copyWith(letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildGameTile(
      BuildContext context, int number, GameRecord game, ColorScheme scheme) {
    final isPaWin = game.winner == Team.partyAnimals;
    final color = isPaWin ? scheme.tertiary : scheme.error;
    final icon = isPaWin ? Icons.emoji_events : Icons.warning_amber_rounded;
    final duration = game.endedAt.difference(game.startedAt);
    final durationStr = '${duration.inMinutes}m';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CBGlassTile(
        title: 'GAME $number',
        subtitle:
            '${isPaWin ? "PARTY ANIMALS" : "CLUB STAFF"} WON • $durationStr',
        accentColor: color,
        icon: Icon(icon, color: color),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

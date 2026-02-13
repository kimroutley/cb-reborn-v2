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
    final sortedGames = List<GameRecord>.from(games)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

    return CBPrismScaffold(
      title: 'SESSION RECAP',
      showAppBar: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CBSpace.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session Header
            Text(
              session.sessionName.toUpperCase(),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                    shadows: CBColors.textGlow(scheme.primary),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDateRange(session.startedAt, session.endedAt),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                    letterSpacing: 1.2,
                  ),
            ),
            const SizedBox(height: 24),

            // Stats Summary
            _buildStatsSummary(context, scheme),

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
                      color: scheme.onSurface.withValues(alpha: 0.7)),
                ),
              )
            else
              ...sortedGames
                  .map((game) => _buildGameTile(context, game, scheme)),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    final startStr = DateFormat('MMMM d, yyyy').format(start).toUpperCase();
    if (end == null) return '$startStr (ACTIVE)';

    if (start.day == end.day &&
        start.month == end.month &&
        start.year == end.year) {
      return startStr;
    }
    return '$startStr - ${DateFormat('MMMM d').format(end).toUpperCase()}';
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
            scheme.primary, // Turquoise/Blue for Party Animals
            scheme,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context,
            "CLUB STAFF",
            staffWins,
            scheme.secondary, // Pink/Magenta for Club Staff
            scheme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, int value,
      Color color, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        boxShadow: CBColors.boxGlow(color, intensity: 0.2),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: CBTypography.h2.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: CBTypography.micro
                .copyWith(color: scheme.onSurface.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGameTile(
      BuildContext context, GameRecord game, ColorScheme scheme) {
    final isPartyWin = game.winner == Team.partyAnimals;
    final winColor = isPartyWin ? scheme.primary : scheme.secondary;
    final winnerName = isPartyWin ? "PARTY ANIMALS" : "CLUB STAFF";

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
        title: "GAME • ${game.dayCount} ROUNDS",
        subtitle: "WINNER: $winnerName • ${game.playerCount} PLAYERS",
        accentColor: winColor,
        icon: Icon(isPartyWin ? Icons.celebration : Icons.security,
            color: winColor),
        isPrismatic: true,
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(context, "DURATION",
                  _formatDuration(game.startedAt, game.endedAt), scheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, ColorScheme scheme) {
    return Row(
      children: [
        Text(
          "$label: ",
          style: CBTypography.micro
              .copyWith(color: scheme.onSurface.withValues(alpha: 0.5)),
        ),
        Text(
          value,
          style: CBTypography.micro.copyWith(color: scheme.onSurface),
        ),
      ],
    );
  }

  String _formatDuration(DateTime start, DateTime end) {
    final d = end.difference(start);
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return "${minutes}m ${seconds}s";
  }
}

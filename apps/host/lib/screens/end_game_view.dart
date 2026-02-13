import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class EndGameView extends StatelessWidget {
  final GameState gameState;
  final Game controller;

  const EndGameView({
    super.key,
    required this.gameState,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final winner = gameState.winner;
    final winnerName = switch (winner) {
      Team.clubStaff => 'CLUB STAFF',
      Team.partyAnimals => 'PARTY ANIMALS',
      Team.neutral => 'NEUTRAL',
      Team.unknown || null => 'UNKNOWN',
    };
    final winColor = switch (winner) {
      Team.clubStaff => scheme.primary,
      Team.partyAnimals => scheme.secondary,
      Team.neutral => CBColors.alertOrange,
      Team.unknown || null => scheme.onSurface.withValues(alpha: 0.55),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Winner Banner
          CBStatusOverlay(
            icon: Icons.emoji_events,
            label: 'GAME OVER',
            color: winColor,
            detail: '$winnerName WIN',
          ),
          // End game report lines
          CBPanel(
            borderColor: winColor,
            child: Column(
              children: [
                for (final line in gameState.endGameReport)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium!,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Player Final Roster
          CBPanel(
            borderColor: scheme.onSurface.withValues(alpha: 0.24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CBBadge(text: 'FINAL ROSTER', color: scheme.primary),
                const SizedBox(height: 12),
                for (final player in gameState.players)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Opacity(
                            opacity: player.isAlive ? 1.0 : 0.4,
                            child: Image.asset(
                              player.role.assetPath,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                player.isAlive
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: player.isAlive
                                    ? scheme.primary
                                    : scheme.secondary,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            player.name,
                            style: textTheme.bodyLarge!.copyWith(
                              color: player.isAlive
                                  ? null
                                  : scheme.onSurface.withValues(alpha: 0.38),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          player.role.name.toUpperCase(),
                          style: textTheme.labelSmall!.copyWith(
                            color: switch (player.alliance) {
                              Team.clubStaff => scheme.primary,
                              Team.partyAnimals => scheme.secondary,
                              Team.neutral => CBColors.alertOrange,
                              Team.unknown =>
                                scheme.onSurface.withValues(alpha: 0.55),
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          switch (player.alliance) {
                            Team.clubStaff => 'STAFF',
                            Team.partyAnimals => 'PA',
                            Team.neutral => 'NEUTRAL',
                            Team.unknown => 'UNKNOWN',
                          },
                          style: textTheme.labelSmall!.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.38),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class EndGameView extends StatelessWidget {
  final GameState gameState;
  final Game controller;
  final VoidCallback onReturnToLobby;
  final VoidCallback onRematchWithPlayers;

  const EndGameView({
    super.key,
    required this.gameState,
    required this.controller,
    required this.onReturnToLobby,
    required this.onRematchWithPlayers,
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

    return CBNeonBackground(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // Winner Banner
          CBStatusOverlay(
            icon: Icons.emoji_events_rounded,
            label: 'GAME OVER',
            color: winColor,
            detail: '$winnerName VICTORY',
          ),
          const SizedBox(height: 24),

          // End game report lines
          CBPanel(
            borderColor: winColor.withValues(alpha: 0.5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CBSectionHeader(
                  title: 'RESOLUTION REPORT',
                  icon: Icons.summarize_rounded,
                  color: winColor,
                ),
                const SizedBox(height: 16),
                for (final line in gameState.endGameReport)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      line,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium!.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Player Final Roster
          CBPanel(
            borderColor: scheme.outlineVariant.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CBSectionHeader(
                  title: 'FINAL ROSTER STATUS',
                  icon: Icons.group_rounded,
                  color: scheme.onSurface,
                ),
                const SizedBox(height: 20),
                for (final player in gameState.players)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CBGlassTile(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      borderColor: player.isAlive ? scheme.tertiary.withValues(alpha: 0.3) : scheme.error.withValues(alpha: 0.3),
                      child: Row(
                        children: [
                          CBRoleAvatar(
                            assetPath: player.role.assetPath,
                            color: CBColors.fromHex(player.role.colorHex),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name.toUpperCase(),
                                  style: textTheme.labelLarge!.copyWith(
                                    color: player.isAlive
                                        ? scheme.onSurface
                                        : scheme.onSurface.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.w900,
                                    decoration: player.isAlive ? null : TextDecoration.lineThrough,
                                  ),
                                ),
                                Text(
                                  player.role.name.toUpperCase(),
                                  style: textTheme.labelSmall!.copyWith(
                                    color: CBColors.fromHex(player.role.colorHex),
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CBBadge(
                            text: switch (player.alliance) {
                              Team.clubStaff => 'STAFF',
                              Team.partyAnimals => 'PARTY',
                              Team.neutral => 'NEUTRAL',
                              Team.unknown => 'UNKNOWN',
                            },
                            color: switch (player.alliance) {
                              Team.clubStaff => scheme.primary,
                              Team.partyAnimals => scheme.secondary,
                              Team.neutral => CBColors.alertOrange,
                              Team.unknown => scheme.onSurface.withValues(alpha: 0.5),
                            },
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            player.isAlive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: player.isAlive ? scheme.tertiary : scheme.error,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          CBPrimaryButton(
            label: 'REMATCH',
            icon: Icons.replay_rounded,
            onPressed: onRematchWithPlayers,
          ),
          const SizedBox(height: 10),
          CBGhostButton(
            label: 'RETURN TO LOBBY',
            icon: Icons.refresh_rounded,
            onPressed: onReturnToLobby,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

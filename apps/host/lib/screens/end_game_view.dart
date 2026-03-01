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

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Winner Banner
          CBFadeSlide(
            child: CBStatusOverlay(
              icon: Icons.emoji_events_rounded,
              label: 'GAME OVER',
              color: winColor,
              detail: '$winnerName VICTORY',
            ),
          ),
          const SizedBox(height: 32),

          // End game report lines
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: CBPanel(
              borderColor: winColor.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CBSectionHeader(
                    title: 'RESOLUTION REPORT',
                    icon: Icons.summarize_rounded,
                    color: winColor,
                  ),
                  const SizedBox(height: 20),
                  for (final line in gameState.endGameReport)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        line,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Player Final Roster
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: CBPanel(
              borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CBSectionHeader(
                    title: 'FINAL OPERATIVE STATUS',
                    icon: Icons.group_rounded,
                    color: scheme.onSurface,
                  ),
                  const SizedBox(height: 24),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gameState.players.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final player = gameState.players[index];
                      final roleColor = CBColors.fromHex(player.role.colorHex);
                      final isWinner = player.alliance == winner;

                      return CBGlassTile(
                        padding: const EdgeInsets.all(12),
                        isPrismatic: isWinner,
                        borderColor: player.isAlive
                            ? scheme.tertiary.withValues(alpha: 0.3)
                            : scheme.error.withValues(alpha: 0.3),
                        child: Row(
                          children: [
                            CBRoleAvatar(
                              assetPath: player.role.assetPath,
                              color: roleColor,
                              size: 40,
                              pulsing: isWinner && player.isAlive,
                            ),
                            const SizedBox(width: 16),
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
                                      letterSpacing: 1.0,
                                      decoration: player.isAlive
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  CBMiniTag(
                                    text: player.role.name.toUpperCase(),
                                    color: roleColor,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
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
                                    Team.unknown =>
                                      scheme.onSurface.withValues(alpha: 0.5),
                                  },
                                ),
                                const SizedBox(height: 6),
                                Icon(
                                  player.isAlive
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded,
                                  color:
                                      player.isAlive ? scheme.tertiary : scheme.error,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          CBFadeSlide(
            delay: const Duration(milliseconds: 300),
            child: CBPrimaryButton(
              label: 'START REMATCH',
              icon: Icons.replay_rounded,
              onPressed: () {
                HapticService.heavy();
                onRematchWithPlayers();
              },
            ),
          ),
          const SizedBox(height: 12),
          CBFadeSlide(
            delay: const Duration(milliseconds: 400),
            child: CBGhostButton(
              label: 'RETURN TO LOBBY',
              icon: Icons.refresh_rounded,
              onPressed: () {
                HapticService.medium();
                onReturnToLobby();
              },
            ),
          ),
        ],
      ),
    );
  }
}

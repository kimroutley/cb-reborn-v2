import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_bridge_actions.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import 'custom_drawer.dart';

class GhostLoungeContent extends StatelessWidget {
  final PlayerGameState gameState;
  final PlayerSnapshot player;
  final String playerId;
  final PlayerBridgeActions bridge;

  const GhostLoungeContent({
    super.key,
    required this.gameState,
    required this.player,
    required this.playerId,
    required this.bridge,
  });

  @override
  Widget build(BuildContext context) {
    final aliveTargets = gameState.players.where((p) => p.isAlive).toList();
    final currentBetTarget = player.currentBetTargetId == null
        ? null
        : gameState.players
            .where((p) => p.id == player.currentBetTargetId)
            .map((p) => p.name)
            .cast<String?>()
            .firstWhere((_) => true, orElse: () => null);

    final roster = gameState.players
        .map((p) => (
              name: p.name,
              role: p.roleName,
              color: CBColors.fromHex(p.roleColorHex),
              isAlive: p.isAlive,
            ))
        .toList();

    return CBPrismScaffold(
      title: "GHOST LOUNGE",
      drawer: const CustomDrawer(),
      body: CBGhostLoungeView(
        playerRoster: roster,
        lastWords: player.deathDay != null
            ? "ELIMINATED ON DAY ${player.deathDay}"
            : "SILENCED FROM BEYOND",
        currentBetTargetName: currentBetTarget,
        bettingHistory: player.penalties
            .where((entry) => entry.contains('[DEAD POOL]'))
            .toList(),
        ghostMessages: gameState.ghostChatMessages,
        onPlaceBet: aliveTargets.isEmpty
            ? null
            : () {
                showThemedBottomSheet<void>(
                  context: context,
                  accentColor: Theme.of(context).colorScheme.error,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'PLACE DEAD POOL BET',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ...aliveTargets.map(
                        (target) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CBPrimaryButton(
                            label: target.name.toUpperCase(),
                            onPressed: () {
                              bridge.placeDeadPoolBet(
                                playerId: playerId,
                                targetPlayerId: target.id,
                              );
                              Navigator.pop(context);
                              HapticService.selection();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
        onSendGhostMessage: (text) {
          bridge.sendGhostChat(
            playerId: playerId,
            playerName: player.name,
            message: text,
          );
          HapticService.selection();
        },
      ),
    );
  }
}

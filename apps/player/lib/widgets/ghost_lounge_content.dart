import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_bridge_actions.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'custom_drawer.dart';

class GhostLoungeContent extends StatelessWidget {
  final PlayerGameState gameState;
  final String playerId;
  final PlayerBridgeActions bridge;

  const GhostLoungeContent({
    super.key,
    required this.gameState,
    required this.playerId,
    required this.bridge,
  });

  @override
  Widget build(BuildContext context) {
    final playersById = {
      for (final p in gameState.players) p.id: p,
    };
    final aliveTargets = gameState.players
        .where((p) => p.isAlive)
        .map(
          (p) => GhostLoungeTarget(id: p.id, name: p.name),
        )
        .toList();

<<<<<<< ui-polish-host-player-9962985775398423612
    return CBPrismScaffold(
      title: "GHOST LOUNGE",
      drawer: const CustomDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'WELCOME TO THE GHOST LOUNGE',
              style: textTheme.headlineSmall!.copyWith(
                color: scheme.onSurface,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            if (aliveTargets.isNotEmpty)
              CBPrimaryButton(
                label: 'PLACE DEAD POOL BET',
                onPressed: () {
                  showThemedBottomSheet<void>(
                    context: context,
                    accentColor: scheme.error,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'PLACE DEAD POOL BET',
                          style: textTheme.headlineSmall,
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
                                HapticFeedback.selectionClick();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
=======
    final betCounts = <String, int>{};
    for (final entry in gameState.deadPoolBets.entries) {
      betCounts[entry.value] = (betCounts[entry.value] ?? 0) + 1;
    }

    final activeBets = gameState.deadPoolBets.entries
        .map(
          (entry) => GhostLoungeBet(
            bettorName: playersById[entry.key]?.name ?? entry.key,
            targetName: playersById[entry.value]?.name ?? entry.value,
            oddsCount: betCounts[entry.value] ?? 0,
          ),
        )
        .toList();

    final myBetTargetId = gameState.deadPoolBets[playerId];
    final myBetTargetName = myBetTargetId == null
        ? null
        : (playersById[myBetTargetId]?.name ?? myBetTargetId);

    return GhostLoungeView(
      aliveTargets: aliveTargets,
      activeBets: activeBets,
      currentBetTargetName: myBetTargetName,
      onPlaceBet: (targetId) {
        bridge.placeDeadPoolBet(
          playerId: playerId,
          targetPlayerId: targetId,
        );
        HapticFeedback.selectionClick();
      },
>>>>>>> main
    );
  }
}

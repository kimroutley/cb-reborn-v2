import 'package:cb_player/player_bridge_actions.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("GHOST LOUNGE"),
      ),
      body: CBNeonBackground(
        child: Center(
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
                  label: 'Place Dead Pool Bet',
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
      ),
    );
  }
}

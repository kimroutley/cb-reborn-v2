import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import '../widgets/roster_tile.dart';

void showPlayerRoster(
  BuildContext context,
  GameState gameState,
  List<String> claimedIds,
) {
  showThemedBottomSheetBuilder<void>(
    context: context,
    accentColor: CBColors.matrixGreen,
    padding: EdgeInsets.zero,
    wrapInScrollView: false,
    addHandle: false,
    builder: (ctx) {
      final alive = gameState.players.where((p) => p.isAlive).toList();
      final dead = gameState.players.where((p) => !p.isAlive).toList();
      final isInGame = gameState.phase != GamePhase.lobby;
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) {
          return ListView(
            controller: scrollController,
            padding: CBInsets.screenH,
            children: [
              const CBBottomSheetHandle(
                margin: EdgeInsets.only(top: CBSpace.x3, bottom: CBSpace.x3),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: CBSpace.x2),
                child: CBSectionHeader(title: 'ALIVE', count: alive.length),
              ),
              for (final p in alive)
                RosterTile(
                  player: p,
                  showKill: isInGame,
                  isClaimed: claimedIds.contains(p.id),
                ),
              if (dead.isNotEmpty) ...[
                const SizedBox(height: CBSpace.x3),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: CBSpace.x2),
                  child: CBSectionHeader(
                    title: 'ELIMINATED',
                    count: dead.length,
                  ),
                ),
                for (final p in dead)
                  RosterTile(
                    player: p,
                    isClaimed: claimedIds.contains(p.id),
                  ),
              ],
              const SizedBox(height: CBSpace.x4),
            ],
          );
        },
      );
    },
  );
}

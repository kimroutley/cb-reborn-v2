import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import '../widgets/bottom_controls.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';
import 'end_game_view.dart';
import 'logs_view.dart';
import 'stats_view.dart';

class HostGameScreen extends ConsumerWidget {
  const HostGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final nav = ref.read(hostNavigationProvider.notifier);

    final isEndGame = gameState.phase == GamePhase.endGame;

    return CBPrismScaffold(
      title: 'GAME CONTROL',
      drawer: const CustomDrawer(currentDestination: HostDestination.game),
      actions: [
        IconButton(
          tooltip: 'View Analytics',
          icon: const Icon(Icons.analytics_outlined),
          onPressed: () {
            showThemedDialog(
              context: context,
              child: StatsView(
                gameState: gameState,
                onOpenCommand: () => Navigator.of(context).pop(),
              ),
            );
          },
        ),
        const SimulationModeBadgeAction(),
      ],
      body: isEndGame
          ? EndGameView(
              gameState: gameState,
              controller: controller,
              onReturnToLobby: () {
                controller.returnToLobby();
                nav.setDestination(HostDestination.lobby);
              },
            )
          : Column(
              children: [
                if (gameState.phase == GamePhase.lobby)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: CBGlassTile(
                      borderColor: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Game Control is active. Start game from Lobby when roster is ready.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.82),
                                  ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                nav.setDestination(HostDestination.lobby),
                            icon: const Icon(Icons.rocket_launch_rounded,
                                size: 16),
                            label: const Text('Lobby'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: LogsView(
                    gameState: gameState,
                    onOpenCommand: () {},
                  ),
                ),
                BottomControls(
                  isLobby: false,
                  isEndGame: false,
                  playerCount: gameState.players.length,
                  onAction: gameState.phase == GamePhase.lobby
                      ? () => nav.setDestination(HostDestination.lobby)
                      : controller.advancePhase,
                  onAddMock: controller.addBot,
                  eyesOpen: gameState.eyesOpen,
                  onToggleEyes: controller.toggleEyes,
                  onBack: () => nav.setDestination(HostDestination.lobby),
                  requiredPlayers: Game.minPlayers,
                )
              ],
            ),
    );
  }
}

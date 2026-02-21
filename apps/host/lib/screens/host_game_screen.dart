import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';
import 'dashboard_view.dart';
import 'end_game_view.dart';
import 'host_lobby_screen.dart';
import 'logs_view.dart';
import 'stats_view.dart';

class HostGameScreen extends ConsumerWidget {
  const HostGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final nav = ref.read(hostNavigationProvider.notifier);

    if (gameState.phase == GamePhase.lobby) {
      return const HostLobbyScreen();
    }

    final isEndGame = gameState.phase == GamePhase.endGame;

    return CBPrismScaffold(
      title: 'GAME',
      drawer: const CustomDrawer(currentDestination: HostDestination.game),
      actions: const [SimulationModeBadgeAction()],
      body: isEndGame
          ? EndGameView(
              gameState: gameState,
              controller: controller,
              onReturnToLobby: () {
                controller.returnToLobby();
                nav.setDestination(HostDestination.lobby);
              },
            )
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Command'),
                      Tab(text: 'Logs'),
                      Tab(text: 'Analytics'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        DashboardView(
                          gameState: gameState,
                          onAction: controller.advancePhase,
                          onAddMock: controller.addBot,
                          eyesOpen: gameState.eyesOpen,
                          onToggleEyes: controller.toggleEyes,
                          onBack: () => nav.setDestination(HostDestination.lobby),
                        ),
                        Builder(
                          builder: (tabContext) => LogsView(
                            gameState: gameState,
                            onOpenCommand: () =>
                                DefaultTabController.of(tabContext).animateTo(0),
                          ),
                        ),
                        Builder(
                          builder: (tabContext) => StatsView(
                            gameState: gameState,
                            onOpenCommand: () =>
                                DefaultTabController.of(tabContext).animateTo(0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

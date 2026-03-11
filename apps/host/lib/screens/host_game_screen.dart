import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';
import '../widgets/host_main_feed.dart';
import 'end_game_view.dart';
import 'stats_view.dart';

class HostGameScreen extends ConsumerWidget {
  const HostGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final nav = ref.read(hostNavigationProvider.notifier);

    final isEndGame = gameState.phase == GamePhase.endGame;

    if (isEndGame) {
      return CBPrismScaffold(
        title: 'GAME RECAP',
        body: EndGameView(
          gameState: gameState,
          controller: controller,
          onReturnToLobby: () {
            controller.returnToLobby();
            nav.setDestination(HostDestination.lobby);
          },
          onRematchWithPlayers: () {
            controller.returnToLobbyWithPlayers();
            nav.setDestination(HostDestination.lobby);
          },
        ),
      );
    }

    return CBPrismScaffold(
      title: 'GAME CONTROL',
      appBar: CBMessagingAppBar(
        title: 'MISSION TERMINAL',
        subtitle: 'PHASE: ${gameState.phase.name.toUpperCase()} • DAY ${gameState.dayCount}',
        avatar: CircleAvatar(
          radius: 18,
          backgroundColor: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
          child: Icon(Icons.admin_panel_settings_rounded, color: Theme.of(context).colorScheme.tertiary, size: 20),
        ),
        showBackButton: false,
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
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: const CustomDrawer(currentDestination: HostDestination.game),
      body: CBPhaseOverlay(
        isNight: gameState.phase == GamePhase.night,
        child: HostMainFeed(gameState: gameState),
      ),
    );
  }
}

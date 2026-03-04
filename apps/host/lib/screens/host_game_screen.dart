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
import 'dashboard_view.dart';
import 'end_game_view.dart';
import 'stats_view.dart';

class HostGameScreen extends ConsumerWidget {
  const HostGameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final controller = ref.read(gameProvider.notifier);
    final nav = ref.read(hostNavigationProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

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

    final isMobile = MediaQuery.sizeOf(context).width < 800;

    return DefaultTabController(
      length: 2,
      child: CBPrismScaffold(
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
        appBarBottom: isMobile
            ? TabBar(
                indicatorColor: scheme.primary,
                labelColor: scheme.primary,
                tabs: const [
                  Tab(text: 'FEED', icon: Icon(Icons.chat_bubble_outline_rounded, size: 18)),
                  Tab(text: 'DASHBOARD', icon: Icon(Icons.dashboard_customize_rounded, size: 18)),
                ],
              )
            : null,
        body: CBPhaseOverlay(
          isNight: gameState.phase == GamePhase.night,
          child: isMobile
              ? TabBarView(
                  children: [
                    HostMainFeed(gameState: gameState),
                    _buildDashboard(context, gameState, controller, nav, scheme),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: HostMainFeed(gameState: gameState)),
                    Expanded(
                      child: _buildDashboard(context, gameState, controller, nav, scheme),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    GameState gameState,
    Game controller,
    HostNavigationNotifier nav,
    ColorScheme scheme,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.radar_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 12),
              Text(
                'NERVE CENTRE DASHBOARD',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      shadows: CBColors.textGlow(scheme.primary, intensity: 0.3),
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: DashboardView(
              gameState: gameState,
              onAction: controller.advancePhase,
              onAddMock: controller.addBot,
              eyesOpen: gameState.eyesOpen,
              onToggleEyes: controller.toggleEyes,
              onBack: () => nav.setDestination(HostDestination.lobby),
            ),
          ),
        ),
      ],
    );
  }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../player_destinations.dart';
import '../player_navigation.dart';
import '../active_bridge.dart';
import 'home_screen.dart';
import 'lobby_screen.dart';
import 'claim_screen.dart';
import 'game_screen.dart';
import 'guides_screen.dart';
import 'games_night_screen.dart';
import 'hall_of_fame_screen.dart';
import 'stats_screen.dart';

class PlayerHomeShell extends ConsumerWidget {
  const PlayerHomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(playerNavigationProvider);

    // Auto-sync navigation based on game state
    ref.listen(activeBridgeProvider, (previous, next) {
      final prevPhase = previous?.state.phase;
      final nextPhase = next.state.phase;
      final nextConnected = next.state.isConnected;

      if (!nextConnected) {
        ref.read(playerNavigationProvider.notifier).setDestination(PlayerDestination.home);
      } else if (nextPhase != prevPhase) {
        switch (nextPhase) {
          case 'lobby':
            ref.read(playerNavigationProvider.notifier).setDestination(PlayerDestination.lobby);
            break;
          case 'setup':
            ref.read(playerNavigationProvider.notifier).setDestination(PlayerDestination.claim);
            break;
          case 'active':
          case 'recap':
            ref.read(playerNavigationProvider.notifier).setDestination(PlayerDestination.game);
            break;
        }
      }
    });

    Widget activeWidget;
    switch (destination) {
      case PlayerDestination.home:
        activeWidget = const HomeScreen();
        break;
      case PlayerDestination.lobby:
        activeWidget = const LobbyScreen();
        break;
      case PlayerDestination.claim:
        activeWidget = const ClaimScreen();
        break;
      case PlayerDestination.game:
        activeWidget = const GameScreen();
        break;
      case PlayerDestination.guides:
        activeWidget = const GuidesScreen();
        break;
      case PlayerDestination.gamesNight:
        activeWidget = const GamesNightScreen();
        break;
      case PlayerDestination.hallOfFame:
        activeWidget = const HallOfFameScreen();
        break;
      case PlayerDestination.stats:
        activeWidget = const StatsScreen();
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(destination),
        child: activeWidget,
      ),
    );
  }
}

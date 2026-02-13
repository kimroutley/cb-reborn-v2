import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_bridge_actions.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'claim_screen.dart';
import 'game_screen.dart';
import 'home_screen.dart';

class GameRouter extends ConsumerStatefulWidget {
  const GameRouter({super.key});

  @override
  ConsumerState<GameRouter> createState() => _GameRouterState();
}

class _GameRouterState extends ConsumerState<GameRouter> {
  void _handleNavigation(
      BuildContext context, PlayerGameState gameState, bool isCloud, WidgetRef ref) {
    final PlayerBridgeActions bridge = isCloud
        ? ref.read(cloudPlayerBridgeProvider.notifier)
        : ref.read(playerBridgeProvider.notifier);

    if (gameState.joinAccepted) {
      if (gameState.isPlayerClaimed) {
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/game'),
            builder: (context) => GameScreen(
              bridge: bridge,
              gameState: gameState,
              player: gameState.myPlayerSnapshot!,
              playerId: gameState.myPlayerId!,
            ),
          ),
          (route) => route.isFirst,
        );

      } else {
         if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/claim'),
            builder: (context) => ClaimScreen(
              isCloud: isCloud,
            ),
          ),
        );
      }
    } else {
       if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to cloud bridge
    ref.listen<PlayerGameState>(cloudPlayerBridgeProvider, (previous, next) {
      _handleHaptics(previous, next);

      final wasJoined = previous?.joinAccepted ?? false;
      final isJoined = next.joinAccepted;

      final wasClaimed = previous?.isPlayerClaimed ?? false;
      final isClaimed = next.isPlayerClaimed;

      if (isJoined != wasJoined || isClaimed != wasClaimed) {
        _handleNavigation(context, next, true, ref);
      }
    });

    // Listen to local bridge
    ref.listen<PlayerGameState>(playerBridgeProvider, (previous, next) {
      _handleHaptics(previous, next);

      final wasJoined = previous?.joinAccepted ?? false;
      final isJoined = next.joinAccepted;

      final wasClaimed = previous?.isPlayerClaimed ?? false;
      final isClaimed = next.isPlayerClaimed;

      if (isJoined != wasJoined || isClaimed != wasClaimed) {
        _handleNavigation(context, next, false, ref);
      }
    });

    return const HomeScreen();
  }

  void _handleHaptics(PlayerGameState? previous, PlayerGameState next) {
    // 1. Eyes Toggle
    final wasEyesOpen = previous?.eyesOpen ?? true;
    final isEyesOpen = next.eyesOpen;

    if (wasEyesOpen != isEyesOpen) {
      if (isEyesOpen) {
        HapticService.eyesOpen();
      } else {
        HapticService.eyesClosed();
      }
    }

    // 2. New Bulletin Message (Alert)
    if (previous != null && next.bulletinBoard.length > previous.bulletinBoard.length) {
      final newEntry = next.bulletinBoard.last;
      if (newEntry.type == 'system' || newEntry.type == 'result' || newEntry.type == 'urgent') {
        HapticService.alertDispatch();
      } else {
        HapticService.selection();
      }
    }

    // 3. New Turn (My role action)
    if (next.currentStep != null && next.currentStep != previous?.currentStep) {
      if (next.currentStep!.roleId == next.myPlayerSnapshot?.roleId || next.currentStep!.isVote) {
        HapticService.heavy();
      }
    }
  }
}

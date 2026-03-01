import 'package:cb_theme/cb_theme.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/custom_drawer.dart';

/// Wrapper for CB Guide Screen in player app
/// When accessed from menu/drawer, gameState is null (shows static content)
/// When accessed from game screen, can pass gameState and localPlayer for context-aware strategy
class GuidesScreen extends ConsumerWidget {
  final GameState? gameState;
  final Player? localPlayer;

  const GuidesScreen({super.key, this.gameState, this.localPlayer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    // CBGuideScreen now manages its own Scaffold, but we want to pass the Player Drawer
    if (gameState == null) {
      return CBGuideScreen(
        gameState: gameState,
        localPlayer: localPlayer,
        drawer: const CustomDrawer(),
      );
    }

    // For game context, just return the screen (it handles back button vs drawer internally)
    return CBGuideScreen(
      gameState: gameState,
      localPlayer: localPlayer,
    );
  }
}

import 'package:cb_theme/cb_theme.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';

import '../widgets/custom_drawer.dart';

/// Wrapper for CB Guide Screen in player app
/// When accessed from menu/drawer, gameState is null (shows static content)
/// When accessed from game screen, can pass gameState and localPlayer for context-aware strategy
class GuidesScreen extends StatelessWidget {
  final GameState? gameState;
  final Player? localPlayer;

  const GuidesScreen({super.key, this.gameState, this.localPlayer});

  @override
  Widget build(BuildContext context) {
    // If we have no context, we show the full scaffold with drawer
    if (gameState == null) {
      return CBPrismScaffold(
        title: 'THE BLACKBOOK',
        drawer: const CustomDrawer(),
        body: CBGuideScreen(gameState: gameState, localPlayer: localPlayer),
      );
    }

    // Otherwise rely on CBGuideScreen's internal layout (usually for modal/game usage)
    return CBGuideScreen(gameState: gameState, localPlayer: localPlayer);
  }
}

import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_logic/cb_logic.dart';
import '../host_destinations.dart';
import '../widgets/custom_drawer.dart';

/// Wrapper for CB Guide Screen in host app.
/// This ensures visually mirrored parity with the player app bible.
class GuidesScreen extends ConsumerWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);

    return CBPrismScaffold(
      title: 'THE BLACKBOOK',
      drawer: const CustomDrawer(currentDestination: HostDestination.guides),
      body: CBGuideScreen(
        gameState: gameState,
        localPlayer: null,
      ),
    );
  }
}

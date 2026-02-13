import 'package:cb_player/player_bridge.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/custom_drawer.dart';

class HostOverviewScreen extends ConsumerWidget {
  const HostOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(playerBridgeProvider);
    final scheme = Theme.of(context).colorScheme;

    String connectionStatus;
    Color connectionColor;

    if (gameState.isConnected) {
      connectionStatus = 'CONNECTED';
      connectionColor = scheme.tertiary; // Success green
    } else {
      connectionStatus = 'DISCONNECTED';
      connectionColor = scheme.error; // Error red
    }

    final phaseLabel = gameState.phase.toUpperCase();

    return CBPrismScaffold(
      title: 'HOST OVERVIEW',
      drawer:
          const CustomDrawer(), // Keep as const for now, revisit drawer integration later
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CBSectionHeader(title: 'CONNECTION STATUS', color: connectionColor),
          const SizedBox(height: 16),
          CBGlassTile(
            title: 'HOST CONNECTION',
            subtitle: connectionStatus,
            accentColor: connectionColor,
            icon: Icon(Icons.wifi_rounded, color: connectionColor, size: 24),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phase: $phaseLabel',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Day: ${gameState.dayCount}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.75)),
                ),
                const SizedBox(height: 4),
                Text(
                  'Players: ${gameState.players.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.75)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          CBSectionHeader(title: 'SESSION SNAPSHOT', color: scheme.primary),
          const SizedBox(height: 16),
          CBGlassTile(
            title: 'CURRENT STEP',
            subtitle: gameState.currentStep?.title ?? 'WAITING FOR HOST',
            accentColor: scheme.primary,
            icon: Icon(Icons.settings_input_component_rounded,
                color: scheme.primary, size: 24),
            content: Text(
              gameState.currentStep?.instructionText ??
                  'No active directive yet.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.75)),
            ),
          ),
          const SizedBox(height: 120), // Provide some bottom padding
        ],
      ),
    );
  }
}

import 'package:cb_player/player_bridge.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'HOST OVERVIEW',
          style: Theme.of(context).textTheme.titleLarge!,
        ),
        centerTitle: true,
      ),
      body: CBNeonBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CBSectionHeader(
                  title: 'CONNECTION STATUS', color: connectionColor),
              const SizedBox(height: 16),
              CBGlassTile(
                borderColor: connectionColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wifi_rounded,
                            color: connectionColor, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('HOST CONNECTION',
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(connectionStatus,
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: connectionColor)),
                    const SizedBox(height: 10),
                    Text(
                      'Phase: $phaseLabel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75)),
                    ),
                    if (gameState.hostName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Host: ${gameState.hostName}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color:
                                      scheme.onSurface.withValues(alpha: 0.75)),
                        ),
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
                borderColor: scheme.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings_input_component_rounded,
                            color: scheme.primary, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('CURRENT STEP',
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      gameState.currentStep?.title ?? 'WAITING FOR HOST',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: scheme.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gameState.currentStep?.instructionText ??
                          'No active directive yet.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 120), // Provide some bottom padding
            ],
          ),
        ),
      ),
    );
  }
}

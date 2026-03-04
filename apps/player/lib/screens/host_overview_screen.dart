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
    final textTheme = Theme.of(context).textTheme;

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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x5, vertical: CBSpace.x6),
        physics: const BouncingScrollPhysics(),
        children: [
              CBSectionHeader(
                  title: 'CONNECTION STATUS',
                  color: connectionColor,
                  icon: Icons.sensors_rounded,
              ),
              const SizedBox(height: CBSpace.x4),
              CBGlassTile(
                borderColor: connectionColor.withValues(alpha: 0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.wifi_rounded,
                            color: connectionColor, size: 24),
                        const SizedBox(width: CBSpace.x3),
                        Expanded(
                          child: Text(
                            'HUB SYNC PROTOCOL',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CBSpace.x2),
                    Text(
                      connectionStatus,
                      style: textTheme.labelLarge?.copyWith(
                        color: connectionColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        shadows: CBColors.textGlow(connectionColor, intensity: 0.4),
                      ),
                    ),
                    const SizedBox(height: CBSpace.x5),
                    _buildDetailRow(context, 'CURRENT PHASE', phaseLabel, scheme),
                    if (gameState.hostName != null)
                      _buildDetailRow(context, 'HOST IDENT', gameState.hostName!.toUpperCase(), scheme),
                    _buildDetailRow(context, 'CURRENT CYCLE', 'DAY ${gameState.dayCount}', scheme),
                    _buildDetailRow(context, 'ACTIVE NODES', '${gameState.players.length} OPERATIVES', scheme),
                  ],
                ),
              ),
              const SizedBox(height: CBSpace.x8),
              CBSectionHeader(
                title: 'MISSION SNAPSHOT',
                color: scheme.primary,
                icon: Icons.analytics_outlined,
              ),
              const SizedBox(height: CBSpace.x4),
              CBGlassTile(
                borderColor: scheme.primary.withValues(alpha: 0.4),
                isPrismatic: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.settings_input_component_rounded,
                            color: scheme.primary, size: 24),
                        const SizedBox(width: CBSpace.x3),
                        Expanded(
                          child: Text(
                            'DIRECTIVE MATRIX',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: CBSpace.x2),
                    Text(
                      gameState.currentStep?.title.toUpperCase() ?? 'WAITING FOR HUB...',
                      style: textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        shadows: CBColors.textGlow(scheme.primary, intensity: 0.4),
                      ),
                    ),
                    const SizedBox(height: CBSpace.x4),
                    Container(
                      padding: const EdgeInsets.all(CBSpace.x4),
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(CBRadius.sm),
                        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        gameState.currentStep?.instructionText.toUpperCase() ??
                            'ESTABLISHING NEURAL LINK. PLEASE STAND BY.',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 120), // Provide some bottom padding
            ],
          ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: CBSpace.x2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            value,
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w900,
              fontFamily: 'RobotoMono',
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

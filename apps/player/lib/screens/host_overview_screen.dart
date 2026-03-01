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
    final textTheme = Theme.of(context).textTheme;

    String connectionStatus;
    Color connectionColor;

    if (gameState.isConnected) {
      connectionStatus = 'CONNECTION ACTIVE';
      connectionColor = scheme.tertiary; // Success green
    } else {
      connectionStatus = 'CONNECTION LOST';
      connectionColor = scheme.error; // Error red
    }

    final phaseLabel = gameState.phase.toUpperCase();

    return CBPrismScaffold(
      title: 'HOST OVERVIEW',
      drawer: const CustomDrawer(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x6, CBSpace.x6, CBSpace.x12),
        physics: const BouncingScrollPhysics(),
        children: [
          CBFadeSlide(
            child: CBSectionHeader(
                title: 'UPLINK STATUS',
                icon: Icons.wifi_rounded,
                color: connectionColor),
          ),
          const SizedBox(height: CBSpace.x4),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: CBGlassTile(
              borderColor: connectionColor.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(CBSpace.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(CBSpace.x2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: connectionColor.withValues(alpha: 0.1),
                        ),
                        child: Icon(Icons.wifi_rounded,
                            color: connectionColor, size: 24),
                      ),
                      const SizedBox(width: CBSpace.x3),
                      Expanded(
                        child: Text('HOST BRIDGE',
                            style: textTheme.titleMedium!.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            )),
                      ),
                    ],
                  ),
                  const SizedBox(height: CBSpace.x3),
                  Text(
                    connectionStatus,
                    style: textTheme.labelLarge!.copyWith(
                      color: connectionColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x3),
                  _buildDetailRow(context, 'ACTIVE PHASE', phaseLabel, scheme.primary),
                  if (gameState.hostName != null)
                    _buildDetailRow(context, 'HOST ID', gameState.hostName!.toUpperCase(), scheme.secondary),
                  _buildDetailRow(context, 'CURRENT CYCLE', '${gameState.dayCount}', scheme.tertiary),
                  _buildDetailRow(context, 'ACTIVE OPERATIVES', '${gameState.players.length}', scheme.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: CBSpace.x8),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: CBSectionHeader(
                title: 'SESSION DIRECTIVE',
                icon: Icons.settings_input_component_rounded,
                color: scheme.primary),
          ),
          const SizedBox(height: CBSpace.x4),
          CBFadeSlide(
            delay: const Duration(milliseconds: 300),
            child: CBGlassTile(
              borderColor: scheme.primary.withValues(alpha: 0.4),
              padding: const EdgeInsets.all(CBSpace.x5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gameState.currentStep?.title?.toUpperCase() ?? 'NO ACTIVE DIRECTIVE',
                    style: textTheme.labelLarge!.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: gameState.currentStep?.title != null ? CBColors.textGlow(scheme.primary, intensity: 0.3) : null,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x3),
                  Text(
                    gameState.currentStep?.instructionText?.toUpperCase() ??
                        'AWAITING HOST INITIATION.',
                    style: textTheme.bodySmall!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                      height: 1.4,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, String label, String value, Color color) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CBSpace.x1),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label.toUpperCase(),
              style: textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.4),
                fontSize: 9,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toUpperCase(),
              style: textTheme.bodySmall!.copyWith(
                color: color.withValues(alpha: 0.8),
                fontFamily: 'RobotoMono',
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

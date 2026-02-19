import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final stats = PersistenceService.instance.computeStats();

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [SimulationModeBadgeAction()],
      ),
      drawer: const CustomDrawer(),
      body: CBNeonBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: CBSpace.x6,
              vertical: CBSpace.x10,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // ── LOGO / TITLE AREA ──
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  Text(
                    'HOST CONTROL',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium!.copyWith(
                      color: scheme.secondary,
                      shadows: CBColors.textGlow(scheme.secondary),
                      letterSpacing: 8.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: CBSpace.x4),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [scheme.primary, scheme.secondary],
                    ).createShader(bounds),
                    child: Text(
                      'CLUB\nBLACKOUT',
                      textAlign: TextAlign.center,
                      style: CBTypography.heroNumber.copyWith(
                        color: scheme.onSurface,
                        height: 0.85,
                        fontWeight: FontWeight.w900,
                        shadows:
                            CBColors.textGlow(scheme.primary, intensity: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: CBSpace.x12),

            // ── QUICK STATS ROW ──
            Row(
              children: [
                Expanded(
                  child: _buildQuickStatTile(
                    context,
                    'TOTAL GAMES',
                    '${stats.totalGames}',
                    Icons.videogame_asset_outlined,
                    scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickStatTile(
                    context,
                    'AVG PLAYERS',
                    stats.averagePlayerCount.toStringAsFixed(1),
                    Icons.people_outline_rounded,
                    scheme.secondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: CBSpace.x6),

            // ── MAIN ACTIONS PANEL ──
            CBPanel(
              borderColor: scheme.primary.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CBPrimaryButton(
                    label: "START NEW GAME",
                    icon: Icons.add_circle_outline,
                    onPressed: () {
                      HapticService.heavy();
                      ref.read(hostNavigationProvider.notifier).setDestination(HostDestination.lobby);
                    },
                  ),
                  const SizedBox(height: CBSpace.x4),
                  CBGhostButton(
                    label: 'RESTORE SESSION',
                    onPressed: () {
                      HapticService.light();
                      ref.read(hostNavigationProvider.notifier).setDestination(HostDestination.saveLoad);
                    },
                  ),
                  const SizedBox(height: CBSpace.x3),
                  CBGhostButton(
                    label: 'VIEW HALL OF FAME',
                    onPressed: () {
                      HapticService.light();
                      ref
                          .read(hostNavigationProvider.notifier)
                          .setDestination(HostDestination.hallOfFame);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: CBSpace.x10),

            // ── SYSTEM FOOTER ──
            Text(
              "V4.0.8 NEON | SECURE CONNECTION ACTIVE",
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall!.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 1.5,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
}

  Widget _buildQuickStatTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(CBRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: textTheme.headlineSmall!.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.0,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}

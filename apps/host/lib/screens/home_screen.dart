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

    return CBPrismScaffold(
      title: '',
      actions: const [SimulationModeBadgeAction()],
      drawer: const CustomDrawer(),
      body: Center(
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
                child: Text(
                  'HOST COMMAND CENTER',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall!.copyWith(
                    color: scheme.primary,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                    shadows: CBColors.textGlow(scheme.primary),
                  ),
                ),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
              ),

              const SizedBox(height: CBSpace.x12),

              // ── MAIN ACTIONS PANEL ──
              CBPanel(
                borderColor: scheme.primary.withValues(alpha: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CBPrimaryButton(
                      label: 'START NEW GAME',
                      icon: Icons.add_circle_outline,
                      onPressed: () {
                        HapticService.heavy();
                        ref
                            .read(hostNavigationProvider.notifier)
                            .setDestination(HostDestination.lobby);
                      },
                    ),
                    const SizedBox(height: CBSpace.x4),
                    CBGhostButton(
                      label: 'RESTORE SESSION',
                      onPressed: () {
                        HapticService.light();
                        ref
                            .read(hostNavigationProvider.notifier)
                            .setDestination(HostDestination.saveLoad);
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
                'V4.0.8 NEON | SECURE CONNECTION ACTIVE',
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
    );
  }
}

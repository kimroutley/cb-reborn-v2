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
    final textTheme = theme.textTheme;

    return CBPrismScaffold(
      title: 'COMMAND CENTER',
      actions: const [SimulationModeBadgeAction()],
      drawer: const CustomDrawer(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── LOGO / TITLE AREA ──
              CBFadeSlide(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: CBColors.circleGlow(scheme.primary, intensity: 0.3),
                      ),
                      child: Icon(
                        Icons.nightlife_rounded,
                        size: 64,
                        color: scheme.primary,
                        shadows: CBColors.iconGlow(scheme.primary),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'HOST TERMINAL',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium!.copyWith(
                        color: scheme.primary,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w900,
                        shadows: CBColors.textGlow(scheme.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CBBadge(
                      text: 'SESSION DIRECTOR ACTIVE',
                      color: scheme.tertiary,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // ── MAIN ACTIONS PANEL ──
              CBFadeSlide(
                delay: const Duration(milliseconds: 120),
                child: CBPanel(
                  borderColor: scheme.primary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CBPrimaryButton(
                        label: 'OPEN THE CLUB',
                        icon: Icons.login_rounded,
                        onPressed: () {
                          HapticService.heavy();
                          ref
                              .read(hostNavigationProvider.notifier)
                              .setDestination(HostDestination.lobby);
                        },
                      ),
                      const SizedBox(height: 16),
                      CBGhostButton(
                        label: 'RESTORE SESSION',
                        icon: Icons.settings_backup_restore_rounded,
                        onPressed: () {
                          HapticService.medium();
                          ref
                              .read(hostNavigationProvider.notifier)
                              .setDestination(HostDestination.saveLoad);
                        },
                      ),
                      const SizedBox(height: 16),
                      CBGhostButton(
                        label: 'HALL OF FAME',
                        icon: Icons.emoji_events_rounded,
                        onPressed: () {
                          HapticService.medium();
                          ref
                              .read(hostNavigationProvider.notifier)
                              .setDestination(HostDestination.hallOfFame);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // ── SYSTEM FOOTER ──
              CBFadeSlide(
                delay: const Duration(milliseconds: 240),
                child: Text(
                  'V4.0.8 NEON | SECURE UPLINK ACTIVE',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

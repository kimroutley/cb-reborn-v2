import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';

import '../host_destinations.dart';
import 'dashboard_view.dart';
import '../widgets/dj_booth/turntable_widget.dart';
import '../widgets/simulation_mode_badge_action.dart';
import '../widgets/custom_drawer.dart';

class DjBoothView extends ConsumerStatefulWidget {
  final GameState gameState;
  const DjBoothView({super.key, required this.gameState});

  @override
  ConsumerState<DjBoothView> createState() => _DjBoothViewState();
}

class _DjBoothViewState extends ConsumerState<DjBoothView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CBPrismScaffold(
      title: 'DJ BOOTH',
      drawer: const CustomDrawer(currentDestination: HostDestination.djBooth),
      actions: const [SimulationModeBadgeAction()],
      body: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.14,
                child: Image.asset(
                  'assets/backgrounds/dj_booth_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: CBInsets.panel,
                physics: const BouncingScrollPhysics(),
                child: CBPanel(
                  borderColor: scheme.secondary.withValues(alpha: 0.5),
                  padding: CBInsets.panel,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TurntableWidget(),
                      const SizedBox(height: CBSpace.x10),
                      Text(
                        'WELCOME TO THE DJ BOOTH',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              shadows: CBColors.textGlow(scheme.secondary, intensity: 0.4),
                            ),
                      ),
                      const SizedBox(height: CBSpace.x3),
                      Text(
                        'STATION UNDER CONSTRUCTION',
                        textAlign: TextAlign.center,
                        style: textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                      ),
                      const SizedBox(height: CBSpace.x12),
                      CBPrimaryButton(
                        fullWidth: false,
                        label: 'ACCESS LEGACY DASHBOARD',
                        icon: Icons.dashboard_rounded,
                        onPressed: () {
                          HapticService.medium();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CBPrismScaffold(
                                title: 'LEGACY DASHBOARD',
                                drawer: const CustomDrawer(),
                                actions: const [SimulationModeBadgeAction()],
                                body: DashboardView(
                                  gameState: widget.gameState,
                                  onAction: () {},
                                  onAddMock: () {},
                                  eyesOpen: false,
                                  onToggleEyes: (_) {},
                                  onBack: () => Navigator.of(context).maybePop(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}

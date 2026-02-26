import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';

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
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: const Text('DJ Booth'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [SimulationModeBadgeAction()],
      ),
      body: CBNeonBackground(
        child: Stack(
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
              child: Padding(
                padding: CBInsets.panel,
                child: CBPanel(
                  borderColor: scheme.secondary,
                  padding: CBInsets.panel,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const TurntableWidget(),
                      const SizedBox(height: CBSpace.x10),
                      Text(
                        'WELCOME TO THE DJ BOOTH',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                            ),
                      ),
                      const SizedBox(height: CBSpace.x2),
                      Text(
                        'Under Construction',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: CBSpace.x10),
                      CBPrimaryButton(
                        fullWidth: false,
                        label: 'ACCESS OLD DASHBOARD',
                        icon: Icons.dashboard_rounded,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                drawer: const CustomDrawer(),
                                appBar: AppBar(
                                  title: const Text('Old Dashboard'),
                                  backgroundColor: Colors.transparent,
                                  elevation: 0,
                                  actions: const [SimulationModeBadgeAction()],
                                ),
                                body: CBNeonBackground(
                                  child: DashboardView(
                                    gameState: widget.gameState,
                                    onAction: () {},
                                    onAddMock: () {},
                                    eyesOpen: false,
                                    onToggleEyes: (_) {},
                                    onBack: () =>
                                        Navigator.of(context).maybePop(),
                                  ),
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
      ),
    );
  }
}

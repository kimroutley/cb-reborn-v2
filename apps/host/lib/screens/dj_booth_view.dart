import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';

import '../widgets/dj_booth/turntable_widget.dart'; // Assuming this is already polished
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
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: 'DJ BOOTH',
      drawer: const CustomDrawer(),
      actions: const [SimulationModeBadgeAction()],
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: Image.asset(
                'assets/backgrounds/dj_booth_bg.png', // Ensure this asset path is correct
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter, // Focus on the booth elements
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(CBSpace.x6),
                physics: const BouncingScrollPhysics(),
                child: CBFadeSlide(
                  child: CBPanel(
                    borderColor: scheme.secondary.withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(CBSpace.x8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TurntableWidget(), // Assuming this widget is already themed correctly
                        const SizedBox(height: CBSpace.x12),
                        Text(
                          'DJ BOOTH // OFFLINE',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            color: scheme.secondary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            shadows: CBColors.textGlow(scheme.secondary),
                          ),
                        ),
                        const SizedBox(height: CBSpace.x4),
                        Text(
                          'SOUND SYSTEMS ARE UNDERGOING UPGRADES. ACCESS TEMPORARILY OFFLINE.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                            height: 1.5,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: CBSpace.x10),
                        CBGhostButton(
                          label: 'RETURN TO COMMAND',
                          icon: Icons.dashboard_rounded,
                          onPressed: () {
                            HapticService.medium();
                            // Assuming navigation will be handled by HostNavigationShell or similar
                            // For now, we'll just pop to previous screen if possible
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

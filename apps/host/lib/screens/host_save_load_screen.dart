import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../host_destinations.dart';
import '../host_navigation.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/simulation_mode_badge_action.dart';

class HostSaveLoadScreen extends ConsumerWidget {
  const HostSaveLoadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = PersistenceService.instance;
    final controller = ref.read(gameProvider.notifier);
    final nav = ref.read(hostNavigationProvider.notifier);
    final hasActiveGame = service.hasActiveGame;
    final savedAt = service.activeGameSavedAt;
    final savedAtLabel = savedAt == null
        ? 'N/A'
        : DateFormat('yyyy-MM-dd HH:mm').format(savedAt.toLocal());
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'SAVE / LOAD',
      drawer: const CustomDrawer(currentDestination: HostDestination.saveLoad),
      actions: const [SimulationModeBadgeAction()],
      body: ListView(
        padding: CBInsets.screen,
        children: [
          CBFadeSlide(
            child: CBPanel(
              borderColor: hasActiveGame
                  ? scheme.tertiary.withValues(alpha: 0.5)
                  : scheme.outline.withValues(alpha: 0.4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CBSectionHeader(
                    title: 'ACTIVE SLOT STATUS',
                    icon: Icons.save_rounded,
                    color: hasActiveGame ? scheme.tertiary : scheme.onSurface,
                  ),
                  const SizedBox(height: CBSpace.x3),
                  Text(
                    hasActiveGame ? 'SNAPSHOT AVAILABLE' : 'NO ACTIVE SNAPSHOT',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: hasActiveGame
                              ? scheme.tertiary
                              : scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: CBSpace.x2),
                  Text(
                    'LAST SAVED: $savedAtLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.75),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: CBSpace.x6),
          CBFadeSlide(
            delay: const Duration(milliseconds: 80),
            child: CBPrimaryButton(
              label: 'SAVE CURRENT SESSION',
              onPressed: () {
                final ok = controller.manualSave();
                showThemedSnackBar(
                  context,
                  ok ? 'Session saved.' : 'Failed to save session.',
                  accentColor: ok ? scheme.tertiary : scheme.error,
                );
              },
            ),
          ),
          const SizedBox(height: CBSpace.x3),
          CBFadeSlide(
            delay: const Duration(milliseconds: 160),
            child: CBPrimaryButton(
              label: 'LOAD SAVED SESSION',
              onPressed: () {
                final ok = controller.manualLoad();
                if (!ok) {
                  showThemedSnackBar(
                    context,
                    'No valid saved session found.',
                    accentColor: scheme.error,
                  );
                  return;
                }

                final phase = ref.read(gameProvider).phase;
                nav.setDestination(
                  phase == GamePhase.lobby
                      ? HostDestination.lobby
                      : HostDestination.game,
                );
                showThemedSnackBar(
                  context,
                  'Saved session loaded.',
                  accentColor: scheme.tertiary,
                );
              },
            ),
          ),
          const SizedBox(height: CBSpace.x3),
          CBFadeSlide(
            delay: const Duration(milliseconds: 240),
            child: CBGhostButton(
              label: 'CLEAR SAVED SNAPSHOT',
              color: scheme.error,
              onPressed: () {
                service.clearActiveGame();
                showThemedSnackBar(
                  context,
                  'Saved snapshot cleared.',
                  accentColor: scheme.error,
                );
              },
            ),
          ),
          const SizedBox(height: CBSpace.x3),
          CBFadeSlide(
            delay: const Duration(milliseconds: 320),
            child: CBGhostButton(
              label: 'LOAD TEST SANDBOX',
              color: scheme.secondary,
              onPressed: () {
                final ok = controller.loadTestGameSandbox();
                if (!ok) {
                  showThemedSnackBar(
                    context,
                    'Failed to load test sandbox.',
                    accentColor: scheme.error,
                  );
                  return;
                }
                nav.setDestination(HostDestination.game);
                showThemedSnackBar(
                  context,
                  'Test sandbox loaded.',
                  accentColor: scheme.secondary,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

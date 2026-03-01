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
        ? 'NO DATA'
        : DateFormat('MMM dd, yyyy – HH:mm').format(savedAt.toLocal()).toUpperCase();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: 'DATA PROTOCOL',
      drawer: const CustomDrawer(currentDestination: HostDestination.saveLoad),
      actions: const [SimulationModeBadgeAction()],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(CBSpace.x6, CBSpace.x6, CBSpace.x6, CBSpace.x12),
        physics: const BouncingScrollPhysics(),
        children: [
          CBFadeSlide(
            child: CBPanel(
              borderColor: hasActiveGame
                  ? scheme.tertiary.withValues(alpha: 0.5)
                  : scheme.outlineVariant.withValues(alpha: 0.3),
              padding: const EdgeInsets.all(CBSpace.x6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CBSectionHeader(
                    title: 'ACTIVE SNAPSHOT STATUS',
                    icon: Icons.save_rounded,
                    color: hasActiveGame ? scheme.tertiary : scheme.onSurface,
                  ),
                  const SizedBox(height: CBSpace.x4),
                  Text(
                    hasActiveGame ? 'SNAPSHOT AVAILABLE' : 'NO ACTIVE SNAPSHOT',
                    style: textTheme.labelLarge?.copyWith(
                          color: hasActiveGame
                              ? scheme.tertiary
                              : scheme.onSurface.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          shadows: hasActiveGame ? CBColors.textGlow(scheme.tertiary, intensity: 0.3) : null,
                        ),
                  ),
                  const SizedBox(height: CBSpace.x2),
                  Text(
                    'LAST SYNC: $savedAtLabel',
                    style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: CBSpace.x8),
          CBFadeSlide(
            delay: const Duration(milliseconds: 100),
            child: CBPrimaryButton(
              label: 'SAVE CURRENT STATE',
              icon: Icons.upload_file_rounded,
              onPressed: () {
                HapticService.medium();
                final ok = controller.manualSave();
                showThemedSnackBar(
                  context,
                  ok ? 'SESSION STATE ARCHIVED.' : 'ARCHIVE FAILED.',
                  accentColor: ok ? scheme.tertiary : scheme.error,
                );
              },
            ),
          ),
          const SizedBox(height: CBSpace.x3),
          CBFadeSlide(
            delay: const Duration(milliseconds: 200),
            child: CBPrimaryButton(
              label: 'LOAD ARCHIVED STATE',
              icon: Icons.download_rounded,
              onPressed: () {
                HapticService.medium();
                final ok = controller.manualLoad();
                if (!ok) {
                  showThemedSnackBar(
                    context,
                    'NO VALID ARCHIVED STATE FOUND.',
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
                  'ARCHIVED STATE RESTORED.',
                  accentColor: scheme.tertiary,
                );
              },
            ),
          ),
          const SizedBox(height: CBSpace.x6),
          CBFadeSlide(
            delay: const Duration(milliseconds: 300),
            child: CBGhostButton(
              label: 'CLEAR SAVED STATE',
              icon: Icons.delete_sweep_rounded,
              color: scheme.error,
              onPressed: () {
                HapticService.heavy();
                service.clearActiveGame();
                showThemedSnackBar(
                  context,
                  'ARCHIVED STATE PURGED.',
                  accentColor: scheme.error,
                );
              },
            ),
          ),
          const SizedBox(height: CBSpace.x3),
          CBFadeSlide(
            delay: const Duration(milliseconds: 400),
            child: CBGhostButton(
              label: 'LOAD TEST SANDBOX',
              icon: Icons.science_rounded,
              color: scheme.secondary,
              onPressed: () {
                HapticService.medium();
                final ok = controller.loadTestGameSandbox();
                if (!ok) {
                  showThemedSnackBar(
                    context,
                    'FAILED TO LOAD TEST SANDBOX.',
                    accentColor: scheme.error,
                  );
                  return;
                }
                nav.setDestination(HostDestination.game);
                showThemedSnackBar(
                  context,
                  'TEST SANDBOX DEPLOYED.',
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

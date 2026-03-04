import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../cloud_player_bridge.dart';
import '../player_bridge.dart';
import '../settings_provider.dart';
import '../widgets/custom_drawer.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBPrismScaffold(
      title: 'SETTINGS',
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: CBSpace.x5, vertical: CBSpace.x6),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            CBPanel(
              borderColor: scheme.primary.withValues(alpha: 0.35),
              padding: CBInsets.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CBSectionHeader(
                    title: 'AUDIO & FEEDBACK',
                    icon: Icons.graphic_eq_rounded,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: CBSpace.x6),
                  _buildSettingRow(
                    context,
                    title: 'SOUND EFFECTS',
                    subtitle: 'UI CLICKS AND INTERACTION SOUNDS',
                    value: settings.soundEffectsEnabled,
                    onChanged: (val) {
                      HapticService.selection();
                      notifier.toggleSoundEffects(val);
                    },
                    icon: Icons.volume_up_rounded,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: CBSpace.x4),
                  _buildSettingRow(
                    context,
                    title: 'MUSIC',
                    subtitle: 'BACKGROUND AMBIENCE AND TRACKS',
                    value: settings.musicEnabled,
                    onChanged: (val) {
                      HapticService.selection();
                      notifier.toggleMusic(val);
                    },
                    icon: Icons.music_note_rounded,
                    color: scheme.secondary,
                  ),
                  const SizedBox(height: CBSpace.x4),
                  _buildSettingRow(
                    context,
                    title: 'HAPTIC FEEDBACK',
                    subtitle: 'VIBRATION ON TOUCH INTERACTIONS',
                    value: settings.hapticsEnabled,
                    onChanged: (val) {
                      HapticService.selection();
                      notifier.toggleHaptics(val);
                    },
                    icon: Icons.vibration_rounded,
                    color: scheme.tertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: CBSpace.x6),
            CBPanel(
              borderColor: scheme.outlineVariant.withValues(alpha: 0.3),
              padding: CBInsets.panel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CBSectionHeader(
                    title: 'DISPLAY',
                    icon: Icons.monitor_rounded,
                    color: scheme.onSurface,
                  ),
                  const SizedBox(height: CBSpace.x6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(CBSpace.x2),
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(CBRadius.xs),
                          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
                        ),
                        child: Icon(Icons.contrast_rounded,
                            color: scheme.onSurface.withValues(alpha: 0.7),
                            size: 20),
                      ),
                      const SizedBox(width: CBSpace.x4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HIGH CONTRAST MODE',
                              style: textTheme.labelLarge?.copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                            ),
                            Text(
                              'ENHANCED ACCESSIBILITY (COMING SOON)',
                              style: textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface.withValues(alpha: 0.4),
                                    fontStyle: FontStyle.italic,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: CBSwitch(
                          value: false,
                          onChanged: null,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: CBSpace.x8),
            SizedBox(
              width: double.infinity,
              child: CBGhostButton(
                label: 'ABORT SESSION (SIGN OUT)',
                icon: Icons.logout_rounded,
                color: scheme.error,
                onPressed: () async {
                  HapticService.medium();
                  final confirmed = await showCBDiscardChangesDialog(
                    context,
                    title: 'SIGN OUT',
                    message: 'ARE YOU SURE YOU WANT TO TERMINATE YOUR SESSION?',
                    confirmLabel: 'TERMINATE',
                  );

                  if (!confirmed || !context.mounted) return;

                  // Disconnect bridges
                  await ref.read(playerBridgeProvider.notifier).disconnect();
                  await ref
                      .read(cloudPlayerBridgeProvider.notifier)
                      .disconnect();

                  // Sign out
                  await ref.read(authProvider.notifier).signOut();

                  if (!context.mounted) return;
                  showThemedSnackBar(
                    context,
                    'SESSION TERMINATED.',
                    accentColor: scheme.error,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(CBSpace.x2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(CBRadius.xs),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: CBSpace.x4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle.toUpperCase(),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.8,
          child: CBSwitch(
            value: value,
            onChanged: onChanged,
            color: color,
          ),
        ),
      ],
    );
  }
}

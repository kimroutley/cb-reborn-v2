import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_provider.dart';
import '../widgets/custom_drawer.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'SETTINGS',
      drawer: const CustomDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          children: [
            CBPanel(
              borderColor: scheme.primary.withValues(alpha: 0.35),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CBSectionHeader(
                    title: 'AUDIO & FEEDBACK',
                    icon: Icons.graphic_eq_rounded,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 24),
                  _buildSettingRow(
                    context,
                    title: 'SOUND EFFECTS',
                    subtitle: 'UI CLICKS AND INTERACTION SOUNDS',
                    value: settings.soundEffectsEnabled,
                    onChanged: notifier.toggleSoundEffects,
                    icon: Icons.volume_up_rounded,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    context,
                    title: 'MUSIC',
                    subtitle: 'BACKGROUND AMBIENCE AND TRACKS',
                    value: settings.musicEnabled,
                    onChanged: notifier.toggleMusic,
                    icon: Icons.music_note_rounded,
                    color: scheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  _buildSettingRow(
                    context,
                    title: 'HAPTIC FEEDBACK',
                    subtitle: 'VIBRATION ON TOUCH INTERACTIONS',
                    value: settings.hapticsEnabled,
                    onChanged: notifier.toggleHaptics,
                    icon: Icons.vibration_rounded,
                    color: scheme.tertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CBPanel(
              borderColor: scheme.outlineVariant.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CBSectionHeader(
                    title: 'DISPLAY',
                    icon: Icons.monitor_rounded,
                    color: scheme.onSurface,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Icon(
                        Icons.contrast_rounded,
                        color: scheme.onSurface.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HIGH CONTRAST MODE',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(
                                    color: scheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'COMING SOON',
                              style: Theme.of(context).textTheme.bodySmall!
                                  .copyWith(
                                    color: scheme.onSurface.withValues(
                                      alpha: 0.4,
                                    ),
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      CBSwitch(
                        value: false,
                        onChanged: (val) {}, // Placeholder
                        color: scheme.onSurface,
                      ),
                    ],
                  ),
                ],
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.labelLarge!.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
        CBSwitch(value: value, onChanged: onChanged, color: color),
      ],
    );
  }
}

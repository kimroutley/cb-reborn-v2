import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'SETTINGS',
          style: Theme.of(context).textTheme.titleLarge!,
        ),
        centerTitle: true,
      ),
      body: CBNeonBackground(
        child: SafeArea(
          child: ListView(
            padding: CBInsets.screen,
            children: [
              _buildSettingSwitch(
                context,
                'SOUND EFFECTS',
                settings.soundEffectsEnabled,
                notifier.toggleSoundEffects,
                scheme.primary, // Migrated from CBColors.electricCyan
              ),
              _buildSettingSwitch(
                context,
                'MUSIC',
                settings.musicEnabled,
                notifier.toggleMusic,
                scheme.secondary, // Migrated from CBColors.neonPurple
              ),
              _buildSettingSwitch(
                context,
                'HAPTIC FEEDBACK',
                settings.hapticsEnabled,
                notifier.toggleHaptics,
                scheme.tertiary, // Migrated from CBColors.matrixGreen
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(
    BuildContext context,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
    Color accentColor,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return CBPanel(
      borderColor: accentColor.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.headlineSmall!.copyWith(
              color: accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: CBSpace.x3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value ? 'ENABLED' : 'DISABLED',
                style: textTheme.bodySmall!.copyWith(
                  color: accentColor.withValues(alpha: 0.7),
                ),
              ),
              CBSwitch(
                value: value,
                onChanged: onChanged,
                color: accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

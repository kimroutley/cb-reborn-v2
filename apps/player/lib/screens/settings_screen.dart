import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/custom_drawer.dart';

// Provider for settings state
class SettingsState {
  final bool soundEffectsEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;

  const SettingsState({
    this.soundEffectsEnabled = true,
    this.musicEnabled = true,
    this.hapticsEnabled = true,
  });

  SettingsState copyWith({
    bool? soundEffectsEnabled,
    bool? musicEnabled,
    bool? hapticsEnabled,
  }) {
    return SettingsState(
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return const SettingsState();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      soundEffectsEnabled: prefs.getBool('soundEffectsEnabled') ?? true,
      musicEnabled: prefs.getBool('musicEnabled') ?? true,
      hapticsEnabled: prefs.getBool('hapticsEnabled') ?? true,
    );
    _applySettings();
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void toggleSoundEffects(bool enabled) {
    state = state.copyWith(soundEffectsEnabled: enabled);
    _saveSetting('soundEffectsEnabled', enabled);
    _applySettings();
  }

  void toggleMusic(bool enabled) {
    state = state.copyWith(musicEnabled: enabled);
    _saveSetting('musicEnabled', enabled);
    _applySettings();
  }

  void toggleHaptics(bool enabled) {
    state = state.copyWith(hapticsEnabled: enabled);
    _saveSetting('hapticsEnabled', enabled);
    _applySettings();
  }

  void _applySettings() {
    SoundService.setEnabled(state.soundEffectsEnabled);
    SoundService.setMusicEnabled(state.musicEnabled);
    HapticService.setEnabled(state.hapticsEnabled);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return CBPrismScaffold(
      title: 'SETTINGS',
      drawer:
          const CustomDrawer(), // Keep as const for now, revisit drawer integration later
      body: ListView(
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
    return CBGlassTile(
      title: title,
      accentColor: accentColor,
      content: Row(
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
    );
  }
}

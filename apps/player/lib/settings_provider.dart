import 'package:cb_theme/cb_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

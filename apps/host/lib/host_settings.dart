import 'dart:async';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class HostSettings {
  final double sfxVolume;
  final double musicVolume;
  final bool highContrast;
  final bool geminiNarrationEnabled;
  final String hostPersonalityId;
  final String geminiApiKey;

  const HostSettings({
    required this.sfxVolume,
    required this.musicVolume,
    required this.highContrast,
    required this.geminiNarrationEnabled,
    required this.hostPersonalityId,
    this.geminiApiKey = '',
  });

  HostSettings copyWith({
    double? sfxVolume,
    double? musicVolume,
    bool? highContrast,
    bool? geminiNarrationEnabled,
    String? hostPersonalityId,
    String? geminiApiKey,
  }) {
    return HostSettings(
      sfxVolume: sfxVolume ?? this.sfxVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      highContrast: highContrast ?? this.highContrast,
      geminiNarrationEnabled:
          geminiNarrationEnabled ?? this.geminiNarrationEnabled,
      hostPersonalityId: hostPersonalityId ?? this.hostPersonalityId,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
    );
  }

  static const defaults = HostSettings(
    sfxVolume: 1.0,
    musicVolume: 1.0,
    highContrast: false,
    geminiNarrationEnabled: true,
    hostPersonalityId: 'noir_narrator',
  );
}

class HostSettingsNotifier extends Notifier<HostSettings> {
  static const _keySfxVolume = 'sfxVolume';
  static const _keyMusicVolume = 'musicVolume';
  static const _keyHighContrast = 'highContrast';
  static const _keyGeminiNarrationEnabled = 'geminiNarrationEnabled';
  static const _keyHostPersonalityId = 'hostPersonalityId';
  static const _keyGeminiApiKey = 'geminiApiKey';

  @override
  HostSettings build() {
    _hydrate();
    return HostSettings.defaults;
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final sfxVolume = prefs.getDouble(_keySfxVolume);
      final musicVolume = prefs.getDouble(_keyMusicVolume);
      final highContrast = prefs.getBool(_keyHighContrast);
      final geminiNarrationEnabled = prefs.getBool(_keyGeminiNarrationEnabled);
      final hostPersonalityId = prefs.getString(_keyHostPersonalityId);
      final geminiApiKey = prefs.getString(_keyGeminiApiKey);

      state = state.copyWith(
        sfxVolume: (sfxVolume ?? state.sfxVolume).clamp(0.0, 1.0),
        musicVolume: (musicVolume ?? state.musicVolume).clamp(0.0, 1.0),
        highContrast: highContrast ?? state.highContrast,
        geminiNarrationEnabled:
            geminiNarrationEnabled ?? state.geminiNarrationEnabled,
        hostPersonalityId: hostPersonalityId ?? state.hostPersonalityId,
        geminiApiKey: geminiApiKey ?? state.geminiApiKey,
      );

      // Auto-seed from compile-time env if no persisted key exists
      if (state.geminiApiKey.isEmpty) {
        const envKey = String.fromEnvironment('GEMINI_API_KEY');
        if (envKey.isNotEmpty) {
          state = state.copyWith(geminiApiKey: envKey);
          unawaited(_persist(state));
        }
      }

      _syncApiKey(state.geminiApiKey);
      _applySideEffects(state);
    } catch (e) {
      // Best-effort
    }
  }

  Future<void> _persist(HostSettings next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keySfxVolume, next.sfxVolume);
      await prefs.setDouble(_keyMusicVolume, next.musicVolume);
      await prefs.setBool(_keyHighContrast, next.highContrast);
      await prefs.setBool(
          _keyGeminiNarrationEnabled, next.geminiNarrationEnabled);
      await prefs.setString(_keyHostPersonalityId, next.hostPersonalityId);
      await prefs.setString(_keyGeminiApiKey, next.geminiApiKey);
    } catch (e) {
      // Best-effort
    }
  }

  void _syncApiKey(String key) {
    ref.read(geminiNarrationServiceProvider).setApiKey(
          key.trim().isNotEmpty ? key.trim() : null,
        );
  }

  void toggleGeminiNarration() {
    final next = !state.geminiNarrationEnabled;
    state = state.copyWith(geminiNarrationEnabled: next);
    _persist(state);
  }

  void setSfxVolume(double value) {
    state = state.copyWith(sfxVolume: value.clamp(0.0, 1.0));
    _persist(state);
  }

  void setMusicVolume(double value) {
    state = state.copyWith(musicVolume: value.clamp(0.0, 1.0));
    _persist(state);
  }

  void setHighContrast(bool enabled) {
    final next = state.copyWith(highContrast: enabled);
    state = next;
    _applySideEffects(next);
    unawaited(_persist(next));
  }

  void setGeminiNarrationEnabled(bool enabled) {
    final next = state.copyWith(geminiNarrationEnabled: enabled);
    state = next;
    _applySideEffects(next);
    unawaited(_persist(next));
  }

  void setHostPersonalityId(String id) {
    final next = state.copyWith(hostPersonalityId: id);
    state = next;
    _applySideEffects(next);
    unawaited(_persist(next));

    // Sync to GameState so players see the personality color/mood
    ref.read(gameProvider.notifier).updateHostPersonality(id);
  }

  void setGeminiApiKey(String key) {
    final next = state.copyWith(geminiApiKey: key);
    state = next;
    _syncApiKey(key);
    unawaited(_persist(next));
  }

  void _applySideEffects(HostSettings settings) {
    SoundService.setVolume(settings.sfxVolume);
    SoundService.setMusicVolume(settings.musicVolume);
  }
}

final hostSettingsProvider =
    NotifierProvider<HostSettingsNotifier, HostSettings>(
  HostSettingsNotifier.new,
);

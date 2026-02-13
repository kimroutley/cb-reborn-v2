import 'dart:async';

import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

@immutable
class HostSettings {
  final double sfxVolume;
  final double musicVolume;
  final bool highContrast;
  final bool geminiNarrationEnabled;
  final String hostPersonalityId;

  const HostSettings({
    required this.sfxVolume,
    required this.musicVolume,
    required this.highContrast,
    required this.geminiNarrationEnabled,
    required this.hostPersonalityId,
  });

  HostSettings copyWith({
    double? sfxVolume,
    double? musicVolume,
    bool? highContrast,
    bool? geminiNarrationEnabled,
    String? hostPersonalityId,
  }) {
    return HostSettings(
      sfxVolume: sfxVolume ?? this.sfxVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      highContrast: highContrast ?? this.highContrast,
      geminiNarrationEnabled:
          geminiNarrationEnabled ?? this.geminiNarrationEnabled,
      hostPersonalityId: hostPersonalityId ?? this.hostPersonalityId,
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
  static const _boxKey = 'cb_host_settings_v1';
  static const _keySfxVolume = 'sfxVolume';
  static const _keyMusicVolume = 'musicVolume';
  static const _keyHighContrast = 'highContrast';
  static const _keyGeminiNarrationEnabled = 'geminiNarrationEnabled';
  static const _keyHostPersonalityId = 'hostPersonalityId';

  Box<dynamic>? _box;

  @override
  HostSettings build() {
    _hydrate();
    return HostSettings.defaults;
  }

  Future<Box<dynamic>> _ensureBox() async {
    final existing = _box;
    if (existing != null && existing.isOpen) {
      return existing;
    }
    final box = await Hive.openBox<dynamic>(_boxKey);
    _box = box;
    return box;
  }

  Future<void> _hydrate() async {
    try {
      final box = await _ensureBox();
      final sfxVolume = (box.get(_keySfxVolume) as num?)?.toDouble();
      final musicVolume = (box.get(_keyMusicVolume) as num?)?.toDouble();
      final highContrast = box.get(_keyHighContrast) as bool?;
      final geminiNarrationEnabled =
          box.get(_keyGeminiNarrationEnabled) as bool?;
      final hostPersonalityId = box.get(_keyHostPersonalityId) as String?;

      state = state.copyWith(
        sfxVolume: (sfxVolume ?? state.sfxVolume).clamp(0.0, 1.0),
        musicVolume: (musicVolume ?? state.musicVolume).clamp(0.0, 1.0),
        highContrast: highContrast ?? state.highContrast,
        geminiNarrationEnabled:
            geminiNarrationEnabled ?? state.geminiNarrationEnabled,
        hostPersonalityId: hostPersonalityId ?? state.hostPersonalityId,
      );

      _applySideEffects(state);
    } catch (e) {
      // Best-effort
    }
  }

  Future<void> _persist(HostSettings next) async {
    try {
      final box = await _ensureBox();
      await box.put(_keySfxVolume, next.sfxVolume);
      await box.put(_keyMusicVolume, next.musicVolume);
      await box.put(_keyHighContrast, next.highContrast);
      await box.put(_keyGeminiNarrationEnabled, next.geminiNarrationEnabled);
      await box.put(_keyHostPersonalityId, next.hostPersonalityId);
    } catch (e) {
      // Best-effort
    }
  }

  void setSfxVolume(double value) {
    final next = state.copyWith(sfxVolume: value.clamp(0.0, 1.0));
    state = next;
    _applySideEffects(next);
    unawaited(_persist(next));
  }

  void setMusicVolume(double value) {
    final next = state.copyWith(musicVolume: value.clamp(0.0, 1.0));
    state = next;
    _applySideEffects(next);
    unawaited(_persist(next));
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

import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:cb_models/cb_models.dart';

/// A simple audio playback service for in-game sound effects and music.
class SoundService {
  static final AudioPlayer _sfxPlayer = AudioPlayer();
  static final AudioPlayer _musicPlayer =
      AudioPlayer(); // Dedicated music player
  static bool _sfxEnabled = true;
  static double _sfxVolume = 1.0;
  static bool _musicEnabled = true; // Music enable flag
  static double _musicVolume = 1.0; // Music volume
  static bool _assetIndexLoaded = false;
  static final Set<String> _availableAssets = <String>{};
  static final Set<String> _missingAssetWarnings = <String>{};

  static const String _bgMusicAsset =
      'packages/cb_theme/assets/audio/bg_music.mp3';
  static const Map<String, String> _soundAssetMap = {
    SOUND_BASS_DROP: 'packages/cb_theme/assets/audio/bass_drop.mp3',
    SOUND_GLITCH_NOISE: 'packages/cb_theme/assets/audio/glitch_noise.mp3',
    SOUND_CLICK: 'packages/cb_theme/assets/audio/click.mp3',
  };

  static void setEnabled(bool enabled) {
    _sfxEnabled = enabled;
    if (!enabled) {
      _sfxPlayer.stop();
    }
  }

  static void setVolume(double volume) {
    _sfxVolume = volume.clamp(0.0, 1.0);
    _sfxPlayer.setVolume(_sfxVolume);
  }

  /// Enable or disable music playback.
  static void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      _musicPlayer.stop();
    } else {
      // Optionally restart music if it was stopped and should be playing
      // This requires knowledge of what music should be playing.
      // For now, just ensure it's not stopped if re-enabled.
    }
  }

  /// Set the music volume.
  static void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _musicPlayer.setVolume(_musicVolume);
  }

  /// Plays a sound effect based on its ID.
  static Future<void> playSfx(String soundId, {double? volume}) async {
    if (!_sfxEnabled) return;

    await _ensureAssetIndexLoaded();

    final effectiveVolume = volume ?? _sfxVolume;
    final assetPath = _soundAssetMap[soundId];
    if (assetPath == null) {
      debugPrint('Unknown soundId: $soundId');
      return;
    }

    if (!_availableAssets.contains(assetPath)) {
      _warnMissingAssetOnce(assetPath);
      return;
    }

    try {
      await _sfxPlayer.play(AssetSource(assetPath), volume: effectiveVolume);
    } catch (e) {
      debugPrint('Error playing sound $assetPath: $e');
    }
  }

  /// Plays background music. Currently hardcoded to one track.
  static Future<void> playMusic() async {
    if (!_musicEnabled) return;
    await _ensureAssetIndexLoaded();

    if (!_availableAssets.contains(_bgMusicAsset)) {
      _warnMissingAssetOnce(_bgMusicAsset);
      return;
    }

    try {
      // Consider adding a loop mode or a playlist for more robust music management
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(
        AssetSource(_bgMusicAsset),
        volume: _musicVolume,
      );
    } catch (e) {
      debugPrint('Error playing music: $e');
    }
  }

  static Future<void> _ensureAssetIndexLoaded() async {
    if (_assetIndexLoaded) {
      return;
    }

    try {
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final decoded = json.decode(manifestRaw);
      if (decoded is Map<String, dynamic>) {
        _availableAssets
          ..clear()
          ..addAll(decoded.keys);
      }
    } catch (_) {
      // Keep the set empty; playback calls will no-op with a single warning.
    } finally {
      _assetIndexLoaded = true;
    }
  }

  static void _warnMissingAssetOnce(String assetPath) {
    if (_missingAssetWarnings.add(assetPath)) {
      debugPrint('Missing audio asset: $assetPath');
    }
  }

  /// Stops background music.
  static Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  static Future<void> playHeavyBass() => playSfx(SOUND_BASS_DROP, volume: 1.0);
  static Future<void> playClick() => playSfx(SOUND_CLICK, volume: 0.7);

  /// Disposes the audio player when no longer needed.
  static void dispose() {
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}

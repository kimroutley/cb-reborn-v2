import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// A simple background music playback service.
class MusicService {
  static final AudioPlayer _player = AudioPlayer();
  static bool _musicEnabled = true;
  static double _volume = 0.3; // Default lower volume for background music
  static String? _currentTrack;

  static const String track1 =
      'packages/cb_theme/assets/audio/background_music_1.mp3';

  static void setEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (!enabled) {
      _player.stop();
    } else if (_currentTrack != null) {
      _play(_currentTrack!); // Resume if there was a track playing
    }
  }

  static void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _player.setVolume(_volume);
  }

  static Future<void> playTrack(String assetPath) async {
    if (!_musicEnabled) return;
    _currentTrack = assetPath;
    _play(assetPath);
  }

  static Future<void> _play(String assetPath) async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_volume);
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Error playing music $assetPath: $e');
    }
  }

  static void stop() {
    _player.stop();
    _currentTrack = null;
  }

  static void dispose() {
    _player.dispose();
    _currentTrack = null;
  }
}

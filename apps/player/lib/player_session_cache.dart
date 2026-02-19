import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CachedSyncMode {
  local,
  cloud,
}

@immutable
class PlayerSessionCacheEntry {
  const PlayerSessionCacheEntry({
    required this.joinCode,
    required this.mode,
    required this.savedAt,
    required this.state,
    this.hostAddress,
    this.playerName,
  });

  final String joinCode;
  final CachedSyncMode mode;
  final DateTime savedAt;
  final Map<String, dynamic> state;
  final String? hostAddress;
  final String? playerName;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'joinCode': joinCode,
      'mode': mode.name,
      'savedAt': savedAt.toIso8601String(),
      'state': state,
      'hostAddress': hostAddress,
      'playerName': playerName,
    };
  }

  static PlayerSessionCacheEntry? fromJson(Map<String, dynamic> json) {
    final joinCode = (json['joinCode'] as String?)?.trim();
    final modeName = (json['mode'] as String?)?.trim();
    final savedAtRaw = json['savedAt'] as String?;
    final state = json['state'];
    if (joinCode == null ||
        joinCode.isEmpty ||
        modeName == null ||
        savedAtRaw == null ||
        state is! Map<String, dynamic>) {
      return null;
    }

    final savedAt = DateTime.tryParse(savedAtRaw);
    if (savedAt == null) {
      return null;
    }

    final mode = CachedSyncMode.values.where((m) => m.name == modeName);
    if (mode.isEmpty) {
      return null;
    }

    return PlayerSessionCacheEntry(
      joinCode: joinCode,
      mode: mode.first,
      savedAt: savedAt,
      state: state,
      hostAddress: json['hostAddress'] as String?,
      playerName: json['playerName'] as String?,
    );
  }
}

class PlayerSessionCacheRepository {
  const PlayerSessionCacheRepository();

  static const String _entryKey = 'player_session_cache_v1';
  static const Duration _maxEntryAge = Duration(hours: 18);

  Future<SharedPreferences?> _getPrefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // Unit tests that do not initialize Flutter bindings can hit this path.
      return null;
    }
  }

  Future<PlayerSessionCacheEntry?> loadSession() async {
    final prefs = await _getPrefs();
    if (prefs == null) {
      return null;
    }
    final raw = prefs.getString(_entryKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await clear();
        return null;
      }

      final entry = PlayerSessionCacheEntry.fromJson(decoded);
      if (entry == null) {
        await clear();
        return null;
      }

      // Drop stale snapshots to avoid restoring very old sessions.
      if (DateTime.now().difference(entry.savedAt) > _maxEntryAge) {
        await clear();
        return null;
      }

      return entry;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> saveSession(PlayerSessionCacheEntry entry) async {
    final prefs = await _getPrefs();
    if (prefs == null) {
      return;
    }
    await prefs.setString(_entryKey, jsonEncode(entry.toJson()));
  }

  Future<void> clear() async {
    final prefs = await _getPrefs();
    if (prefs == null) {
      return;
    }
    await prefs.remove(_entryKey);
  }
}

final playerSessionCacheRepositoryProvider =
    Provider<PlayerSessionCacheRepository>(
  (ref) => const PlayerSessionCacheRepository(),
);

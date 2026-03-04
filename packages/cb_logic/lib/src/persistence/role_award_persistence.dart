import 'dart:convert';
import 'dart:isolate';
import 'role_award_calculator.dart';

import 'package:cb_models/cb_models.dart';
import 'package:hive_ce/hive.dart';

/// Handles persistence for Role Awards.
class RoleAwardPersistence {
  static const keyPrefix = 'role_award_progress::';

  final Box<String> _recordsBox;
  final List<GameRecord> Function() _gameRecordsLoader;

  RoleAwardPersistence({
    required Box<String> recordsBox,
    required List<GameRecord> Function() gameRecordsLoader,
  })  : _recordsBox = recordsBox,
        _gameRecordsLoader = gameRecordsLoader;

  // ────────────────── Role Award Progress ──────────────────

  /// Save progress for a specific role award.
  Future<void> saveRoleAwardProgress(PlayerRoleAwardProgress progress) async {
    final key = '$keyPrefix${progress.playerKey}::${progress.awardId}';
    final json = jsonEncode(progress.toJson());
    await _recordsBox.put(key, json);
  }

  /// Load all stored role award progress entries.
  List<PlayerRoleAwardProgress> loadRoleAwardProgresses() {
    final progresses = <PlayerRoleAwardProgress>[];
    for (final key in _recordsBox.keys) {
      if (key is String && key.startsWith(keyPrefix)) {
        final raw = _recordsBox.get(key);
        if (raw != null) {
          try {
            final json = jsonDecode(raw) as Map<String, dynamic>;
            progresses.add(PlayerRoleAwardProgress.fromJson(json));
          } catch (_) {
            // skip corrupted
          }
        }
      }
    }
    return progresses;
  }

  List<PlayerRoleAwardProgress> loadRoleAwardProgressesByPlayer(
    String playerKey,
  ) {
    return loadRoleAwardProgresses()
        .where((progress) => progress.playerKey == playerKey)
        .toList(growable: false);
  }

  List<PlayerRoleAwardProgress> loadRoleAwardProgressesByRole(String roleId) {
    return loadRoleAwardProgresses().where((progress) {
      final definition = roleAwardDefinitionById(progress.awardId);
      return definition?.roleId == roleId;
    }).toList(growable: false);
  }

  List<PlayerRoleAwardProgress> loadRoleAwardProgressesByTier(
    RoleAwardTier tier,
  ) {
    return loadRoleAwardProgresses().where((progress) {
      final definition = roleAwardDefinitionById(progress.awardId);
      return definition?.tier == tier;
    }).toList(growable: false);
  }

  List<PlayerRoleAwardProgress> loadRecentRoleAwardUnlocks({int limit = 20}) {
    final unlocked = loadRoleAwardProgresses()
        .where((progress) => progress.isUnlocked && progress.unlockedAt != null)
        .toList(growable: false)
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
    return unlocked.take(limit).toList(growable: false);
  }

  Future<void> clearRoleAwardProgresses() async {
    final keysToDelete = _recordsBox.keys.whereType<String>().where((key) {
      return key.startsWith(keyPrefix);
    }).toList(growable: false);

    for (final key in keysToDelete) {
      await _recordsBox.delete(key);
    }
  }

  Future<List<PlayerRoleAwardProgress>> rebuildRoleAwardProgresses() async {
    await clearRoleAwardProgresses();
    final records = _gameRecordsLoader();
    if (records.isEmpty) {
      return const <PlayerRoleAwardProgress>[];
    }

    final rebuilt = await Isolate.run(() => calculateRoleAwardProgress(records));

    for (final progress in rebuilt) {
      await saveRoleAwardProgress(progress);
    }

    return rebuilt;
  }
}

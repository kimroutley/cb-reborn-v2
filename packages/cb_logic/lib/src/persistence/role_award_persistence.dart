import 'dart:convert';

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
    final definitions = allRoleAwardDefinitions();
    if (records.isEmpty || definitions.isEmpty) {
      return const <PlayerRoleAwardProgress>[];
    }

    final roleStatsByPlayer = _buildRoleStatsByPlayer(records);
    final rebuilt = <PlayerRoleAwardProgress>[];

    for (final entry in roleStatsByPlayer.entries) {
      final playerKey = entry.key;
      final roleStats = entry.value;

      for (final roleEntry in roleStats.entries) {
        final roleId = roleEntry.key;
        final stats = roleEntry.value;
        final awardDefinitions = roleAwardsForRoleId(roleId);

        for (final definition in awardDefinitions) {
          final metric = _metricValueForRule(stats, definition.unlockRule);
          final threshold = _minimumForRule(definition.unlockRule);
          final unlocked = metric >= threshold;
          final progress = PlayerRoleAwardProgress(
            playerKey: playerKey,
            awardId: definition.awardId,
            progressValue: metric,
            isUnlocked: unlocked,
            unlockedAt: unlocked ? stats.latestEndedAt : null,
            sourceGameId: unlocked ? stats.latestGameId : null,
          );
          rebuilt.add(progress);
          await saveRoleAwardProgress(progress);
        }
      }
    }

    return rebuilt;
  }

  int _minimumForRule(Map<String, dynamic> unlockRule) {
    final raw = unlockRule['minimum'] ?? unlockRule['min'] ?? 1;
    if (raw is num) {
      return raw.toInt().clamp(0, 1000000);
    }
    return 1;
  }

  int _metricValueForRule(
    _RoleUsageStats stats,
    Map<String, dynamic> unlockRule,
  ) {
    final metric = (unlockRule['metric'] as String? ?? 'gamesPlayed').trim();
    switch (metric) {
      case 'wins':
      case 'gamesWon':
        return stats.gamesWon;
      case 'survivals':
      case 'gamesSurvived':
        return stats.survivals;
      case 'gamesPlayed':
      default:
        return stats.gamesPlayed;
    }
  }

  Map<String, Map<String, _RoleUsageStats>> _buildRoleStatsByPlayer(
    List<GameRecord> records,
  ) {
    final roleStatsByPlayer = <String, Map<String, _RoleUsageStats>>{};

    for (final record in records) {
      for (final player in record.roster) {
        final playerKey = player.id.trim().isEmpty ? player.name : player.id;
        final perRole = roleStatsByPlayer.putIfAbsent(
          playerKey,
          () => <String, _RoleUsageStats>{},
        );

        final current = perRole[player.roleId] ?? const _RoleUsageStats();
        perRole[player.roleId] = current.copyWith(
          gamesPlayed: current.gamesPlayed + 1,
          gamesWon: record.winner == player.alliance
              ? current.gamesWon + 1
              : current.gamesWon,
          survivals: player.alive ? current.survivals + 1 : current.survivals,
          latestEndedAt: record.endedAt,
          latestGameId: record.id,
        );
      }
    }

    return roleStatsByPlayer;
  }
}

class _RoleUsageStats {
  const _RoleUsageStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.survivals = 0,
    this.latestEndedAt,
    this.latestGameId,
  });

  final int gamesPlayed;
  final int gamesWon;
  final int survivals;
  final DateTime? latestEndedAt;
  final String? latestGameId;

  _RoleUsageStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? survivals,
    DateTime? latestEndedAt,
    String? latestGameId,
  }) {
    return _RoleUsageStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      survivals: survivals ?? this.survivals,
      latestEndedAt: latestEndedAt ?? this.latestEndedAt,
      latestGameId: latestGameId ?? this.latestGameId,
    );
  }
}

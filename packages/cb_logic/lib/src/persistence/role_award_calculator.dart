import 'package:cb_models/cb_models.dart';

/// Calculation logic for role award progress.
/// Extracted to run in an isolate.
List<PlayerRoleAwardProgress> calculateRoleAwardProgress(
  List<GameRecord> records,
) {
  if (records.isEmpty) return const [];

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
      }
    }
  }

  return rebuilt;
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

int _minimumForRule(Map<String, dynamic> unlockRule) {
  final raw = unlockRule['minimum'] ?? unlockRule['min'] ?? 1;
  if (raw is num) {
    return raw.toInt().clamp(0, 1000000);
  }
  return 1;
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

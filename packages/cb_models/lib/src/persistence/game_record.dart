import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';

part 'game_record.freezed.dart';
part 'game_record.g.dart';

/// A snapshot of a completed game for the history database.
@freezed
abstract class GameRecord with _$GameRecord {
  const factory GameRecord({
    required String id,
    required DateTime startedAt,
    required DateTime endedAt,
    required Team winner,
    required int playerCount,
    @Default(1) int dayCount,

    /// Role IDs that were in play (e.g. ['dealer', 'bouncer', 'whore', ...])
    @Default([]) List<String> rolesInPlay,

    /// Snapshot of player names + role IDs at game end
    @Default([]) List<PlayerSnapshot> roster,

    /// Full game timeline
    @Default([]) List<String> history,
  }) = _GameRecord;

  factory GameRecord.fromJson(Map<String, dynamic> json) =>
      _$GameRecordFromJson(json);
}

/// Lightweight player info for the game record roster.
@freezed
abstract class PlayerSnapshot with _$PlayerSnapshot {
  const factory PlayerSnapshot({
    required String id,
    required String name,
    required String roleId,
    required Team alliance,
    @Default(true) bool alive,
  }) = _PlayerSnapshot;

  factory PlayerSnapshot.fromJson(Map<String, dynamic> json) =>
      _$PlayerSnapshotFromJson(json);
}

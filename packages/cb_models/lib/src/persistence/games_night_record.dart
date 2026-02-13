import 'package:freezed_annotation/freezed_annotation.dart';

part 'games_night_record.freezed.dart';
part 'games_night_record.g.dart';

/// Games Night tracking - groups multiple game sessions.
@freezed
abstract class GamesNightRecord with _$GamesNightRecord {
  const factory GamesNightRecord({
    required String id,
    required String sessionName,
    required DateTime startedAt,
    DateTime? endedAt,
    @Default([]) List<String> gameIds,
    @Default([]) List<String> playerNames,
    @Default({}) Map<String, int> playerGamesCount,
    @Default({}) Map<String, String> playerIdMapping,
    @Default(true) bool isActive,
  }) = _GamesNightRecord;

  factory GamesNightRecord.fromJson(Map<String, dynamic> json) =>
      _$GamesNightRecordFromJson(json);
}

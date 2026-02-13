import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_stats.freezed.dart';
part 'game_stats.g.dart';

/// Aggregate statistics computed from all stored GameRecords.
@freezed
abstract class GameStats with _$GameStats {
  const factory GameStats({
    @Default(0) int totalGames,
    @Default(0) int clubStaffWins,
    @Default(0) int partyAnimalsWins,
    @Default(0) int averagePlayerCount,
    @Default(0) int averageDayCount,

    /// role ID -> number of games it appeared in
    @Default({}) Map<String, int> roleFrequency,

    /// role ID -> number of games its team won when it was in play
    @Default({}) Map<String, int> roleWinCount,
  }) = _GameStats;

  factory GameStats.fromJson(Map<String, dynamic> json) =>
      _$GameStatsFromJson(json);
}

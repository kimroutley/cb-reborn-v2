import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_event.freezed.dart';
part 'game_event.g.dart';

@freezed
sealed class GameEvent with _$GameEvent {
  const factory GameEvent.dayStart({
    required int day,
  }) = GameEventDayStart;

  const factory GameEvent.vote({
    required String voterId,
    required String targetId,
    required int day,
  }) = GameEventVote;

  const factory GameEvent.death({
    required String playerId,
    required String reason,
    required int day,
  }) = GameEventDeath;

  const factory GameEvent.kill({
    required String killerId,
    required String victimId,
    required int day,
  }) = GameEventKill;

  const factory GameEvent.tieBreak({
    required int day,
    required String strategy,
    required List<String> tiedPlayerIds,
    required List<String> resultantExileIds,
  }) = GameEventTieBreak;

  factory GameEvent.fromJson(Map<String, dynamic> json) => _$GameEventFromJson(json);
}

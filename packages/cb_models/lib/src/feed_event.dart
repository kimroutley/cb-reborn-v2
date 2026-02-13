import 'package:freezed_annotation/freezed_annotation.dart';
import 'script/script_action_type.dart';

part 'feed_event.freezed.dart';
part 'feed_event.g.dart';

enum FeedEventType {
  narrative,
  directive,
  action,
  system,
  result,
  timer,
}

@freezed
abstract class FeedEvent with _$FeedEvent {
  const factory FeedEvent({
    required String id,
    required FeedEventType type,
    required String content,
    @Default('') String title,
    String? roleId,
    required DateTime timestamp,

    // Action-specific
    ScriptActionType? actionType,
    String? stepId,
    @Default([]) List<String> options,
    @Default(false) bool resolved,
    String? resolution,
    @Default([]) List<String> targetPlayerIds,
    int? timerSeconds,
  }) = _FeedEvent;

  factory FeedEvent.fromJson(Map<String, dynamic> json) =>
      _$FeedEventFromJson(json);
}

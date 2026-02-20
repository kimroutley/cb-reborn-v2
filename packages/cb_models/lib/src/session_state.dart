import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_state.freezed.dart';
part 'session_state.g.dart';

const int kJoinCodeSuffixLength = 6;
const String kJoinCodePrefix = 'NEON';

String generateJoinCode() {
  final rng = Random.secure();
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final suffix = List.generate(
    kJoinCodeSuffixLength,
    (_) => chars[rng.nextInt(chars.length)],
  ).join();
  return '$kJoinCodePrefix-$suffix';
}

String generateSessionId() {
  final rng = Random.secure();
  String segment(int length) {
    const chars = 'abcdef0123456789';
    return List.generate(
      length,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
  }

  return '${segment(8)}-${segment(4)}-${segment(4)}-${segment(4)}-${segment(12)}';
}

@freezed
abstract class SessionState with _$SessionState {
  const factory SessionState({
    @Default('') String sessionId,
    @Default('') String joinCode,
    @Default([]) List<String> claimedPlayerIds,
    @Default([]) List<String> roleConfirmedPlayerIds,
    @Default(false) bool forceStartOverride,
  }) = _SessionState;

  factory SessionState.fromJson(Map<String, dynamic> json) =>
      _$SessionStateFromJson(json);
}

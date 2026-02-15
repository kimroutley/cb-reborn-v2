import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_state.freezed.dart';
part 'session_state.g.dart';

const int kJoinCodeSuffixLength = 6;
const String kJoinCodePrefix = 'NEON';

String generateJoinCode() {
  final rng = Random.secure();
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final suffix = List.generate(kJoinCodeSuffixLength, (_) => chars[rng.nextInt(chars.length)]).join();
  return '$kJoinCodePrefix-$suffix';
}

@freezed
abstract class SessionState with _$SessionState {
  const factory SessionState({
    @Default('') String joinCode,
    @Default([]) List<String> claimedPlayerIds,
  }) = _SessionState;

  factory SessionState.fromJson(Map<String, dynamic> json) =>
      _$SessionStateFromJson(json);
}

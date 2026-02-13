import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_state.freezed.dart';
part 'session_state.g.dart';

String generateJoinCode() {
  final rng = Random.secure();
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  final suffix = List.generate(4, (_) => chars[rng.nextInt(chars.length)]).join();
  return 'NEON-$suffix';
}

@freezed
abstract class SessionState with _$SessionState {
  const factory SessionState({
    @Default('') String joinCode,
    @Default([]) List<String> claimedPlayerIds,
    @Default('Club Host') String hostName,
  }) = _SessionState;

  factory SessionState.fromJson(Map<String, dynamic> json) => _$SessionStateFromJson(json);
}

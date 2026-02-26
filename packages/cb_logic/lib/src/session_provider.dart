import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cb_models/cb_models.dart';

part 'session_provider.g.dart';

@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  SessionState build() {
    return SessionState(
      sessionId: generateSessionId(),
      joinCode: generateJoinCode(),
    );
  }

  bool claimPlayer(String playerId) {
    if (state.claimedPlayerIds.contains(playerId)) {
      return false;
    }

    state = state.copyWith(
      claimedPlayerIds: [...state.claimedPlayerIds, playerId],
    );
    return true;
  }

  void releasePlayer(String playerId) {
    state = state.copyWith(
      claimedPlayerIds: state.claimedPlayerIds
          .where((id) => id != playerId)
          .toList(),
      roleConfirmedPlayerIds: state.roleConfirmedPlayerIds
          .where((id) => id != playerId)
          .toList(),
    );
  }

  void confirmRole(String playerId) {
    if (state.roleConfirmedPlayerIds.contains(playerId)) {
      return;
    }
    state = state.copyWith(
      roleConfirmedPlayerIds: [...state.roleConfirmedPlayerIds, playerId],
    );
  }

  void clearRoleConfirmations() {
    state = state.copyWith(roleConfirmedPlayerIds: const []);
  }

  void setForceStartOverride(bool enabled) {
    state = state.copyWith(forceStartOverride: enabled);
  }
}

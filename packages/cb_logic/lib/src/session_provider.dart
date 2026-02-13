import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cb_models/cb_models.dart';

part 'session_provider.g.dart';

@Riverpod(keepAlive: true)
String hostName(Ref ref) => 'Club Host';

@Riverpod(keepAlive: true)
class Session extends _$Session {
  @override
  SessionState build() {
    final name = ref.watch(hostNameProvider);
    return SessionState(
      joinCode: generateJoinCode(),
      hostName: name,
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
      claimedPlayerIds:
          state.claimedPlayerIds.where((id) => id != playerId).toList(),
    );
  }
}

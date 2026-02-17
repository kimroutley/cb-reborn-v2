import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_bridge_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeBridgeProvider = Provider<ActiveBridge>((ref) {
  final cloudState = ref.watch(cloudPlayerBridgeProvider);
  final localState = ref.watch(playerBridgeProvider);

  // Cloud takes precedence if both connected
  if (cloudState.isConnected || cloudState.joinAccepted) {
    return ActiveBridge(
      state: cloudState,
      actions: ref.read(cloudPlayerBridgeProvider.notifier),
      isCloud: true,
    );
  }

  return ActiveBridge(
    state: localState,
    actions: ref.read(playerBridgeProvider.notifier),
    isCloud: false,
  );
});

class ActiveBridge {
  final PlayerGameState state;
  final PlayerBridgeActions actions;
  final bool isCloud;

  ActiveBridge({
    required this.state,
    required this.actions,
    required this.isCloud,
  });
}
import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_bridge_actions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeBridgeProvider = Provider<ActiveBridge>((ref) {
  final cloudState = ref.watch(cloudPlayerBridgeProvider);
  return ActiveBridge(
    state: cloudState,
    actions: ref.read(cloudPlayerBridgeProvider.notifier),
    isCloud: true,
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
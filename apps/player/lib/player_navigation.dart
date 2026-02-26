import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'player_destinations.dart';

class PlayerNavigationNotifier extends Notifier<PlayerDestination> {
  @override
  PlayerDestination build() => PlayerDestination.connect;

  void setDestination(PlayerDestination destination) {
    state = destination;
  }
}

final playerNavigationProvider =
    NotifierProvider<PlayerNavigationNotifier, PlayerDestination>(() {
  return PlayerNavigationNotifier();
});

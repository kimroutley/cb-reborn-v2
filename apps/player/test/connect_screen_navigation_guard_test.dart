import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_destinations.dart';
import 'package:cb_player/player_navigation.dart';
import 'package:cb_player/screens/connect_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestNavigatorObserver extends NavigatorObserver {
  int didPushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    didPushCount++;
    super.didPush(route, previousRoute);
  }
}

class _TestPlayerBridge extends PlayerBridge {
  @override
  PlayerGameState build() => const PlayerGameState();

  void emitJoinAccepted() {
    state = state.copyWith(joinAccepted: true, joinError: null);
  }
}

class _TestCloudPlayerBridge extends CloudPlayerBridge {
  @override
  PlayerGameState build() => const PlayerGameState();

  void emitJoinAccepted() {
    state = state.copyWith(joinAccepted: true, joinError: null);
  }
}

class _TestNavigationNotifier extends PlayerNavigationNotifier {
  @override
  PlayerDestination build() => PlayerDestination.connect;
}

void main() {
  testWidgets(
    'ConnectScreen only pushes ClaimScreen once when both bridges accept rapidly',
    (tester) async {
      final observer = _TestNavigatorObserver();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerBridgeProvider.overrideWith(() => _TestPlayerBridge()),
            cloudPlayerBridgeProvider.overrideWith(
              () => _TestCloudPlayerBridge(),
            ),
            playerNavigationProvider
                .overrideWith(() => _TestNavigationNotifier()),
          ],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: const Scaffold(
              body: ConnectScreen(),
            ),
          ),
        ),
      );

      // Initial route push for MaterialApp home.
      expect(observer.didPushCount, 1);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ConnectScreen)),
      );
      final cloudBridge = container.read(cloudPlayerBridgeProvider.notifier)
          as _TestCloudPlayerBridge;
      final localBridge =
          container.read(playerBridgeProvider.notifier) as _TestPlayerBridge;

      // Simulate near-simultaneous accepted join responses from both bridges.
      cloudBridge.emitJoinAccepted();
      localBridge.emitJoinAccepted();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Routing is destination-based now; ensure a single app route push and
      // destination advanced to lobby.
      expect(observer.didPushCount, 1);
      expect(
        container.read(playerNavigationProvider),
        PlayerDestination.lobby,
      );
    },
  );
}

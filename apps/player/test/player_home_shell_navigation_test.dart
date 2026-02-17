import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_destinations.dart';
import 'package:cb_player/player_navigation.dart';
import 'package:cb_player/screens/player_home_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestCloudBridge extends CloudPlayerBridge {
  @override
  PlayerGameState build() =>
      const PlayerGameState(isConnected: true, phase: 'lobby');

  void emitPhase(String phase) {
    state = state.copyWith(phase: phase, isConnected: true);
  }

  @override
  Future<void> disconnect() async {}
}

class _TestLocalBridge extends PlayerBridge {
  @override
  PlayerGameState build() =>
      const PlayerGameState(isConnected: true, phase: 'lobby');

  @override
  Future<void> disconnect() async {}
}

class _LobbyFirstNavigationNotifier extends PlayerNavigationNotifier {
  @override
  PlayerDestination build() => PlayerDestination.lobby;
}

void main() {
  testWidgets('PlayerHomeShell auto-syncs navigation from active bridge phase',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudPlayerBridgeProvider.overrideWith(() => _TestCloudBridge()),
          playerBridgeProvider.overrideWith(() => _TestLocalBridge()),
          playerNavigationProvider
              .overrideWith(() => _LobbyFirstNavigationNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PlayerHomeShell()),
        ),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerHomeShell)),
    );

    expect(container.read(playerNavigationProvider), PlayerDestination.lobby);

    final cloud =
        container.read(cloudPlayerBridgeProvider.notifier) as _TestCloudBridge;

    cloud.emitPhase('setup');
    await tester.pump();
    expect(container.read(playerNavigationProvider), PlayerDestination.claim);

    cloud.emitPhase('active');
    await tester.pump();
    expect(container.read(playerNavigationProvider), PlayerDestination.game);

    cloud.emitPhase('recap');
    await tester.pump();
    expect(container.read(playerNavigationProvider), PlayerDestination.game);
  });

  testWidgets('Menu button remains accessible across shell destinations',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudPlayerBridgeProvider.overrideWith(() => _TestCloudBridge()),
          playerBridgeProvider.overrideWith(() => _TestLocalBridge()),
          playerNavigationProvider
              .overrideWith(() => _LobbyFirstNavigationNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PlayerHomeShell()),
        ),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerHomeShell)),
    );

    expect(
        find.byKey(const ValueKey('player_shell_menu_button')), findsOneWidget);

    container
        .read(playerNavigationProvider.notifier)
        .setDestination(PlayerDestination.claim);
    await tester.pump(const Duration(milliseconds: 600));

    expect(
        find.byKey(const ValueKey('player_shell_menu_button')), findsOneWidget);

    container
        .read(playerNavigationProvider.notifier)
        .setDestination(PlayerDestination.game);
    await tester.pump(const Duration(milliseconds: 600));

    expect(
        find.byKey(const ValueKey('player_shell_menu_button')), findsOneWidget);
  });
}

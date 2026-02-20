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
  PlayerGameState build() => const PlayerGameState(
      isConnected: false, joinAccepted: false, phase: 'lobby');

  void emitJoinAcceptedLobby() {
    state = state.copyWith(
      isConnected: true,
      joinAccepted: true,
      phase: 'lobby',
    );
  }

  void emitPhase(String phase) {
    state = state.copyWith(phase: phase, isConnected: true);
  }

  @override
  Future<void> disconnect() async {}
}

class _TestLocalBridge extends PlayerBridge {
  @override
  PlayerGameState build() =>
      const PlayerGameState(isConnected: false, phase: 'lobby');

  @override
  Future<void> disconnect() async {}
}

class _HomeFirstNavigationNotifier extends PlayerNavigationNotifier {
  @override
  PlayerDestination build() => PlayerDestination.home;
}

class _LobbyFirstNavigationNotifier extends PlayerNavigationNotifier {
  @override
  PlayerDestination build() => PlayerDestination.lobby;
}

void main() {
  testWidgets(
      'PlayerHomeShell preserves hall of fame destination while disconnected',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudPlayerBridgeProvider.overrideWith(() => _TestCloudBridge()),
          playerBridgeProvider.overrideWith(() => _TestLocalBridge()),
          playerNavigationProvider
              .overrideWith(() => _HomeFirstNavigationNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PlayerHomeShell()),
        ),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerHomeShell)),
    );

    container
        .read(playerNavigationProvider.notifier)
        .setDestination(PlayerDestination.hallOfFame);
    await tester.pump();

    expect(
      container.read(playerNavigationProvider),
      PlayerDestination.hallOfFame,
    );
  });

  testWidgets('PlayerHomeShell routes join acceptance to lobby from home',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudPlayerBridgeProvider.overrideWith(() => _TestCloudBridge()),
          playerBridgeProvider.overrideWith(() => _TestLocalBridge()),
          playerNavigationProvider
              .overrideWith(() => _HomeFirstNavigationNotifier()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PlayerHomeShell()),
        ),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerHomeShell)),
    );

    expect(container.read(playerNavigationProvider), PlayerDestination.home);

    final cloud =
        container.read(cloudPlayerBridgeProvider.notifier) as _TestCloudBridge;
    cloud.emitJoinAcceptedLobby();
    await tester.pump();

    expect(container.read(playerNavigationProvider), PlayerDestination.lobby);
  });

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
          home: Scaffold(
            body: PlayerHomeShell(
              startConfirmTimeout: Duration.zero,
              transitionDuration: Duration(milliseconds: 20),
            ),
          ),
        ),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerHomeShell)),
    );

    expect(container.read(playerNavigationProvider), PlayerDestination.lobby);

    final cloud =
        container.read(cloudPlayerBridgeProvider.notifier) as _TestCloudBridge;

    cloud.emitJoinAcceptedLobby();
    await tester.pump();

    cloud.emitPhase('setup');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));

    expect(container.read(playerNavigationProvider), PlayerDestination.game);

    cloud.emitPhase('night');
    await tester.pump();
    expect(container.read(playerNavigationProvider), PlayerDestination.game);

    cloud.emitPhase('day');
    await tester.pump();
    expect(container.read(playerNavigationProvider), PlayerDestination.game);

    cloud.emitPhase('resolution');
    await tester.pump();
    expect(container.read(playerNavigationProvider), PlayerDestination.game);

    cloud.emitPhase('endGame');
    await tester.pump();
    expect(container.read(playerNavigationProvider), PlayerDestination.game);
  });

  testWidgets('Shell does not render duplicate menu button overlay',
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
      find.byKey(const ValueKey('player_shell_menu_button')),
      findsNothing,
    );

    container
        .read(playerNavigationProvider.notifier)
        .setDestination(PlayerDestination.claim);
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(const ValueKey('player_shell_menu_button')),
      findsNothing,
    );

    container
        .read(playerNavigationProvider.notifier)
        .setDestination(PlayerDestination.game);
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(const ValueKey('player_shell_menu_button')),
      findsNothing,
    );

    container
        .read(playerNavigationProvider.notifier)
        .setDestination(PlayerDestination.about);
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      find.byKey(const ValueKey('player_shell_menu_button')),
      findsNothing,
    );
  });
}

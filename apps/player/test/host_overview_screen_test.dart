import 'package:cb_comms/cb_comms.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/screens/host_overview_screen.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock PlayerBridge to provide controlled state
class MockPlayerBridge extends PlayerBridge {
  @override
  PlayerGameState build() {
    return const PlayerGameState(
      phase: 'night',
      dayCount: 5,
      players: [
        PlayerSnapshot(
          id: 'p1',
          name: 'Player 1',
          roleId: 'r1',
          roleName: 'Role 1',
          alliance: 'unknown',
        ),
        PlayerSnapshot(
          id: 'p2',
          name: 'Player 2',
          roleId: 'r2',
          roleName: 'Role 2',
          alliance: 'unknown',
        ),
      ],
      isConnected: true,
    );
  }

  // Implement required overrides from PlayerBridge/PlayerBridgeActions as no-ops
  @override
  Future<void> connect(String url) async {}
  @override
  Future<void> disconnect() async {}
  @override
  void joinWithCode(String code) {}
  @override
  Future<void> joinGame(String joinCode, String playerName) async {}
  @override
  Future<void> claimPlayer(String playerId) async {}
  @override
  Future<void> vote({required String voterId, required String targetId}) async {}
  @override
  Future<void> sendAction({required String stepId, required String targetId, String? voterId}) async {}
  @override
  Future<void> placeDeadPoolBet({required String playerId, required String targetPlayerId}) async {}
  @override
  Future<void> sendGhostChat({required String playerId, required String message, String? playerName}) async {}
  @override
  Future<void> leave() async {}
  @override
  PlayerConnectionState get connectionState => PlayerConnectionState.connected;
}

void main() {
  testWidgets('HostOverviewScreen displays day count and player count', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerBridgeProvider.overrideWith(() => MockPlayerBridge()),
        ],
        child: MaterialApp(
          theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)), // Use the app theme
          home: const HostOverviewScreen(),
        ),
      ),
    );

    // Verify initial state (Phase is displayed)
    expect(find.text('Phase: NIGHT'), findsOneWidget);

    // These are the new elements we want to add
    // Now they should be there
    expect(find.text('Day: 5'), findsOneWidget);
    expect(find.text('Players: 2'), findsOneWidget);
  });
}

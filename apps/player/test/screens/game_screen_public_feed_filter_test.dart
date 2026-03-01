import 'package:cb_models/cb_models.dart';
import 'package:cb_player/active_bridge.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_bridge_actions.dart';
import 'package:cb_player/screens/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopPlayerActions implements PlayerBridgeActions {
  @override
  Future<void> claimPlayer(String playerId) async {}

  @override
  Future<void> confirmRole({required String playerId}) async {}

  @override
  Future<void> joinGame(String joinCode, String playerName) async {}

  @override
  Future<void> leave() async {}

  @override
  Future<void> placeDeadPoolBet({
    required String playerId,
    required String targetPlayerId,
  }) async {}

  @override
  Future<void> sendAction({
    required String stepId,
    required String targetId,
    String? voterId,
  }) async {}

  @override
  Future<void> sendBulletin({
    required String title,
    required String floatContent,
    String? roleId,
  }) async {}

  @override
  Future<void> sendGhostChat({
    required String playerId,
    required String message,
    String? playerName,
  }) async {}

  @override
  Future<void> vote({required String voterId, required String targetId}) async {}
}

void main() {
  testWidgets('GameScreen public feed hides host-only/internal bulletin entries',
      (tester) async {
    const me = PlayerSnapshot(
      id: 'p1',
      name: 'Alice',
      roleId: RoleIds.partyAnimal,
      roleName: 'Party Animal',
      roleColorHex: '#33B5E5',
      alliance: 'partyAnimals',
      isAlive: true,
    );

    final state = PlayerGameState(
      phase: 'day',
      dayCount: 2,
      players: const [me],
      myPlayerId: 'p1',
      myPlayerSnapshot: me,
      roleConfirmedPlayerIds: const ['p1'],
      bulletinBoard: [
        BulletinEntry(
          id: 'public-1',
          title: 'NIGHT RECAP',
          content: 'A public-safe recap line.',
          type: 'result',
          timestamp: DateTime(2026, 2, 28, 1, 0),
          isHostOnly: false,
        ),
        BulletinEntry(
          id: 'host-only-1',
          title: 'AI NARRATOR (SPICY)',
          content: 'Host spicy details',
          type: 'result',
          timestamp: DateTime(2026, 2, 28, 1, 1),
          isHostOnly: true,
        ),
        BulletinEntry(
          id: 'intel-1',
          title: 'PHASE CHANGE',
          content: 'Host intel only',
          type: 'hostIntel',
          timestamp: DateTime(2026, 2, 28, 1, 2),
          isHostOnly: false,
        ),
      ],
    );

    final active = ActiveBridge(
      state: state,
      actions: _NoopPlayerActions(),
      isCloud: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBridgeProvider.overrideWith((ref) => active),
        ],
        child: const MaterialApp(
          home: GameScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('A PUBLIC-SAFE RECAP LINE.'), findsOneWidget);
    expect(find.text('HOST SPICY DETAILS'), findsNothing);
    expect(find.text('HOST INTEL ONLY'), findsNothing);
  });
}

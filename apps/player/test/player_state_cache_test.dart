import 'package:cb_player/player_bridge.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PlayerGameState cache map roundtrips key gameplay fields', () {
    final source = PlayerGameState(
      phase: 'night',
      dayCount: 3,
      players: const [
        PlayerSnapshot(
          id: 'p1',
          name: 'Ava',
          roleId: 'wallflower',
          roleName: 'Wallflower',
          alliance: 'partyAnimals',
          isAlive: true,
        ),
      ],
      currentStep: const StepSnapshot(
        id: 'dealer_act_p2_3',
        title: 'Dealer',
        readAloudText: 'Dealer, choose.',
        actionType: 'singleSelect',
      ),
      bulletinBoard: [
        BulletinEntry(
          id: 'b1',
          title: 'Night falls',
          content: 'The club goes dark.',
          timestamp: DateTime.utc(2026, 2, 18, 12),
        ),
      ],
      voteTally: const {'p1': 2},
      votesByVoter: const {'p2': 'p1'},
      privateMessages: const {
        'p1': ['You are alive.'],
      },
      claimedPlayerIds: const ['p1'],
      roleConfirmedPlayerIds: const ['p1'],
      joinAccepted: true,
      myPlayerId: 'p1',
      hostName: 'Host',
    );

    final restored = PlayerGameState.fromCacheMap(source.toCacheMap());

    expect(restored.phase, 'night');
    expect(restored.dayCount, 3);
    expect(restored.players.single.id, 'p1');
    expect(restored.currentStep?.id, 'dealer_act_p2_3');
    expect(restored.bulletinBoard.single.id, 'b1');
    expect(restored.voteTally['p1'], 2);
    expect(restored.votesByVoter['p2'], 'p1');
    expect(restored.privateMessages['p1'], contains('You are alive.'));
    expect(restored.joinAccepted, isTrue);
    expect(restored.myPlayerId, 'p1');
    expect(restored.hostName, 'Host');
    expect(restored.isConnected, isFalse);
  });
}

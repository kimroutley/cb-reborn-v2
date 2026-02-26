import 'package:cb_comms/cb_comms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ═══════════════════════════════════════════════
  //  JSON Roundtrip (toJson → fromJson)
  // ═══════════════════════════════════════════════

  group('GameMessage JSON roundtrip', () {
    test('stateSync roundtrips with all fields', () {
      final original = GameMessage.stateSync(
        phase: 'night',
        dayCount: 2,
        players: [
          {'id': 'alice', 'name': 'Alice', 'isAlive': true},
        ],
        voteTally: {'alice': 3},
        votesByVoter: {'bob': 'alice'},
        gameHistory: ['── NIGHT 1 ──', 'Dealer killed Bob.'],
        endGameReport: ['PA wins!'],
        claimedPlayerIds: ['alice', 'bob'],
      );

      final json = original.toJson();
      final restored = GameMessage.fromJson(json);

      expect(restored.type, 'state_sync');
      expect(restored.payload['phase'], 'night');
      expect(restored.payload['dayCount'], 2);
      expect(restored.payload['players'], hasLength(1));
      expect(restored.payload['voteTally']['alice'], 3);
      expect(restored.payload['votesByVoter']['bob'], 'alice');
      expect(restored.payload['gameHistory'], hasLength(2));
      expect(restored.payload['endGameReport'], ['PA wins!']);
      expect(restored.payload['claimedPlayerIds'], ['alice', 'bob']);
    });

    test('stateSync omits null optional fields', () {
      final msg = GameMessage.stateSync(
        phase: 'lobby',
        dayCount: 0,
        players: const [],
      );

      final json = msg.toJson();
      final restored = GameMessage.fromJson(json);

      expect(restored.payload.containsKey('voteTally'), false);
      expect(restored.payload.containsKey('votesByVoter'), false);
      expect(restored.payload.containsKey('gameHistory'), false);
      expect(restored.payload.containsKey('endGameReport'), false);
      expect(restored.payload.containsKey('nightReport'), false);
      expect(restored.payload.containsKey('dayReport'), false);
      expect(restored.payload.containsKey('privateMessages'), false);
      // claimedPlayerIds always present (has a default)
      expect(restored.payload['claimedPlayerIds'], isEmpty);
    });

    test('stepUpdate roundtrips', () {
      final msg = GameMessage.stepUpdate(
        stepId: 'dealer_act_alice',
        title: 'Dealer Wakes Up',
        readAloudText: 'Choose your target...',
        phase: 'night',
      );

      final json = msg.toJson();
      final restored = GameMessage.fromJson(json);

      expect(restored.type, 'step_update');
      expect(restored.payload['stepId'], 'dealer_act_alice');
      expect(restored.payload['title'], 'Dealer Wakes Up');
      expect(restored.payload['readAloudText'], 'Choose your target...');
      expect(restored.payload['phase'], 'night');
    });

    test('playerKicked roundtrips', () {
      final msg = GameMessage.playerKicked(playerId: 'alice');
      final json = msg.toJson();
      final restored = GameMessage.fromJson(json);

      expect(restored.type, 'player_kicked');
      expect(restored.payload['playerId'], 'alice');
    });

    test('ping / pong roundtrip', () {
      final ping = GameMessage.ping();
      expect(GameMessage.fromJson(ping.toJson()).type, 'ping');

      final pong = GameMessage.pong();
      expect(GameMessage.fromJson(pong.toJson()).type, 'pong');
    });

    test('joinCodeResponse roundtrips', () {
      final accepted = GameMessage.joinCodeResponse(accepted: true);
      final rejected = GameMessage.joinCodeResponse(
        accepted: false,
        error: 'wrong code',
      );

      final restoredAccepted = GameMessage.fromJson(accepted.toJson());
      expect(restoredAccepted.payload['accepted'], true);
      expect(restoredAccepted.payload.containsKey('error'), false);

      final restoredRejected = GameMessage.fromJson(rejected.toJson());
      expect(restoredRejected.payload['accepted'], false);
      expect(restoredRejected.payload['error'], 'wrong code');
    });

    test('claimResponse roundtrips', () {
      final success = GameMessage.claimResponse(success: true, playerId: 'p1');
      final failure = GameMessage.claimResponse(success: false);

      final restoredSuccess = GameMessage.fromJson(success.toJson());
      expect(restoredSuccess.payload['success'], true);
      expect(restoredSuccess.payload['playerId'], 'p1');

      final restoredFailure = GameMessage.fromJson(failure.toJson());
      expect(restoredFailure.payload['success'], false);
      expect(restoredFailure.payload.containsKey('playerId'), false);
    });

    test('playerJoin roundtrips', () {
      final msg = GameMessage.playerJoin(joinCode: 'NEON-ABCD');
      final restored = GameMessage.fromJson(msg.toJson());
      expect(restored.type, 'player_join');
      expect(restored.payload['joinCode'], 'NEON-ABCD');
    });

    test('playerClaim roundtrips', () {
      final msg = GameMessage.playerClaim(playerId: 'alice');
      final restored = GameMessage.fromJson(msg.toJson());
      expect(restored.type, 'player_claim');
      expect(restored.payload['playerId'], 'alice');
    });

    test('playerVote roundtrips', () {
      final msg = GameMessage.playerVote(voterId: 'bob', targetId: 'alice');
      final restored = GameMessage.fromJson(msg.toJson());
      expect(restored.type, 'player_vote');
      expect(restored.payload['voterId'], 'bob');
      expect(restored.payload['targetId'], 'alice');
    });

    test('playerAction roundtrips with all fields', () {
      final msg = GameMessage.playerAction(
        stepId: 'day_vote',
        targetId: 'alice',
        voterId: 'bob',
      );
      final restored = GameMessage.fromJson(msg.toJson());
      expect(restored.type, 'player_action');
      expect(restored.payload['stepId'], 'day_vote');
      expect(restored.payload['targetId'], 'alice');
      expect(restored.payload['voterId'], 'bob');
    });

    test('playerAction omits null voterId', () {
      final msg = GameMessage.playerAction(
        stepId: 'night_action',
        targetId: 'target1',
      );
      final restored = GameMessage.fromJson(msg.toJson());
      expect(restored.payload.containsKey('voterId'), false);
    });

    test('playerLeave roundtrips', () {
      final msg = GameMessage.playerLeave(playerId: 'alice');
      final restored = GameMessage.fromJson(msg.toJson());
      expect(restored.type, 'player_leave');
      expect(restored.payload['playerId'], 'alice');
    });

    test('playerReconnect roundtrips', () {
      final msg = GameMessage.playerReconnect(claimedPlayerIds: ['p1', 'p2']);
      final restored = GameMessage.fromJson(msg.toJson());
      expect(restored.type, 'player_reconnect');
      expect(restored.payload['claimedPlayerIds'], ['p1', 'p2']);
    });
  });

  // ═══════════════════════════════════════════════
  //  Edge Cases
  // ═══════════════════════════════════════════════

  group('GameMessage edge cases', () {
    test('fromJson handles empty payload gracefully', () {
      final msg = GameMessage.fromJson('{"type":"custom"}');
      expect(msg.type, 'custom');
      expect(msg.payload, isEmpty);
    });

    test('fromJson handles unknown type', () {
      final msg = GameMessage.fromJson(
        '{"type":"unknown_type","payload":{"key":"val"}}',
      );
      expect(msg.type, 'unknown_type');
      expect(msg.payload['key'], 'val');
    });

    test('toString includes type and payload', () {
      final msg = GameMessage.ping();
      expect(msg.toString(), contains('ping'));
    });

    test('stateSync with privateMessages roundtrips', () {
      final msg = GameMessage.stateSync(
        phase: 'day',
        dayCount: 1,
        players: const [],
        privateMessages: {
          'alice': ['You saw Bob visiting Charlie.'],
          'bob': ['You were protected by the medic.'],
        },
      );
      final restored = GameMessage.fromJson(msg.toJson());
      final pm = restored.payload['privateMessages'] as Map<String, dynamic>;
      expect(pm['alice'], ['You saw Bob visiting Charlie.']);
      expect(pm['bob'], hasLength(1));
    });
  });
}

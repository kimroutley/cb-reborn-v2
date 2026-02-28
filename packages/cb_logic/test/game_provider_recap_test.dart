import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  late ProviderContainer container;
  late Game game;

  setUp(() {
    container = ProviderContainer();
    game = container.read(gameProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  test('resolving day emits one parseable redacted dayRecap bulletin', () {
    game.addPlayer('Alice');
    game.addPlayer('Bob');
    game.addPlayer('Charlie');
    game.addPlayer('Dana');

    final initial = container.read(gameProvider);
    final aliceId = initial.players.firstWhere((p) => p.name == 'Alice').id;
    final bobId = initial.players.firstWhere((p) => p.name == 'Bob').id;
    final charlieId =
        initial.players.firstWhere((p) => p.name == 'Charlie').id;
    final danaId = initial.players.firstWhere((p) => p.name == 'Dana').id;

    game.assignRole(aliceId, RoleIds.dealer);
    game.assignRole(bobId, RoleIds.medic);
    game.assignRole(charlieId, RoleIds.bouncer);
    game.assignRole(danaId, RoleIds.partyAnimal);

    final seeded = container.read(gameProvider);
    game.state = seeded.copyWith(
      phase: GamePhase.day,
      dayCount: 2,
      dayVoteTally: {
        bobId: 3,
        aliceId: 1,
      },
      dayVotesByVoter: {
        aliceId: bobId,
        bobId: aliceId,
        charlieId: bobId,
        danaId: bobId,
      },
      scriptQueue: const [],
      scriptIndex: 0,
      actionLog: const {},
      bulletinBoard: const [],
    );

    game.advancePhase();

    final after = container.read(gameProvider);
    final recaps =
        after.bulletinBoard.where((entry) => entry.type == 'dayRecap').toList();

    expect(recaps, hasLength(1));

    final payload = DayRecapCardPayload.tryParse(recaps.first.content);
    expect(payload, isNotNull);
    expect(payload!.day, 2);

    final playerText = payload.playerBullets.join(' ').toLowerCase();
    for (final name in ['alice', 'bob', 'charlie', 'dana']) {
      expect(playerText.contains(name), isFalse);
    }

    final roleNames = after.players
        .map((player) => player.role.name.toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();
    for (final roleName in roleNames) {
      expect(playerText.contains(roleName), isFalse);
    }
  });
}

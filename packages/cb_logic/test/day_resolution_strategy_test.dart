import 'package:cb_logic/src/day_actions/resolution/day_resolution.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

Role _role(
  String id, {
  Team alliance = Team.partyAnimals,
}) {
  return roleCatalogMap[id] ??
      Role(
        id: id,
        name: id,
        alliance: alliance,
        type: 'Test',
        description: 'Test role',
        nightPriority: 100,
        assetPath: '',
        colorHex: '#000000',
      );
}

Player _player(
  String id,
  String name,
  Role role, {
  bool isAlive = true,
  String? deathReason,
  int? deathDay,
  String? dramaTargetA,
  String? dramaTargetB,
}) {
  return Player(
    id: id,
    name: name,
    role: role,
    alliance: role.alliance,
    isAlive: isAlive,
    deathReason: deathReason,
    deathDay: deathDay,
    dramaQueenTargetAId: dramaTargetA,
    dramaQueenTargetBId: dramaTargetB,
  );
}

class _MutatingHandler implements DayResolutionHandler {
  @override
  DayResolutionResult handle(DayResolutionContext context) {
    final updatedPlayers = List<Player>.from(context.players);
    final first = updatedPlayers.first;
    updatedPlayers[0] =
        first.copyWith(role: _role(RoleIds.dealer, alliance: Team.clubStaff));

    return DayResolutionResult(
      players: updatedPlayers,
      lines: const ['mutated'],
      events: const [
        GameEvent.death(playerId: 'p2', reason: 'from_handler_1', day: 2),
      ],
      deathTriggerVictimIds: const ['p2'],
    );
  }
}

class _ReadingHandler implements DayResolutionHandler {
  @override
  DayResolutionResult handle(DayResolutionContext context) {
    return DayResolutionResult(
      players: context.players,
      lines: ['saw:${context.players.first.role.id}'],
      events: const [
        GameEvent.death(playerId: 'p3', reason: 'from_handler_2', day: 2),
      ],
      deathTriggerVictimIds: const ['p3'],
    );
  }
}

void main() {
  group('DayResolutionStrategy', () {
    test('aggregates outputs and propagates updated players through handlers',
        () {
      final initialPlayers = [
        _player('p1', 'One', _role(RoleIds.partyAnimal)),
        _player('p2', 'Two', _role(RoleIds.partyAnimal)),
        _player('p3', 'Three', _role(RoleIds.partyAnimal)),
      ];

      final strategy = DayResolutionStrategy(
        handlers: [_MutatingHandler(), _ReadingHandler()],
      );

      final result = strategy.execute(
        DayResolutionContext(
          players: initialPlayers,
          votesByVoter: const {'p2': 'p1'},
          dayCount: 2,
        ),
      );

      expect(result.players.first.role.id, RoleIds.dealer);
      expect(result.lines, ['mutated', 'saw:${RoleIds.dealer}']);
      expect(result.events.length, 2);
      expect((result.events[0] as GameEventDeath).reason, 'from_handler_1');
      expect((result.events[1] as GameEventDeath).reason, 'from_handler_2');
      expect(result.deathTriggerVictimIds, ['p2', 'p3']);
    });

    test('default handler order preserves expected chained outcome', () {
      final players = [
        _player(
          'tea',
          'Tea',
          _role(RoleIds.teaSpiller),
          isAlive: false,
          deathReason: 'exile',
          deathDay: 1,
        ),
        _player(
          'drama',
          'Drama',
          _role(RoleIds.dramaQueen),
          isAlive: false,
          deathReason: 'exile',
          deathDay: 1,
          dramaTargetA: 'dealer',
          dramaTargetB: 'buddy',
        ),
        _player(
          'pred',
          'Pred',
          _role(RoleIds.predator),
          isAlive: false,
          deathReason: 'exile',
          deathDay: 1,
        ),
        _player('dealer', 'Dealer',
            _role(RoleIds.dealer, alliance: Team.clubStaff)),
        _player('buddy', 'Buddy', _role(RoleIds.partyAnimal)),
        _player('observer', 'Observer', _role(RoleIds.sober)),
      ];

      final result = DayResolutionStrategy().execute(
        DayResolutionContext(
          players: players,
          votesByVoter: const {
            'dealer': 'tea',
            'buddy': 'pred',
            'observer': 'drama',
          },
          dayCount: 1,
        ),
      );

      expect(result.lines, isNotEmpty);
      expect(result.lines.first, contains('Tea Spiller exposed Dealer'));

      final dramaLineIndex = result.lines.indexWhere(
        (line) => line.contains('Drama Queen chaos'),
      );
      final predatorLineIndex = result.lines.indexWhere(
        (line) => line.contains('Predator struck back'),
      );
      expect(dramaLineIndex, greaterThanOrEqualTo(0));
      expect(predatorLineIndex, greaterThan(dramaLineIndex));

      final dealer = result.players.firstWhere((p) => p.id == 'dealer');
      final buddy = result.players.firstWhere((p) => p.id == 'buddy');

      expect(dealer.role.id, RoleIds.partyAnimal);
      expect(buddy.role.id, RoleIds.dealer);
      expect(buddy.isAlive, false);
      expect(buddy.deathReason, 'predator_retaliation');
      expect(result.deathTriggerVictimIds, ['buddy']);
      expect(result.events.length, 1);
      expect((result.events.single as GameEventDeath).reason,
          'predator_retaliation');
    });

    test('dead pool handler settles ghost bets and requests dead-pool clear', () {
      final players = [
        _player(
          'tea',
          'Tea',
          _role(RoleIds.teaSpiller),
          isAlive: false,
          deathReason: 'exile',
          deathDay: 1,
        ),
        _player('dealer', 'Dealer', _role(RoleIds.dealer))
            .copyWith(isAlive: false, currentBetTargetId: 'tea'),
      ];

      final result = DayResolutionStrategy().execute(
        DayResolutionContext(
          players: players,
          votesByVoter: const {'dealer': 'tea'},
          dayCount: 1,
          exiledPlayerId: 'tea',
        ),
      );

      final dealer = result.players.firstWhere((p) => p.id == 'dealer');
      expect(dealer.currentBetTargetId, isNull);
      expect(dealer.penalties.last, contains('[DEAD POOL] WON'));
      expect(result.clearDeadPoolBets, isTrue);
    });
  });
}

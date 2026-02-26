import 'package:cb_logic/src/day_actions/resolution/predator_retaliation.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

Role _role(String id, {Team alliance = Team.partyAnimals}) => Role(
  id: id,
  name: id,
  alliance: alliance,
  type: 'Test',
  description: 'Test role',
  nightPriority: 100,
  assetPath: '',
  colorHex: '#000000',
);

Player _player(
  String id,
  String name,
  Role role, {
  bool isAlive = true,
  String? deathReason,
  int? deathDay,
}) => Player(
  id: id,
  name: name,
  role: role,
  alliance: role.alliance,
  isAlive: isAlive,
  deathReason: deathReason,
  deathDay: deathDay,
);

void main() {
  group('resolvePredatorRetaliation', () {
    test('uses explicit retaliation choice when valid', () {
      final predatorRole = _role(RoleIds.predator);
      final dealerRole = _role(RoleIds.dealer, alliance: Team.clubStaff);
      final buddyRole = _role(RoleIds.partyAnimal);

      final players = [
        _player(
          'pred',
          'Predator',
          predatorRole,
          isAlive: false,
          deathReason: 'exile',
          deathDay: 1,
        ),
        _player('dealer', 'Dealer', dealerRole),
        _player('buddy', 'Buddy', buddyRole),
      ];

      final votesByVoter = {'dealer': 'pred', 'buddy': 'pred'};

      final result = resolvePredatorRetaliation(
        players: players,
        votesByVoter: votesByVoter,
        dayCount: 1,
        retaliationChoices: const {'pred': 'buddy'},
      );

      final dealer = result.players.firstWhere((p) => p.id == 'dealer');
      final buddy = result.players.firstWhere((p) => p.id == 'buddy');

      expect(dealer.isAlive, isTrue);
      expect(buddy.isAlive, isFalse);
      expect(buddy.deathReason, 'predator_retaliation');
      expect(result.victimIds.single, 'buddy');
    });

    test('exiled predator retaliates against first alive voter', () {
      final predatorRole = _role(RoleIds.predator);
      final dealerRole = _role(RoleIds.dealer, alliance: Team.clubStaff);
      final buddyRole = _role(RoleIds.partyAnimal);

      final players = [
        _player(
          'pred',
          'Predator',
          predatorRole,
          isAlive: false,
          deathReason: 'exile',
          deathDay: 1,
        ),
        _player('dealer', 'Dealer', dealerRole),
        _player('buddy', 'Buddy', buddyRole),
      ];

      final votesByVoter = {'dealer': 'pred', 'buddy': 'pred'};

      final result = resolvePredatorRetaliation(
        players: players,
        votesByVoter: votesByVoter,
        dayCount: 1,
      );

      final dealer = result.players.firstWhere((p) => p.id == 'dealer');
      expect(dealer.isAlive, isFalse);
      expect(dealer.deathReason, 'predator_retaliation');
      expect(dealer.deathDay, 1);
      expect(
        result.lines.single,
        'Predator struck back: Dealer was taken down in retaliation.',
      );
      expect(result.events.single, isA<GameEventDeath>());
      final event = result.events.single as GameEventDeath;
      expect(event.reason, 'predator_retaliation');
      expect(result.victimIds.single, 'dealer');
    });

    test('skips dead voters and targets next alive voter', () {
      final predatorRole = _role(RoleIds.predator);
      final dealerRole = _role(RoleIds.dealer, alliance: Team.clubStaff);
      final buddyRole = _role(RoleIds.partyAnimal);

      final players = [
        _player(
          'pred',
          'Predator',
          predatorRole,
          isAlive: false,
          deathReason: 'exile',
          deathDay: 1,
        ),
        _player(
          'dealer',
          'Dealer',
          dealerRole,
          isAlive: false,
          deathReason: 'exile',
          deathDay: 1,
        ),
        _player('buddy', 'Buddy', buddyRole),
      ];

      final votesByVoter = {'dealer': 'pred', 'buddy': 'pred'};

      final result = resolvePredatorRetaliation(
        players: players,
        votesByVoter: votesByVoter,
        dayCount: 1,
      );

      final buddy = result.players.firstWhere((p) => p.id == 'buddy');
      expect(buddy.isAlive, isFalse);
      expect(buddy.deathReason, 'predator_retaliation');
      expect(result.victimIds.single, 'buddy');
    });
  });
}

import 'package:cb_logic/src/day_actions/resolution/tea_spiller_reveal.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

Role _role(
  String id, {
  Team alliance = Team.partyAnimals,
}) =>
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

Player _player(
  String id,
  String name,
  Role role, {
  bool isAlive = true,
  String? deathReason,
}) =>
    Player(
      id: id,
      name: name,
      role: role,
      alliance: role.alliance,
      isAlive: isAlive,
      deathReason: deathReason,
    );

void main() {
  group('resolveTeaSpillerReveals', () {
    test('reveals first voter role for exiled Tea Spiller', () {
      final teaSpillerRole = _role(RoleIds.teaSpiller);
      final dealerRole = _role(RoleIds.dealer, alliance: Team.clubStaff);
      final buddyRole = _role(RoleIds.partyAnimal);

      final players = [
        _player('tea', 'Tea', teaSpillerRole,
            isAlive: false, deathReason: 'exile'),
        _player('dealer', 'Dealer', dealerRole),
        _player('buddy', 'Buddy', buddyRole),
      ];

      final lines = resolveTeaSpillerReveals(
        players: players,
        votesByVoter: {
          'dealer': 'tea',
          'buddy': 'tea',
        },
      );

      expect(lines.length, 1);
      expect(lines.single,
          'THE TEA HAS BEEN SPILLED! TEA DRAGS DEALER DOWN WITH THEM: THEY ARE THE DEALER!');
    });

    test('returns empty when no voters targeted Tea Spiller', () {
      final teaSpillerRole = _role(RoleIds.teaSpiller);
      final dealerRole = _role(RoleIds.dealer, alliance: Team.clubStaff);

      final players = [
        _player('tea', 'Tea', teaSpillerRole,
            isAlive: false, deathReason: 'exile'),
        _player('dealer', 'Dealer', dealerRole),
      ];

      final lines = resolveTeaSpillerReveals(
        players: players,
        votesByVoter: {'dealer': 'someone_else'},
      );

      expect(lines, isEmpty);
    });

    test('honors explicit selected reveal target when valid', () {
      final teaSpillerRole = _role(RoleIds.teaSpiller);
      final dealerRole = _role(RoleIds.dealer, alliance: Team.clubStaff);
      final buddyRole = _role(RoleIds.partyAnimal);

      final players = [
        _player('tea', 'Tea', teaSpillerRole,
            isAlive: false, deathReason: 'exile'),
        _player('dealer', 'Dealer', dealerRole),
        _player('buddy', 'Buddy', buddyRole),
      ];

      final lines = resolveTeaSpillerReveals(
        players: players,
        votesByVoter: {
          'dealer': 'tea',
          'buddy': 'tea',
        },
        teaSpillerRevealChoices: const {'tea': 'buddy'},
      );

      expect(lines.length, 1);
      expect(lines.single,
          'THE TEA HAS BEEN SPILLED! TEA DRAGS BUDDY DOWN WITH THEM: THEY ARE THE PARTY_ANIMAL!');
    });
  });
}

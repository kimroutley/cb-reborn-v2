import 'package:cb_logic/src/day_actions/resolution/drama_queen_swap.dart';
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
  String? targetA,
  String? targetB,
}) =>
    Player(
      id: id,
      name: name,
      role: role,
      alliance: role.alliance,
      isAlive: isAlive,
      deathReason: deathReason,
      dramaQueenTargetAId: targetA,
      dramaQueenTargetBId: targetB,
    );

void main() {
  group('resolveDramaQueenSwaps', () {
    test('uses configured setup targets first and swaps their roles', () {
      final dramaRole = _role(RoleIds.dramaQueen);
      final dealerRole = _role(RoleIds.dealer, alliance: Team.clubStaff);
      final buddyRole = _role(RoleIds.partyAnimal);
      final soberRole = _role(RoleIds.sober);

      final players = [
        _player('drama', 'Drama', dramaRole,
            isAlive: false,
            deathReason: 'exile',
            targetA: 'dealer',
            targetB: 'buddy'),
        _player('dealer', 'Dealer', dealerRole),
        _player('buddy', 'Buddy', buddyRole),
        _player('sober', 'Sober', soberRole),
      ];

      final result = resolveDramaQueenSwaps(
        players: players,
        votesByVoter: {
          'dealer': 'drama',
          'buddy': 'drama',
        },
      );

      final dealer = result.players.firstWhere((p) => p.id == 'dealer');
      final buddy = result.players.firstWhere((p) => p.id == 'buddy');

      expect(dealer.role.id, RoleIds.partyAnimal);
      expect(buddy.role.id, RoleIds.dealer);
      expect(result.lines, contains('Drama Queen chaos: Dealer and Buddy swapped roles.'));
      expect(
        result.lines,
        contains(
          'Drama Queen reveal: Dealer is now party_animal, Buddy is now dealer.',
        ),
      );
    });

    test('falls back to voters/alive targets when setup targets absent', () {
      final dramaRole = _role(RoleIds.dramaQueen);
      final dealerRole = _role(RoleIds.dealer, alliance: Team.clubStaff);
      final buddyRole = _role(RoleIds.partyAnimal);

      final players = [
        _player('drama', 'Drama', dramaRole,
            isAlive: false, deathReason: 'exile'),
        _player('dealer', 'Dealer', dealerRole),
        _player('buddy', 'Buddy', buddyRole),
      ];

      final result = resolveDramaQueenSwaps(
        players: players,
        votesByVoter: {
          'dealer': 'drama',
          'buddy': 'drama',
        },
      );

      final dealer = result.players.firstWhere((p) => p.id == 'dealer');
      final buddy = result.players.firstWhere((p) => p.id == 'buddy');

      expect(dealer.role.id, RoleIds.partyAnimal);
      expect(buddy.role.id, RoleIds.dealer);
      expect(result.lines, isNotEmpty);
    });
  });
}

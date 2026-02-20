import 'package:cb_models/cb_models.dart';
import 'package:cb_player/widgets/end_game_card.dart';
import 'package:flutter_test/flutter_test.dart';

PlayerSnapshot _player({
  required String roleId,
  required String alliance,
  bool isAlive = true,
}) {
  return PlayerSnapshot(
    id: 'p1',
    name: 'P1',
    roleId: roleId,
    roleName: roleId,
    alliance: alliance,
    isAlive: isAlive,
  );
}

void main() {
  group('isPlayerVictory', () {
    test('club staff wins when winner is clubStaff', () {
      final player = _player(roleId: RoleIds.dealer, alliance: 'clubStaff');
      expect(isPlayerVictory(winner: 'clubStaff', player: player), isTrue);
    });

    test('party animal wins when winner is partyAnimals', () {
      final player =
          _player(roleId: RoleIds.partyAnimal, alliance: 'partyAnimals');
      expect(isPlayerVictory(winner: 'partyAnimals', player: player), isTrue);
    });

    test('alive Club Manager co-wins with non-neutral winner', () {
      final manager = _player(
        roleId: RoleIds.clubManager,
        alliance: 'neutral',
        isAlive: true,
      );
      expect(isPlayerVictory(winner: 'clubStaff', player: manager), isTrue);
      expect(isPlayerVictory(winner: 'partyAnimals', player: manager), isTrue);
    });

    test('dead Club Manager does not co-win', () {
      final manager = _player(
        roleId: RoleIds.clubManager,
        alliance: 'neutral',
        isAlive: false,
      );
      expect(isPlayerVictory(winner: 'clubStaff', player: manager), isFalse);
    });

    test('Club Manager does not co-win neutral winner', () {
      final manager = _player(
        roleId: RoleIds.clubManager,
        alliance: 'neutral',
        isAlive: true,
      );
      expect(isPlayerVictory(winner: 'neutral', player: manager), isFalse);
    });
  });
}

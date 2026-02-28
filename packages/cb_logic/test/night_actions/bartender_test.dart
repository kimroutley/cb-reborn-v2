import 'package:cb_logic/src/game_resolution_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

// Helpers
Role _role(
  String id, {
  Team alliance = Team.partyAnimals,
  int priority = 100,
}) =>
    Role(
      id: id,
      name: id.toUpperCase(),
      alliance: alliance,
      type: 'Test',
      description: 'Test role',
      nightPriority: priority,
      assetPath: '',
      colorHex: '#FF0000',
    );

Player _player(String name, Role role, {Team? alliance}) => Player(
      id: name.toLowerCase(),
      name: name,
      role: role,
      alliance: alliance ?? role.alliance,
    );

NightResolution _resolveNight(List<Player> players, Map<String, String> log) =>
    GameResolutionLogic.resolveNightActions(
      GameState(
        players: players,
        actionLog: log,
        dayCount: 1,
      ),
    );

void main() {
  group('Bartender Action', () {
    test('Bartender: Same Side (Innocents)', () {
      final bartender = _player('Bartender', _role(RoleIds.bartender));
      final p1 = _player('Alice', _role(RoleIds.partyAnimal));
      final p2 = _player('Bob', _role(RoleIds.partyAnimal));
      final players = [bartender, p1, p2];

      final log = {
        'bartender_act_${bartender.id}_1': '${p1.id},${p2.id}',
      };

      final result = _resolveNight(players, log);

      final messages = result.privateMessages[bartender.id];
      expect(messages, isNotNull);
      expect(
        messages!.any((m) => m.contains('SAME side')),
        true,
      );
      expect(
        messages.any((m) => m.contains('Alice') && m.contains('Bob')),
        true,
      );
    });

    test('Bartender: Same Side (Dealers) - Club Staff Message', () {
      final bartender = _player('Bartender', _role(RoleIds.bartender));
      final d1 = _player('Dealer1', _role(RoleIds.dealer, alliance: Team.clubStaff));
      final d2 = _player('Dealer2', _role(RoleIds.dealer, alliance: Team.clubStaff));
      final players = [bartender, d1, d2];

      final log = {
        'bartender_act_${bartender.id}_1': '${d1.id},${d2.id}',
      };

      final result = _resolveNight(players, log);

      final messages = result.privateMessages[bartender.id];
      expect(messages, isNotNull);
      expect(
        messages!.any((m) => m.contains('CLUB STAFF')),
        true,
      );
      expect(
        messages.any((m) => m.contains('Dealer1') && m.contains('Dealer2')),
        true,
      );
    });

    test('Bartender: Different Sides', () {
      final bartender = _player('Bartender', _role(RoleIds.bartender));
      final dealer = _player('Dealer', _role(RoleIds.dealer, alliance: Team.clubStaff));
      final innocent = _player('Innocent', _role(RoleIds.partyAnimal));
      final players = [bartender, dealer, innocent];

      final log = {
        'bartender_act_${bartender.id}_1': '${dealer.id},${innocent.id}',
      };

      final result = _resolveNight(players, log);

      final messages = result.privateMessages[bartender.id];
      expect(messages, isNotNull);
      expect(
        messages!.any((m) => m.contains('DIFFERENT sides')),
        true,
      );
    });

    test('Bartender: Blocked by Sober', () {
      final bartender = _player('Bartender', _role(RoleIds.bartender));
      final sober = _player('Sober', _role(RoleIds.sober));
      final p1 = _player('Alice', _role(RoleIds.partyAnimal));
      final p2 = _player('Bob', _role(RoleIds.partyAnimal));
      
      final players = [bartender, sober, p1, p2];

      final log = {
        'bartender_act_${bartender.id}_1': '${p1.id},${p2.id}',
        'sober_act_${sober.id}_1': bartender.id,
      };

      final result = _resolveNight(players, log);

      final messages = result.privateMessages[bartender.id];
      // Since blocked by Sober, bartender should NOT get their investigation message.
      if (messages != null) {
        expect(
          messages.any((m) => m.contains('SAME side') || m.contains('DIFFERENT sides') || m.contains('CLUB STAFF')),
          false,
        );
      }
    });

    test('Bartender: Silenced by Roofi', () {
      final bartender = _player('Bartender', _role(RoleIds.bartender));
      final roofi = _player('Roofi', _role(RoleIds.roofi, alliance: Team.clubStaff));
      final p1 = _player('Alice', _role(RoleIds.partyAnimal));
      final p2 = _player('Bob', _role(RoleIds.partyAnimal));
      
      final players = [bartender, roofi, p1, p2];

      final log = {
        'bartender_act_${bartender.id}_1': '${p1.id},${p2.id}',
        'roofi_act_${roofi.id}_1': bartender.id,
      };

      final result = _resolveNight(players, log);

      final messages = result.privateMessages[bartender.id];
      // Since silenced by Roofi, bartender should NOT get their investigation message.
      if (messages != null) {
        expect(
          messages.any((m) => m.contains('SAME side') || m.contains('DIFFERENT sides') || m.contains('CLUB STAFF')),
          false,
        );
      }
    });
  });
}

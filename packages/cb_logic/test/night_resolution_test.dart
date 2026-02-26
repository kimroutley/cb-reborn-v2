import 'package:cb_logic/src/game_resolution_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

// Helpers
Role _role(
  String id, {
  Team alliance = Team.partyAnimals,
  int priority = 100,
}) => Role(
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

NightResolution _resolveNight(
  List<Player> players,
  Map<String, String> log, {
  String? gawkedPlayerId,
}) => GameResolutionLogic.resolveNightActions(
  GameState(
    players: players,
    actionLog: log,
    dayCount: 1,
    gawkedPlayerId: gawkedPlayerId,
  ),
);

void main() {
  group('NightResolutionLogic', () {
    test('Dealer kills target', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final victim = _player('Victim', _role(RoleIds.partyAnimal));
      final players = [dealer, victim];

      final log = {'dealer_act_${dealer.id}_1': victim.id};

      final result = _resolveNight(players, log);

      final updatedVictim = result.players.firstWhere((p) => p.id == victim.id);
      expect(updatedVictim.isAlive, false);
      expect(updatedVictim.deathReason, 'murder');
      expect(result.report.any((s) => s.contains('butchered')), true);
    });

    test('Drama Queen swaps stored targets when killed at night', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final sober = _player('Sober', _role(RoleIds.sober));
      final buddy = _player('Buddy', _role(RoleIds.partyAnimal));
      final drama = _player(
        'Drama',
        _role(RoleIds.dramaQueen),
      ).copyWith(dramaQueenTargetAId: sober.id, dramaQueenTargetBId: buddy.id);
      final players = [dealer, sober, buddy, drama];

      final log = {'dealer_act_${dealer.id}_1': drama.id};

      final result = _resolveNight(players, log);

      final updatedDrama = result.players.firstWhere((p) => p.id == drama.id);
      final updatedSober = result.players.firstWhere((p) => p.id == sober.id);
      final updatedBuddy = result.players.firstWhere((p) => p.id == buddy.id);

      expect(updatedDrama.isAlive, false);
      expect(updatedDrama.deathReason, 'murder');
      expect(updatedSober.role.id, RoleIds.partyAnimal);
      expect(updatedBuddy.role.id, RoleIds.sober);
      expect(
        result.report.any((line) => line.contains('Drama Queen chaos')),
        true,
      );
      expect(result.privateMessages[updatedSober.id], isNotNull);
      expect(result.privateMessages[updatedBuddy.id], isNotNull);
      expect(
        result.privateMessages[updatedSober.id]!.join(' '),
        contains('swapped with ${updatedBuddy.name}'),
      );
      expect(
        result.privateMessages[updatedBuddy.id]!.join(' '),
        contains('swapped with ${updatedSober.name}'),
      );
    });

    test('Gawked wallflower is exposed in report', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final wallflower = _player('Wallflower', _role(RoleIds.wallflower));
      final victim = _player('Victim', _role(RoleIds.partyAnimal));
      final players = [dealer, wallflower, victim];

      final log = {'dealer_act_${dealer.id}_1': victim.id};

      final result = _resolveNight(players, log, gawkedPlayerId: wallflower.id);

      expect(result.report.any((m) => m.contains('caught gawking')), true);
    });

    test('Medic protects target', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final medic = _player(
        'Medic',
        _role(RoleIds.medic),
      ).copyWith(medicChoice: 'PROTECT_DAILY');
      final victim = _player('Victim', _role(RoleIds.partyAnimal));
      final players = [dealer, medic, victim];

      final log = {
        'dealer_act_${dealer.id}_1': victim.id,
        'medic_act_${medic.id}_1': victim.id,
      };

      final result = _resolveNight(players, log);

      final updatedVictim = result.players.firstWhere((p) => p.id == victim.id);
      expect(updatedVictim.isAlive, true);
      expect(result.report.any((s) => s.contains('thwarted')), true);
    });

    test('Sober blocks action', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final sober = _player('Sober', _role(RoleIds.sober));
      final victim = _player('Victim', _role(RoleIds.partyAnimal));
      final players = [dealer, sober, victim];

      final log = {
        'dealer_act_${dealer.id}_1': victim.id,
        'sober_act_${sober.id}_1': dealer.id,
      };

      final result = _resolveNight(players, log);

      final updatedVictim = result.players.firstWhere((p) => p.id == victim.id);
      expect(updatedVictim.isAlive, true); // Dealer blocked
      expect(
        result.report.any((s) => s.contains('Sober blocked Dealer')),
        true,
      );
    });

    test('Roofi blocks single dealer', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final roofi = _player('Roofi', _role(RoleIds.roofi));
      final victim = _player('Victim', _role(RoleIds.partyAnimal));
      final players = [dealer, roofi, victim];

      final log = {
        'dealer_act_${dealer.id}_1': victim.id,
        'roofi_act_${roofi.id}_1': dealer.id,
      };

      final result = _resolveNight(players, log);

      final updatedVictim = result.players.firstWhere((p) => p.id == victim.id);
      expect(updatedVictim.isAlive, true);
      expect(result.report.any((s) => s.contains('silenced Dealer')), true);
      expect(
        result.report.any(
          (s) => s.contains('blocked Dealer\'s kill on Victim'),
        ),
        true,
      );

      final updatedDealer = result.players.firstWhere((p) => p.id == dealer.id);
      expect(updatedDealer.silencedDay, 1);
    });

    test('Roofi does NOT block if multiple dealers', () {
      final dealer1 = _player(
        'Dealer1',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final dealer2 = _player(
        'Dealer2',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final roofi = _player('Roofi', _role(RoleIds.roofi));
      final victim = _player('Victim', _role(RoleIds.partyAnimal));
      final players = [dealer1, dealer2, roofi, victim];

      final log = {
        'dealer_act_${dealer1.id}_1': victim.id,
        'roofi_act_${roofi.id}_1': dealer1.id,
      };

      final result = _resolveNight(players, log);

      final updatedVictim = result.players.firstWhere((p) => p.id == victim.id);
      expect(
        updatedVictim.isAlive,
        false,
      ); // Not blocked because another dealer exists

      final updatedDealer1 = result.players.firstWhere(
        (p) => p.id == dealer1.id,
      );
      expect(updatedDealer1.silencedDay, 1);
    });

    test('Bouncer checks ID', () {
      final bouncer = _player('Bouncer', _role(RoleIds.bouncer));
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final players = [bouncer, dealer];

      final log = {'bouncer_act_${bouncer.id}_1': dealer.id};

      final result = _resolveNight(players, log);

      expect(result.privateMessages[bouncer.id]!.first, contains('STAFF'));
      expect(
        result.report.any((s) => s.contains('Bouncer checked Dealer')),
        true,
      );
    });

    test('Bouncer checking Minor marks identity as checked', () {
      final bouncer = _player('Bouncer', _role(RoleIds.bouncer));
      final minor = _player('Minor', _role(RoleIds.minor));
      final players = [bouncer, minor];

      final log = {'bouncer_act_${bouncer.id}_1': minor.id};

      final result = _resolveNight(players, log);

      final updatedMinor = result.players.firstWhere((p) => p.id == minor.id);
      expect(updatedMinor.minorHasBeenIDd, true);
    });

    test('Ally Cat witnesses Bouncer check result', () {
      final bouncer = _player('Bouncer', _role(RoleIds.bouncer));
      final allyCat = _player(
        'AllyCat',
        _role(RoleIds.allyCat),
      ).copyWith(lives: 9);
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final players = [bouncer, allyCat, dealer];

      final log = {'bouncer_act_${bouncer.id}_1': dealer.id};

      final result = _resolveNight(players, log);

      expect(
        result.privateMessages[allyCat.id]!.any(
          (m) => m.contains('witnessed Bouncer check Dealer: STAFF'),
        ),
        true,
      );
    });

    test('Club Manager reveals role and marks target as sighted', () {
      final manager = _player('Manager', _role(RoleIds.clubManager));
      final target = _player('Target', _role(RoleIds.partyAnimal));
      final players = [manager, target];

      final log = {'club_manager_act_${manager.id}_1': target.id};

      final result = _resolveNight(players, log);

      final updatedTarget = result.players.firstWhere((p) => p.id == target.id);
      expect(updatedTarget.sightedByClubManager, true);
      expect(
        result.privateMessages[manager.id]!.first,
        contains(target.role.name),
      );
      expect(
        result.report.any((s) => s.contains('Manager file-checked Target')),
        true,
      );
    });

    test('Lightweight applies taboo name to all alive players', () {
      final lightweight = _player('Lightweight', _role(RoleIds.lightweight));
      final target = _player('Target', _role(RoleIds.partyAnimal));
      final bystander = _player('Bystander', _role(RoleIds.partyAnimal));
      final deadPlayer = _player(
        'Dead',
        _role(RoleIds.partyAnimal),
      ).copyWith(isAlive: false);
      final players = [lightweight, target, bystander, deadPlayer];

      final log = {'lightweight_act_${lightweight.id}_1': target.id};

      final result = _resolveNight(players, log);

      final updatedLightweight = result.players.firstWhere(
        (p) => p.id == lightweight.id,
      );
      final updatedTarget = result.players.firstWhere((p) => p.id == target.id);
      final updatedBystander = result.players.firstWhere(
        (p) => p.id == bystander.id,
      );
      final updatedDead = result.players.firstWhere(
        (p) => p.id == deadPlayer.id,
      );

      expect(updatedLightweight.tabooNames, contains(target.name));
      expect(updatedTarget.tabooNames, contains(target.name));
      expect(updatedBystander.tabooNames, contains(target.name));
      expect(updatedDead.tabooNames, isNot(contains(target.name)));

      expect(
        result.privateMessages[lightweight.id]!.first,
        contains('banned ${target.name}\'s name'),
      );
      expect(
        result.report.any(
          (s) => s.contains('LW banned ${target.name}\'s name'),
        ),
        true,
      );
      expect(result.teasers, contains('A name is now FORBIDDEN.'));
    });

    test('Second Wind survives once', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final sw = _player('SW', _role(RoleIds.secondWind));
      final players = [dealer, sw];

      final log = {'dealer_act_${dealer.id}_1': sw.id};

      final result = _resolveNight(players, log);

      final updatedSW = result.players.firstWhere((p) => p.id == sw.id);
      expect(updatedSW.isAlive, true);
      expect(updatedSW.secondWindPendingConversion, true);
      expect(
        result.report.any((s) => s.contains('Second Wind triggered')),
        true,
      );
    });

    test('Second Wind does not trigger on non-dealer kill', () {
      final messy = _player(
        'Messy',
        _role(RoleIds.messyBitch, alliance: Team.neutral),
      );
      final sw = _player('SW', _role(RoleIds.secondWind));
      final players = [messy, sw];

      final log = {'${RoleIds.messyBitch}_kill_${messy.id}_1': sw.id};

      final result = _resolveNight(players, log);

      final updatedSW = result.players.firstWhere((p) => p.id == sw.id);
      expect(updatedSW.isAlive, false);
      expect(updatedSW.secondWindPendingConversion, false);
      expect(
        result.report.any((s) => s.contains('Second Wind triggered')),
        false,
      );
    });

    test('Seasoned Drinker loses life', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final sd = _player(
        'SD',
        _role(RoleIds.seasonedDrinker),
      ).copyWith(lives: 2);
      final players = [dealer, sd];

      final log = {'dealer_act_${dealer.id}_1': sd.id};

      final result = _resolveNight(players, log);

      final updatedSD = result.players.firstWhere((p) => p.id == sd.id);
      expect(updatedSD.isAlive, true);
      expect(updatedSD.lives, 1);
      expect(result.report.any((s) => s.contains('lost a life')), true);
    });

    test('Seasoned Drinker dies if 1 life', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final sd = _player(
        'SD',
        _role(RoleIds.seasonedDrinker),
      ).copyWith(lives: 1);
      final players = [dealer, sd];

      final log = {'dealer_act_${dealer.id}_1': sd.id};

      final result = _resolveNight(players, log);

      final updatedSD = result.players.firstWhere((p) => p.id == sd.id);
      expect(updatedSD.isAlive, false);
    });

    test('Seasoned Drinker dies on non-dealer kill even with extra lives', () {
      final messy = _player(
        'Messy',
        _role(RoleIds.messyBitch, alliance: Team.neutral),
      );
      final sd = _player(
        'SD',
        _role(RoleIds.seasonedDrinker),
      ).copyWith(lives: 3);
      final players = [messy, sd];

      final log = {'${RoleIds.messyBitch}_kill_${messy.id}_1': sd.id};

      final result = _resolveNight(players, log);

      final updatedSD = result.players.firstWhere((p) => p.id == sd.id);
      expect(updatedSD.isAlive, false);
      expect(updatedSD.lives, 3);
      expect(
        result.report.any((s) => s.contains('Seasoned Drinker SD lost a life')),
        false,
      );
    });

    test('Ally Cat loses a life and survives murder when lives > 1', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final allyCat = _player(
        'AllyCat',
        _role(RoleIds.allyCat),
      ).copyWith(lives: 9);
      final players = [dealer, allyCat];

      final log = {'dealer_act_${dealer.id}_1': allyCat.id};

      final result = _resolveNight(players, log);

      final updatedAllyCat = result.players.firstWhere(
        (p) => p.id == allyCat.id,
      );
      expect(updatedAllyCat.isAlive, true);
      expect(updatedAllyCat.lives, 8);
      expect(
        result.report.any((s) => s.contains('Ally Cat AllyCat lost a life')),
        true,
      );
    });

    test('Ally Cat dies when murder occurs at 1 life', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final allyCat = _player(
        'AllyCat',
        _role(RoleIds.allyCat),
      ).copyWith(lives: 1);
      final players = [dealer, allyCat];

      final log = {'dealer_act_${dealer.id}_1': allyCat.id};

      final result = _resolveNight(players, log);

      final updatedAllyCat = result.players.firstWhere(
        (p) => p.id == allyCat.id,
      );
      expect(updatedAllyCat.isAlive, false);
      expect(updatedAllyCat.deathReason, 'murder');
    });

    test('Minor survives Dealer murder before being ID checked', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final minor = _player('Minor', _role(RoleIds.minor));
      final players = [dealer, minor];

      final log = {'dealer_act_${dealer.id}_1': minor.id};

      final result = _resolveNight(players, log);

      final updatedMinor = result.players.firstWhere((p) => p.id == minor.id);
      expect(updatedMinor.isAlive, true);
      expect(
        result.report.any((s) => s.contains('identity shield held')),
        true,
      );
    });

    test('Minor dies to Dealer murder after being ID checked', () {
      final dealer = _player(
        'Dealer',
        _role(RoleIds.dealer, alliance: Team.clubStaff),
      );
      final minor = _player(
        'Minor',
        _role(RoleIds.minor),
      ).copyWith(minorHasBeenIDd: true);
      final players = [dealer, minor];

      final log = {'dealer_act_${dealer.id}_1': minor.id};

      final result = _resolveNight(players, log);

      final updatedMinor = result.players.firstWhere((p) => p.id == minor.id);
      expect(updatedMinor.isAlive, false);
      expect(updatedMinor.deathReason, 'murder');
    });

    test(
      'Clinger is freed as Attack Dog when partner is murdered by Dealer',
      () {
        final dealer = _player(
          'Dealer',
          _role(RoleIds.dealer, alliance: Team.clubStaff),
        );
        final partner = _player('Partner', _role(RoleIds.partyAnimal));
        final clinger = _player(
          'Clinger',
          _role(RoleIds.clinger),
        ).copyWith(clingerPartnerId: partner.id);
        final players = [dealer, partner, clinger];

        final log = {'dealer_act_${dealer.id}_1': partner.id};

        final result = _resolveNight(players, log);

        final updatedPartner = result.players.firstWhere(
          (p) => p.id == partner.id,
        );
        final updatedClinger = result.players.firstWhere(
          (p) => p.id == clinger.id,
        );

        expect(updatedPartner.isAlive, false);
        expect(updatedClinger.isAlive, true);
        expect(updatedClinger.clingerFreedAsAttackDog, true);
        expect(
          result.report.any(
            (s) => s.contains('has snapped! They are now an Attack Dog'),
          ),
          true,
        );
      },
    );

    test(
      'Clinger dies of broken heart when partner dies from non-dealer kill',
      () {
        final messy = _player(
          'Messy',
          _role(RoleIds.messyBitch, alliance: Team.neutral),
        );
        final partner = _player('Partner', _role(RoleIds.partyAnimal));
        final clinger = _player(
          'Clinger',
          _role(RoleIds.clinger),
        ).copyWith(clingerPartnerId: partner.id);
        final players = [messy, partner, clinger];

        final log = {'${RoleIds.messyBitch}_kill_${messy.id}_1': partner.id};

        final result = _resolveNight(players, log);

        final updatedPartner = result.players.firstWhere(
          (p) => p.id == partner.id,
        );
        final updatedClinger = result.players.firstWhere(
          (p) => p.id == clinger.id,
        );

        expect(updatedPartner.isAlive, false);
        expect(updatedClinger.isAlive, false);
        expect(updatedClinger.clingerFreedAsAttackDog, false);
        expect(
          result.report.any((s) => s.contains('could not live without')),
          true,
        );
      },
    );

    test(
      'Creep inherits target role when target dies during night resolution',
      () {
        final dealer = _player(
          'Dealer',
          _role(RoleIds.dealer, alliance: Team.clubStaff),
        );
        final targetRole = _role(RoleIds.bouncer, alliance: Team.partyAnimals);
        final target = _player('Target', targetRole);
        final creep = _player(
          'Creep',
          _role(RoleIds.creep, alliance: Team.neutral),
        ).copyWith(creepTargetId: target.id);
        final players = [dealer, target, creep];

        final log = {'dealer_act_${dealer.id}_1': target.id};

        final result = _resolveNight(players, log);

        final updatedTarget = result.players.firstWhere(
          (p) => p.id == target.id,
        );
        final updatedCreep = result.players.firstWhere((p) => p.id == creep.id);

        expect(updatedTarget.isAlive, false);
        expect(updatedCreep.isAlive, true);
        expect(updatedCreep.role.id, targetRole.id);
        expect(updatedCreep.role.name, targetRole.name);
        expect(updatedCreep.alliance, targetRole.alliance);
        expect(updatedCreep.creepTargetId, isNull);
        expect(
          result.report.any(
            (s) => s.contains('The Creep Creep inherited the role of BOUNCER.'),
          ),
          true,
        );
      },
    );
  });
}

import 'package:cb_logic/src/scripting/script_builder.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Helpers
  Role makeRole(String id, {int nightPriority = 0}) {
    return Role(
      id: id,
      name: id.toUpperCase(),
      type: 'staff',
      description: 'Test role',
      nightPriority: nightPriority,
      assetPath: 'assets/roles/$id.png',
      colorHex: '#000000',
    );
  }

  Player makePlayer(
    String id,
    String roleId, {
    bool isAlive = true,
    bool isEnabled = true,
    bool joinsNextNight = false,
    bool clingerFreedAsAttackDog = false,
    bool clingerAttackDogUsed = false,
    bool messyBitchKillUsed = false,
    String? medicChoice,
    bool hasReviveToken = false,
    int nightPriority = 0,
  }) {
    return Player(
      id: id,
      name: 'Player $id',
      role: makeRole(roleId, nightPriority: nightPriority),
      alliance: Team.unknown,
      isAlive: isAlive,
      isEnabled: isEnabled,
      joinsNextNight: joinsNextNight,
      clingerFreedAsAttackDog: clingerFreedAsAttackDog,
      clingerAttackDogUsed: clingerAttackDogUsed,
      messyBitchKillUsed: messyBitchKillUsed,
      medicChoice: medicChoice,
      hasReviveToken: hasReviveToken,
    );
  }

  group('ScriptBuilder.buildNightScript', () {
    test('returns setup script when dayCount is 0', () {
      final script = ScriptBuilder.buildNightScript([], 0);
      expect(script, isNotEmpty);
      expect(script.any((s) => s.id == 'intro_01'), isTrue);
    });

    test('returns setup script when players list is empty', () {
      final script = ScriptBuilder.buildNightScript([], 1);
      expect(script, isNotEmpty);
      expect(script.any((s) => s.id == 'intro_01'), isTrue);
    });

    test('generates basic night script for active roles', () {
      final players = [
        makePlayer('1', RoleIds.dealer, nightPriority: 10),
        makePlayer(
          '2',
          RoleIds.medic,
          nightPriority: 20,
          medicChoice: 'PROTECT_DAILY',
        ),
      ];

      final script = ScriptBuilder.buildNightScript(players, 1);

      expect(script.any((s) => s.id.startsWith('dealer_act_')), isTrue);
      expect(script.any((s) => s.id.startsWith('medic_act_')), isTrue);
    });

    test('sorts steps by nightPriority', () {
      final players = [
        makePlayer(
          '1',
          RoleIds.medic,
          nightPriority: 20,
          medicChoice: 'PROTECT_DAILY',
        ),
        makePlayer('2', RoleIds.dealer, nightPriority: 10),
      ];

      final script = ScriptBuilder.buildNightScript(players, 1);

      final dealerIndex = script.indexWhere(
        (s) => s.id.startsWith('dealer_act_'),
      );
      final medicIndex = script.indexWhere(
        (s) => s.id.startsWith('medic_act_'),
      );

      expect(dealerIndex, lessThan(medicIndex));
    });

    test('dead players do not generate steps', () {
      final players = [makePlayer('1', RoleIds.dealer, isAlive: false)];

      final script = ScriptBuilder.buildNightScript(players, 1);

      expect(script.any((s) => s.id.startsWith('dealer_act_')), isFalse);
    });

    test('inactive players (joinsNextNight) do not generate steps', () {
      final players = [makePlayer('1', RoleIds.dealer, joinsNextNight: true)];

      final script = ScriptBuilder.buildNightScript(players, 1);

      expect(script.any((s) => s.id.startsWith('dealer_act_')), isFalse);
    });

    group('Special Roles', () {
      test('Attack Dog generates step when active and freed', () {
        final players = [
          makePlayer(
            '1',
            RoleIds.clinger,
            clingerFreedAsAttackDog: true,
            clingerAttackDogUsed: false,
          ),
        ];

        final script = ScriptBuilder.buildNightScript(players, 1);

        expect(script.any((s) => s.id.startsWith('attack_dog_act_')), isTrue);
      });

      test('Attack Dog does not generate step if already used', () {
        final players = [
          makePlayer(
            '1',
            RoleIds.clinger,
            clingerFreedAsAttackDog: true,
            clingerAttackDogUsed: true,
          ),
        ];

        final script = ScriptBuilder.buildNightScript(players, 1);

        expect(script.any((s) => s.id.startsWith('attack_dog_act_')), isFalse);
      });

      test('Messy Bitch Kill generates step when active and unused', () {
        final players = [
          makePlayer('1', RoleIds.messyBitch, messyBitchKillUsed: false),
        ];

        final script = ScriptBuilder.buildNightScript(players, 1);

        // Messy Bitch has a normal act AND a kill act?
        // Checking `ScriptBuilder` logic:
        // Regular MessyBitchStrategy is added via the loop over activePlayers.
        // MessyBitchKillStrategy is added via explicit check.

        expect(script.any((s) => s.id.startsWith('messy_bitch_act_')), isTrue);
        expect(script.any((s) => s.id.startsWith('messy_bitch_kill_')), isTrue);
      });

      test('Messy Bitch Kill does not generate step if used', () {
        final players = [
          makePlayer('1', RoleIds.messyBitch, messyBitchKillUsed: true),
        ];

        final script = ScriptBuilder.buildNightScript(players, 1);

        expect(script.any((s) => s.id.startsWith('messy_bitch_act_')), isTrue);
        expect(
          script.any((s) => s.id.startsWith('messy_bitch_kill_')),
          isFalse,
        );
      });

      test('Wallflower observation step is inserted after Dealer step', () {
        final players = [
          makePlayer('1', RoleIds.dealer, nightPriority: 10),
          makePlayer(
            '2',
            RoleIds.wallflower,
            nightPriority: 100,
          ), // Wallflower is passive usually but has a notice
        ];

        final script = ScriptBuilder.buildNightScript(players, 1);

        final dealerIndex = script.indexWhere(
          (s) => s.id.startsWith('dealer_act_'),
        );
        final wallflowerIndex = script.indexWhere(
          (s) => s.id.startsWith('wallflower_observe_'),
        );

        expect(dealerIndex, isNot(-1));
        expect(wallflowerIndex, isNot(-1));
        expect(wallflowerIndex, equals(dealerIndex + 1));
      });

      test('Wallflower observation step is NOT inserted if no Dealer step', () {
        final players = [
          makePlayer('2', RoleIds.wallflower),
          // No dealer
        ];

        final script = ScriptBuilder.buildNightScript(players, 1);
        expect(
          script.any((s) => s.id.startsWith('wallflower_observe_')),
          isFalse,
        );
      });
    });

    group('Medic', () {
      test('Medic generates step for PROTECT_DAILY', () {
        final players = [
          makePlayer('1', RoleIds.medic, medicChoice: 'PROTECT_DAILY'),
        ];
        final script = ScriptBuilder.buildNightScript(players, 1);
        expect(script.any((s) => s.id.startsWith('medic_act_')), isTrue);
      });

      test('Medic generates step for REVIVE if has token', () {
        final players = [
          makePlayer(
            '1',
            RoleIds.medic,
            medicChoice: 'REVIVE',
            hasReviveToken: true,
          ),
        ];
        final script = ScriptBuilder.buildNightScript(players, 1);
        expect(script.any((s) => s.id.startsWith('medic_act_')), isTrue);
      });

      test('Medic does NOT generate step for REVIVE if token used', () {
        final players = [
          makePlayer(
            '1',
            RoleIds.medic,
            medicChoice: 'REVIVE',
            hasReviveToken: false,
          ),
        ];
        final script = ScriptBuilder.buildNightScript(players, 1);
        expect(script.any((s) => s.id.startsWith('medic_act_')), isFalse);
      });
    });

    test('adds night_no_actions if no steps generated', () {
      // Create a player that is alive but has no night strategy (e.g. Party Animal)
      final players = [makePlayer('1', RoleIds.partyAnimal)];

      final script = ScriptBuilder.buildNightScript(players, 1);

      expect(script.any((s) => s.id.startsWith('night_no_actions_')), isTrue);
      // It should also have night_start and night_end
      expect(script.length, 3);
    });
  });

  group('ScriptBuilder.buildSetupScript', () {
    test('includes drama queen setup step with selectTwoPlayers action', () {
      final players = [
        makePlayer('1', RoleIds.dramaQueen),
        makePlayer('2', RoleIds.dealer),
        makePlayer('3', RoleIds.partyAnimal),
      ];

      final script = ScriptBuilder.buildSetupScript(players, dayCount: 0);
      final dramaStep = script.firstWhere(
        (s) => s.id.startsWith('drama_queen_setup_'),
      );

      expect(dramaStep.roleId, RoleIds.dramaQueen);
      expect(dramaStep.actionType, ScriptActionType.selectTwoPlayers);
    });
  });
}

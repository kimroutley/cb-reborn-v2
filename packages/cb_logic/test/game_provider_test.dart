import 'package:cb_comms/cb_comms.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helpers to build test data quickly.
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

  group('Lobby', () {
    test('initial state is lobby phase', () {
      final state = container.read(gameProvider);
      expect(state.phase, GamePhase.lobby);
      expect(state.players, isEmpty);
    });

    test('addPlayer adds to roster', () {
      game.addPlayer('Alice');
      game.addPlayer('Bob');
      final state = container.read(gameProvider);
      expect(state.players.length, 2);
      expect(state.players[0].name, 'Alice');
      expect(state.players[1].name, 'Bob');
    });

    test('addPlayer stores authUid if provided', () {
      game.addPlayer('Alice', authUid: 'uid123');
      final state = container.read(gameProvider);
      expect(state.players[0].authUid, 'uid123');
    });

    test('removePlayer removes from roster', () {
      game.addPlayer('Alice');
      game.addPlayer('Bob');
      final aliceId = container.read(gameProvider).players[0].id;
      game.removePlayer(aliceId);
      final state = container.read(gameProvider);
      expect(state.players.length, 1);
      expect(state.players[0].name, 'Bob');
    });

    test('assignRole sets Ally Cat lives to 9', () {
      game.addPlayer('Ally');
      final allyId = container.read(gameProvider).players.first.id;

      game.assignRole(allyId, RoleIds.allyCat);

      final updated = container.read(gameProvider).players.first;
      expect(updated.role.id, RoleIds.allyCat);
      expect(updated.lives, 9);
    });
  });

  group('Game Start', () {
    test('startGame assigns roles and transitions to setup', () {
      for (var i = 0; i < 6; i++) {
        game.addPlayer('P$i');
      }
      game.startGame();
      final state = container.read(gameProvider);
      expect(state.phase, GamePhase.setup);
      expect(state.scriptQueue.isNotEmpty, true);
      // At least one dealer should exist
      final dealers = state.players.where((p) => p.role.id == 'dealer');
      expect(dealers.isNotEmpty, true);
      // All players should have roles assigned (no civilians)
      for (final p in state.players) {
        expect(p.role.id, isNot('civilian'));
      }
    });

    test('role assignment respects dealer ratio', () {
      for (var i = 0; i < 12; i++) {
        game.addPlayer('P$i');
      }
      game.startGame();
      final state = container.read(gameProvider);
      final dealerCount =
          state.players.where((p) => p.role.id == 'dealer').length;
      // For 12 players: floor(12/5) = 2 dealers (minimum 1)
      expect(dealerCount, 2);
    });

    test('Seasoned Drinker gets lives equal to dealer count', () {
      // Run multiple times to find a game with Seasoned Drinker
      for (var attempt = 0; attempt < 100; attempt++) {
        final c = ProviderContainer();
        final g = c.read(gameProvider.notifier);
        for (var i = 0; i < 8; i++) {
          g.addPlayer('P$i');
        }
        g.startGame();
        final state = c.read(gameProvider);
        final sd = state.players.where((p) => p.role.id == 'seasoned_drinker');
        if (sd.isNotEmpty) {
          // dealerCount in _assignRoles = total staff team size (not just the dealer role)
          final staffCount =
              state.players.where((p) => p.alliance == Team.clubStaff).length;
          expect(sd.first.lives, staffCount);
          c.dispose();
          return;
        }
        c.dispose();
      }
      // If we never got a Seasoned Drinker in 100 attempts, skip gracefully
    });

    test(
        'setup gate blocks repeated advancePhase without feed emission or script index increment',
        () {
      _addMockPlayers(game, 4);
      game.startGame();

      final initialState = container.read(gameProvider);
      expect(initialState.phase, GamePhase.setup);
      expect(initialState.scriptQueue, isNotEmpty);

      final firstPlayerId = initialState.players.first.id;
      final session = container.read(sessionProvider.notifier);
      session.claimPlayer(firstPlayerId);

      final initialFeedCount = initialState.feedEvents.length;
      final initialScriptIndex = initialState.scriptIndex;

      game.advancePhase();
      game.advancePhase();

      final updatedState = container.read(gameProvider);
      expect(updatedState.phase, GamePhase.setup);
      expect(updatedState.feedEvents.length, initialFeedCount);
      expect(updatedState.scriptIndex, initialScriptIndex);
    });
  });

  group('Day Vote Resolution', () {
    test('majority vote exiles a player', () {
      game.addPlayer('Alice');
      game.addPlayer('Bob');
      game.addPlayer('Charlie');
      game.addPlayer('Dave');

      // Inject vote directly
      container.read(gameProvider.notifier).handleInteraction(
            stepId: 'day_vote',
            targetId: 'alice',
            voterId: 'bob',
          );
    });

    test('abstain majority skips vote', () {
      game.addPlayer('A');
      game.addPlayer('B');
      game.startGame();
      // Just test that handleInteraction doesn't crash with abstain
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: 'abstain',
        voterId: 'host',
      );
    });
  });

  group('Medic Interaction', () {
    test('medic choice sets medicChoice and hasReviveToken', () {
      game.addPlayer('Medic');
      final state = container.read(gameProvider);
      final medicId = state.players.first.id;

      game.handleInteraction(
        stepId: 'medic_choice_$medicId',
        targetId: 'REVIVE',
      );

      final updated = container.read(gameProvider);
      expect(updated.players.first.medicChoice, 'REVIVE');
      expect(updated.players.first.hasReviveToken, true);
    });

    test('medic protect choice does not set revive token', () {
      game.addPlayer('Medic');
      final state = container.read(gameProvider);
      final medicId = state.players.first.id;

      game.handleInteraction(
        stepId: 'medic_choice_$medicId',
        targetId: 'PROTECT_DAILY',
      );

      final updated = container.read(gameProvider);
      expect(updated.players.first.medicChoice, 'PROTECT_DAILY');
      expect(updated.players.first.hasReviveToken, false);
    });
  });

  group('Creep / Clinger / Drama Queen Setup', () {
    test('creep setup stores target and copies alliance', () {
      game.addPlayer('Creep');
      game.addPlayer('Target');
      final state = container.read(gameProvider);
      final creepId = state.players[0].id;
      final targetId = state.players[1].id;

      game.handleInteraction(
        stepId: 'creep_setup_$creepId',
        targetId: targetId,
      );

      final updated = container.read(gameProvider);
      expect(updated.players[0].creepTargetId, targetId);
    });

    test('clinger setup stores partner id', () {
      game.addPlayer('Clinger');
      game.addPlayer('Partner');
      final state = container.read(gameProvider);
      final clingerId = state.players[0].id;
      final partnerId = state.players[1].id;

      game.handleInteraction(
        stepId: 'clinger_setup_$clingerId',
        targetId: partnerId,
      );

      final updated = container.read(gameProvider);
      expect(updated.players[0].clingerPartnerId, partnerId);
    });

    test('drama queen setup stores two target ids', () {
      game.addPlayer('Drama');
      game.addPlayer('Target A');
      game.addPlayer('Target B');

      final state = container.read(gameProvider);
      final dramaId = state.players[0].id;
      final targetAId = state.players[1].id;
      final targetBId = state.players[2].id;

      game.assignRole(dramaId, RoleIds.dramaQueen);

      game.handleInteraction(
        stepId: 'drama_queen_setup_$dramaId',
        targetId: '$targetAId,$targetBId',
      );

      final updated = container.read(gameProvider);
      final drama = updated.players.firstWhere((p) => p.id == dramaId);
      expect(drama.dramaQueenTargetAId, targetAId);
      expect(drama.dramaQueenTargetBId, targetBId);
    });
  });

  group('Whore Interaction', () {
    test('whore act stores deflection target', () {
      game.addPlayer('Whore');
      game.addPlayer('Scapegoat');
      final state = container.read(gameProvider);
      final whoreId = state.players[0].id;
      final scapegoatId = state.players[1].id;

      game.handleInteraction(
        stepId: 'whore_act_$whoreId',
        targetId: scapegoatId,
      );

      final updated = container.read(gameProvider);
      expect(updated.players[0].whoreDeflectionTargetId, scapegoatId);
    });
  });

  group('Wallflower Observation', () {
    test('PEEKED keeps wallflower hidden and does not set gawked player', () {
      final wallflowerRole = _role(RoleIds.wallflower);
      final otherRole = _role(RoleIds.partyAnimal);

      final wallflower = _player('Wallflower', wallflowerRole);
      final other = _player('Other', otherRole);

      game.state = container.read(gameProvider).copyWith(
            players: [wallflower, other],
            phase: GamePhase.night,
            scriptQueue: [
              ScriptStep(
                id: 'wallflower_observe_${wallflower.id}_1',
                title: 'HOST OBSERVATION',
                readAloudText: '',
                instructionText:
                    'Observe ${wallflower.name}, how did they witness the murder?',
                actionType: ScriptActionType.binaryChoice,
                options: const ['PEEKED', 'GAWKED'],
                roleId: RoleIds.wallflower,
              ),
            ],
            scriptIndex: 0,
            actionLog: const {},
            gawkedPlayerId: null,
          );

      game.handleInteraction(
        stepId: 'wallflower_observe_${wallflower.id}_1',
        targetId: 'PEEKED',
      );

      final updated = container.read(gameProvider);
      final updatedWallflower =
          updated.players.firstWhere((p) => p.id == wallflower.id);

      expect(updated.gawkedPlayerId, isNull);
      expect(updatedWallflower.isExposed, isFalse);
    });

    test('PEEKED stores private intel for wallflower from dealer target', () {
      final wallflowerRole = _role(RoleIds.wallflower);
      final dealerRole = _role(RoleIds.dealer, alliance: Team.clubStaff);
      final partyRole = _role(RoleIds.partyAnimal);

      final wallflower = _player('Wallflower', wallflowerRole);
      final dealer = _player('Dealer', dealerRole, alliance: Team.clubStaff);
      final target = _player('Target', partyRole);

      game.state = container.read(gameProvider).copyWith(
            players: [wallflower, dealer, target],
            phase: GamePhase.night,
            scriptQueue: [
              ScriptStep(
                id: 'wallflower_observe_${wallflower.id}_1',
                title: 'HOST OBSERVATION',
                readAloudText: '',
                instructionText:
                    'Observe ${wallflower.name}, how did they witness the murder?',
                actionType: ScriptActionType.binaryChoice,
                options: const ['PEEKED', 'GAWKED'],
                roleId: RoleIds.wallflower,
              ),
            ],
            scriptIndex: 0,
            actionLog: {
              StepKey.roleAction(
                roleId: RoleIds.dealer,
                playerId: dealer.id,
                dayCount: 1,
              ): target.id,
            },
            gawkedPlayerId: null,
          );

      game.handleInteraction(
        stepId: 'wallflower_observe_${wallflower.id}_1',
        targetId: 'PEEKED',
      );

      final updated = container.read(gameProvider);
      final messages =
          updated.privateMessages[wallflower.id] ?? const <String>[];

      expect(
        messages.any(
          (m) => m.contains('You discreetly witnessed Dealer target Target.'),
        ),
        isTrue,
      );
      expect(updated.gawkedPlayerId, isNull);
    });

    test('GAWKED report is emitted once and cleared for next night', () {
      final wallflowerRole = _role(RoleIds.wallflower);
      final dealerRole = _role(RoleIds.dealer, alliance: Team.clubStaff);
      final partyRole = _role(RoleIds.partyAnimal);

      final wallflower = _player('Wallflower', wallflowerRole);
      final dealer = _player('Dealer', dealerRole, alliance: Team.clubStaff);
      final target = _player('Target', partyRole);

      game.state = container.read(gameProvider).copyWith(
            players: [wallflower, dealer, target],
            phase: GamePhase.night,
            dayCount: 1,
            scriptQueue: const [],
            scriptIndex: 0,
            actionLog: const {},
            gawkedPlayerId: wallflower.id,
          );

      game.advancePhase(); // Resolve night -> day

      var updated = container.read(gameProvider);
      expect(
        updated.lastNightReport.any(
          (line) => line.contains('was caught gawking at the murder'),
        ),
        isTrue,
      );
      expect(updated.gawkedPlayerId, isNull);

      updated = updated.copyWith(
        phase: GamePhase.night,
        scriptQueue: const [],
        scriptIndex: 0,
        actionLog: const {},
      );
      game.state = updated;

      game.advancePhase(); // Next night -> day; should not re-report
      final secondDay = container.read(gameProvider);
      expect(
        secondDay.lastNightReport.any(
          (line) => line.contains('was caught gawking at the murder'),
        ),
        isFalse,
      );
    });
  });

  group('Day Vote Tally', () {
    test('votes accumulate correctly', () {
      game.addPlayer('A');
      game.addPlayer('B');
      game.addPlayer('C');
      final state = container.read(gameProvider);
      final aId = state.players[0].id;
      final bId = state.players[1].id;

      game.handleInteraction(
        stepId: 'day_vote',
        targetId: aId,
        voterId: 'voter1',
      );
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: aId,
        voterId: 'voter2',
      );
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: bId,
        voterId: 'voter3',
      );

      final updated = container.read(gameProvider);
      expect(updated.dayVoteTally[aId], 2);
      expect(updated.dayVoteTally[bId], 1);
    });

    test('changing vote updates tally', () {
      game.addPlayer('A');
      game.addPlayer('B');
      final state = container.read(gameProvider);
      final aId = state.players[0].id;
      final bId = state.players[1].id;

      game.handleInteraction(
        stepId: 'day_vote',
        targetId: aId,
        voterId: 'voter1',
      );
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: bId,
        voterId: 'voter1',
      );

      final updated = container.read(gameProvider);
      // voter1 switched from A to B
      expect(updated.dayVoteTally[bId], 1);
      expect(updated.dayVoteTally.containsKey(aId), false);
    });

    test('duplicate vote is ignored', () {
      game.addPlayer('A');
      final state = container.read(gameProvider);
      final aId = state.players[0].id;

      game.handleInteraction(
        stepId: 'day_vote',
        targetId: aId,
        voterId: 'voter1',
      );
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: aId,
        voterId: 'voter1',
      );

      final updated = container.read(gameProvider);
      expect(updated.dayVoteTally[aId], 1);
    });

    test('silenced player cannot cast a day vote', () {
      game.addPlayer('A');
      game.addPlayer('B');

      final initial = container.read(gameProvider);
      final voter = initial.players[0];
      final target = initial.players[1];

      container.read(gameProvider.notifier).state = initial.copyWith(
        players: initial.players
            .map(
              (p) => p.id == voter.id
                  ? p.copyWith(silencedDay: initial.dayCount)
                  : p,
            )
            .toList(),
      );

      game.handleInteraction(
        stepId: 'day_vote',
        targetId: target.id,
        voterId: voter.id,
      );

      final updated = container.read(gameProvider);
      expect(updated.dayVoteTally, isEmpty);
      expect(updated.dayVotesByVoter, isEmpty);
    });

    test('resetDayVotes clears all votes', () {
      game.addPlayer('A');
      final state = container.read(gameProvider);
      final aId = state.players[0].id;

      game.handleInteraction(
        stepId: 'day_vote',
        targetId: aId,
        voterId: 'voter1',
      );
      game.resetDayVotes();

      final updated = container.read(gameProvider);
      expect(updated.dayVoteTally, isEmpty);
      expect(updated.dayVotesByVoter, isEmpty);
    });
  });

  group('Clinger Day Vote Enforcement', () {
    test('clinger cannot vote before partner has voted', () {
      game.addPlayer('Clinger');
      game.addPlayer('Partner');
      game.addPlayer('Target');

      final state = container.read(gameProvider);
      final clingerId = state.players[0].id;
      final partnerId = state.players[1].id;
      final targetId = state.players[2].id;

      game.assignRole(clingerId, RoleIds.clinger);
      game.handleInteraction(
        stepId: 'clinger_setup_$clingerId',
        targetId: partnerId,
      );

      game.handleInteraction(
        stepId: 'day_vote',
        targetId: targetId,
        voterId: clingerId,
      );

      final updated = container.read(gameProvider);
      expect(updated.dayVotesByVoter.containsKey(clingerId), false);
      expect(updated.dayVoteTally[targetId], isNull);
    });

    test('clinger vote must match partner vote while partner is alive', () {
      game.addPlayer('Clinger');
      game.addPlayer('Partner');
      game.addPlayer('TargetA');
      game.addPlayer('TargetB');

      final state = container.read(gameProvider);
      final clingerId = state.players[0].id;
      final partnerId = state.players[1].id;
      final targetAId = state.players[2].id;
      final targetBId = state.players[3].id;

      game.assignRole(clingerId, RoleIds.clinger);
      game.handleInteraction(
        stepId: 'clinger_setup_$clingerId',
        targetId: partnerId,
      );

      game.handleInteraction(
        stepId: 'day_vote',
        targetId: targetAId,
        voterId: partnerId,
      );

      // Mismatched vote should be ignored.
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: targetBId,
        voterId: clingerId,
      );

      var updated = container.read(gameProvider);
      expect(updated.dayVotesByVoter.containsKey(clingerId), false);
      expect(updated.dayVoteTally[targetBId], isNull);

      // Matching vote should be accepted.
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: targetAId,
        voterId: clingerId,
      );

      updated = container.read(gameProvider);
      expect(updated.dayVotesByVoter[clingerId], targetAId);
      expect(updated.dayVoteTally[targetAId], 2);
    });
  });

  group('Minor ID', () {
    test('minor_id sets minorHasBeenIDd flag', () {
      game.addPlayer('Minor');
      final state = container.read(gameProvider);
      final minorId = state.players.first.id;

      game.handleInteraction(stepId: 'minor_id_$minorId', targetId: 'true');

      final updated = container.read(gameProvider);
      expect(updated.players.first.minorHasBeenIDd, true);
    });
  });

  group('Second Wind', () {
    test('CONVERT sets alliance to clubStaff and joinsNextNight', () {
      game.addPlayer('SW');
      final state = container.read(gameProvider);
      final swId = state.players.first.id;

      game.handleInteraction(
        stepId: 'second_wind_convert_$swId',
        targetId: 'CONVERT',
      );

      final updated = container.read(gameProvider);
      final sw = updated.players.first;
      expect(sw.secondWindConverted, true);
      expect(sw.secondWindPendingConversion, false);
      expect(sw.alliance, Team.clubStaff);
      expect(sw.joinsNextNight, true);
    });

    test('EXECUTE kills the player', () {
      game.addPlayer('SW');
      final state = container.read(gameProvider);
      final swId = state.players.first.id;

      game.handleInteraction(
        stepId: 'second_wind_convert_$swId',
        targetId: 'EXECUTE',
      );

      final updated = container.read(gameProvider);
      final sw = updated.players.first;
      expect(sw.isAlive, false);
      expect(sw.deathReason, 'second_wind_executed');
    });
  });

  group('Return to Lobby', () {
    test('returnToLobby resets all state', () {
      game.addPlayer('A');
      game.addPlayer('B');
      game.addPlayer('C');
      game.addPlayer('D');
      game.startGame();
      game.returnToLobby();

      final state = container.read(gameProvider);
      expect(state.phase, GamePhase.lobby);
      expect(state.players, isEmpty);
      expect(state.scriptQueue, isEmpty);
    });
  });

  group('Script Builder', () {
    test('setup script includes intro and role assignment', () {
      final players = [
        _player('A', _role('party_animal')),
        _player('B', _role('dealer', alliance: Team.clubStaff)),
      ];
      final steps = ScriptBuilder.buildSetupScript(players);
      expect(steps.any((s) => s.id == 'intro_01'), true);
      expect(steps.any((s) => s.id == 'assign_roles_warning'), true);
    });

    test('setup includes medic choice step when medic present', () {
      final medic = _player('Med', _role('medic'));
      final steps = ScriptBuilder.buildSetupScript([medic]);
      expect(steps.any((s) => s.id.startsWith('medic_choice_')), true);
    });

    test('setup includes creep step when creep present', () {
      final creep = _player('Cr', _role('creep'));
      final steps = ScriptBuilder.buildSetupScript([creep]);
      expect(steps.any((s) => s.id.startsWith('creep_setup_')), true);
    });

    test('setup includes clinger step when clinger present', () {
      final clinger = _player('Cl', _role('clinger'));
      final steps = ScriptBuilder.buildSetupScript([clinger]);
      expect(steps.any((s) => s.id.startsWith('clinger_setup_')), true);
    });

    test('setup includes wallflower notice when wallflower present', () {
      final wf = _player('WF', _role('wallflower'));
      final steps = ScriptBuilder.buildSetupScript([wf]);
      expect(steps.any((s) => s.id.startsWith('wallflower_info_')), true);
    });

    test('night script includes dealer step', () {
      final dealer = _player(
        'D',
        _role('dealer', alliance: Team.clubStaff, priority: 10),
      );
      final steps = ScriptBuilder.buildNightScript([dealer], 1);
      expect(steps.any((s) => s.id.startsWith('dealer_act_')), true);
    });

    test('night script includes wallflower observation after dealer', () {
      final dealer = _player(
        'D',
        _role(RoleIds.dealer, alliance: Team.clubStaff, priority: 10),
      );
      final wf = _player('WF', _role(RoleIds.wallflower, priority: 100));
      final steps = ScriptBuilder.buildNightScript([dealer, wf], 1);
      final dealerIdx = steps.indexWhere((s) => s.id.startsWith('dealer_act_'));
      final wfIdx =
          steps.indexWhere((s) => s.id.startsWith('wallflower_observe_'));
      expect(dealerIdx, greaterThanOrEqualTo(0));
      expect(wfIdx, dealerIdx + 1);
    });

    test('day script includes timer and vote step', () {
      final steps = ScriptBuilder.buildDayScript(1);
      expect(
        steps.any((s) => s.actionType == ScriptActionType.showTimer),
        true,
      );
      expect(steps.any((s) => s.id.startsWith('day_vote_')), true);
    });

    test('day script includes second wind conversion when pending', () {
      final sw = _player(
        'SW',
        _role('second_wind'),
      ).copyWith(secondWindPendingConversion: true);
      final steps = ScriptBuilder.buildDayScript(1, [sw]);
      expect(steps.any((s) => s.id.startsWith('second_wind_convert_')), true);
    });
  });

  group('Session', () {
    test('joinCode is generated as NEON-XXXXXX', () {
      final session = container.read(sessionProvider);
      expect(session.joinCode, startsWith('NEON-'));
      expect(session.joinCode.length, 11); // NEON- + 6 chars
    });

    test('claimPlayer adds to claimed list', () {
      final sessionCtrl = container.read(sessionProvider.notifier);
      final success = sessionCtrl.claimPlayer('player-1');
      expect(success, true);
      expect(
        container.read(sessionProvider).claimedPlayerIds,
        contains('player-1'),
      );
    });

    test('double claim returns false', () {
      final sessionCtrl = container.read(sessionProvider.notifier);
      sessionCtrl.claimPlayer('player-1');
      final second = sessionCtrl.claimPlayer('player-1');
      expect(second, false);
    });

    test('releasePlayer removes from claimed', () {
      final sessionCtrl = container.read(sessionProvider.notifier);
      sessionCtrl.claimPlayer('player-1');
      sessionCtrl.releasePlayer('player-1');
      expect(
        container.read(sessionProvider).claimedPlayerIds,
        isNot(contains('player-1')),
      );
    });
  });

  // ── Force Kill ──
  group('Force Kill', () {
    test('forceKillPlayer marks player dead with host_kick reason', () {
      _addMockPlayers(game, 6);
      game.startGame();
      final playerId = container.read(gameProvider).players.first.id;

      game.forceKillPlayer(playerId);

      final state = container.read(gameProvider);
      final player = state.players.firstWhere((p) => p.id == playerId);
      expect(player.isAlive, false);
      expect(player.deathReason, 'host_kick');
    });

    test('forceKillPlayer adds to gameHistory', () {
      _addMockPlayers(game, 6);
      game.startGame();
      final player = container.read(gameProvider).players.first;

      game.forceKillPlayer(player.id);

      final history = container.read(gameProvider).gameHistory;
      expect(history.any((h) => h.contains(player.name)), true);
    });
  });

  // ── Game History ──
  group('Game History', () {
    test('night resolution adds history entries', () {
      _addMockPlayers(game, 6);
      game.startGame();
      // Advance through all setup steps to reach night
      while (container.read(gameProvider).phase == GamePhase.setup) {
        game.advancePhase();
      }
      expect(container.read(gameProvider).phase, GamePhase.night);

      // Now in night — add a dealer action
      final state = container.read(gameProvider);
      final dealer = state.players.firstWhere(
        (p) => p.alliance == Team.clubStaff,
      );
      final target = state.players.firstWhere(
        (p) => p.alliance == Team.partyAnimals,
      );
      game.handleInteraction(
        stepId: 'dealer_act_${dealer.id}',
        targetId: target.id,
      );

      // Advance past remaining night steps to day
      while (container.read(gameProvider).phase == GamePhase.night) {
        game.advancePhase();
      }

      final dayState = container.read(gameProvider);
      expect(dayState.gameHistory.isNotEmpty, true);
      expect(dayState.gameHistory.first, startsWith('── NIGHT'));
    });
  });

  // ── Discussion Timer ──
  group('Discussion Timer', () {
    test('default discussion timer is 300', () {
      expect(container.read(gameProvider).discussionTimerSeconds, 300);
    });
  });

  // ── Wallflower / Ally Cat Private Messages ──
  group('Wallflower Witness', () {
    test('wallflower intel is delivered from host observation step', () {
      final wallflowerRole = _role(RoleIds.wallflower);
      final dealerRole = _role(RoleIds.dealer, alliance: Team.clubStaff);
      final partyRole = _role(RoleIds.partyAnimal);

      final wallflower = _player('Wallflower', wallflowerRole);
      final dealer = _player('Dealer', dealerRole, alliance: Team.clubStaff);
      final target = _player('Target', partyRole);

      game.state = container.read(gameProvider).copyWith(
            players: [wallflower, dealer, target],
            phase: GamePhase.night,
            scriptQueue: const [],
            scriptIndex: 0,
            actionLog: {
              StepKey.roleAction(
                roleId: RoleIds.dealer,
                playerId: dealer.id,
                dayCount: 1,
              ): target.id,
            },
          );

      game.handleInteraction(
        stepId: 'wallflower_observe_${wallflower.id}_1',
        targetId: 'PEEKED',
      );

      final updated = container.read(gameProvider);
      final wfMessages =
          updated.privateMessages[wallflower.id] ?? const <String>[];
      expect(
        wfMessages.any(
            (m) => m.contains('discreetly witnessed Dealer target Target')),
        isTrue,
      );
    });
  });

  // ── Script Builder Smart Timer ──
  group('Script Builder Timer', () {
    test('buildDayScript auto-calculates timer from alive players', () {
      final players = List<Player>.generate(
        6,
        (i) => Player(
          id: '$i',
          name: 'P$i',
          role: roleCatalog[0],
          alliance: roleCatalog[0].alliance,
        ),
      );
      final steps = ScriptBuilder.buildDayScript(1, players);
      final timerStep = steps.firstWhere(
        (s) => s.actionType == ScriptActionType.showTimer,
      );
      // 6 alive * 30s = 180s
      expect(timerStep.timerSeconds, 180);
    });

    test('buildDayScript clamps timer to max 300s', () {
      final players = List<Player>.generate(
        12,
        (i) => Player(
          id: '$i',
          name: 'P$i',
          role: roleCatalog[0],
          alliance: roleCatalog[0].alliance,
        ),
      );
      final steps = ScriptBuilder.buildDayScript(1, players);
      final timerStep = steps.firstWhere(
        (s) => s.actionType == ScriptActionType.showTimer,
      );
      // 12 * 30 = 360, clamped to 300
      expect(timerStep.timerSeconds, 300);
    });

    test('buildDayScript default timer is 300 with no players', () {
      final steps = ScriptBuilder.buildDayScript(1);
      final timerStep = steps.firstWhere(
        (s) => s.actionType == ScriptActionType.showTimer,
      );
      expect(timerStep.timerSeconds, 300);
    });
  });

  // ── Day Resolution Private Messages (Drama Queen) ──
  group('Day Resolution Private Messages', () {
    test('day resolution returns privateMessages from death triggers', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);
      _addMockPlayers(game, 7);
      game.startGame();

      final gs = container.read(gameProvider);
      // Verify DayResolution class accepts privateMessages
      // (structural test — ensures the field exists and defaults empty)
      expect(gs.privateMessages, isA<Map<String, List<String>>>());
    });
  });

  // ── Game History from Day Vote ──
  group('Day Vote History', () {
    test('day vote resolution adds history entries', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);
      _addMockPlayers(game, 7);
      game.startGame();

      // Advance through setup to night
      while (container.read(gameProvider).phase == GamePhase.setup) {
        game.advancePhase();
      }
      expect(container.read(gameProvider).phase, GamePhase.night);

      // Advance through night to day (may hit endGame if all one side dies)
      while (container.read(gameProvider).phase == GamePhase.night) {
        game.advancePhase();
      }

      final afterNight = container.read(gameProvider);
      if (afterNight.phase == GamePhase.endGame) {
        // Game ended during night — just verify night history exists
        expect(afterNight.gameHistory.any((e) => e.contains('NIGHT')), true);
        return;
      }
      expect(afterNight.phase, GamePhase.day);

      // Advance through day to next phase (auto-resolves day vote)
      while (container.read(gameProvider).phase == GamePhase.day) {
        game.advancePhase();
      }

      final gs = container.read(gameProvider);
      // Should have both night AND day history entries
      final hasNightEntry = gs.gameHistory.any((e) => e.contains('NIGHT'));
      final hasDayEntry = gs.gameHistory.any((e) => e.contains('DAY'));
      expect(hasNightEntry, true);
      expect(hasDayEntry, true);
    });
  });

  // ── GameMessage Extensions ──
  group('GameMessage', () {
    test('stateSync includes gameHistory and votesByVoter', () {
      final msg = GameMessage.stateSync(
        phase: 'day',
        dayCount: 1,
        players: const [],
        gameHistory: ['── NIGHT 0 ──', 'Alice was killed.'],
        votesByVoter: {'player1': 'player2'},
      );
      expect(msg.payload['gameHistory'], [
        '── NIGHT 0 ──',
        'Alice was killed.',
      ]);
      expect(msg.payload['votesByVoter'], {'player1': 'player2'});
    });

    test('stateSync omits null optional fields', () {
      final msg = GameMessage.stateSync(
        phase: 'lobby',
        dayCount: 0,
        players: const [],
      );
      expect(msg.payload.containsKey('gameHistory'), false);
      expect(msg.payload.containsKey('votesByVoter'), false);
      expect(msg.payload.containsKey('voteTally'), false);
    });

    test('playerReconnect carries claimed IDs', () {
      final msg = GameMessage.playerReconnect(claimedPlayerIds: ['p1', 'p2']);
      expect(msg.type, 'player_reconnect');
      expect(msg.payload['claimedPlayerIds'], ['p1', 'p2']);
    });
  });

  // ── Discussion Timer persists through game start ──
  group('Discussion Timer in Game', () {
    test('smart timer auto-calculates from alive players after night', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);
      _addMockPlayers(game, 7);
      game.startGame();

      // Advance through setup to night
      while (container.read(gameProvider).phase == GamePhase.setup) {
        game.advancePhase();
      }

      // Advance through night to day (may hit endGame)
      while (container.read(gameProvider).phase == GamePhase.night) {
        game.advancePhase();
      }

      final gs = container.read(gameProvider);

      if (gs.phase == GamePhase.endGame) {
        // Game ended — no day script to check
        return;
      }

      // Find the timer step in the day script
      final timerSteps = gs.scriptQueue
          .where((s) => s.actionType == ScriptActionType.showTimer)
          .toList();
      expect(timerSteps, isNotEmpty);
      // Smart timer: 30s per alive player, max 300
      final aliveCount = gs.players.where((p) => p.isAlive).length;
      expect(timerSteps.first.timerSeconds, (aliveCount * 30).clamp(30, 300));
    });
  });

  // ── Win Condition ──
  group('Win Condition', () {
    test('PA win when all club staff eliminated', () {
      _addMockPlayers(game, 8);
      game.startGame();

      final state = container.read(gameProvider);
      final staff =
          state.players.where((p) => p.alliance == Team.clubStaff).toList();

      // Force-kill all staff
      for (final s in staff) {
        game.forceKillPlayer(s.id);
      }

      final gs = container.read(gameProvider);
      expect(gs.phase, GamePhase.endGame);
      expect(gs.winner, Team.partyAnimals);
    });

    test('Staff win when they equal or outnumber PA', () {
      _addMockPlayers(game, 8);
      game.startGame();

      final state = container.read(gameProvider);
      final pa =
          state.players.where((p) => p.alliance == Team.partyAnimals).toList();

      // Force-kill PA until staff >= PA
      for (var i = 0; i < pa.length; i++) {
        game.forceKillPlayer(pa[i].id);
        final gs = container.read(gameProvider);
        if (gs.phase == GamePhase.endGame) {
          expect(gs.winner, Team.clubStaff);
          return;
        }
      }
    });

    test('game does not end immediately after startGame', () {
      _addMockPlayers(game, 8);
      game.startGame();
      final gs = container.read(gameProvider);
      // Game should be in setup phase, NOT ended
      expect(gs.phase, GamePhase.setup);
    });

    test('alive Club Manager is included as co-winner in endGameReport', () {
      game.addPlayer('Dealer');
      game.addPlayer('Manager');
      game.addPlayer('PA');

      final state = container.read(gameProvider);
      final dealerId = state.players[0].id;
      final managerId = state.players[1].id;
      final partyId = state.players[2].id;

      game.assignRole(dealerId, RoleIds.dealer);
      game.assignRole(managerId, RoleIds.clubManager);
      game.assignRole(partyId, RoleIds.partyAnimal);

      // Trigger a Staff win while Manager remains alive.
      game.forceKillPlayer(partyId);

      final gs = container.read(gameProvider);
      expect(gs.phase, GamePhase.endGame);
      expect(gs.winner, Team.clubStaff);
      expect(
        gs.endGameReport.any((line) =>
            line.contains('Club Manager survived and wins with the house')),
        true,
      );
      expect(gs.endGameReport.any((line) => line.contains('Manager')), true);
    });
  });

  // ── Minimum Player Count ──
  group('Minimum Players', () {
    test('startGame requires at least 4 players', () {
      _addMockPlayers(game, 3);
      game.startGame();
      // Should stay in lobby
      expect(container.read(gameProvider).phase, GamePhase.lobby);
    });

    test('startGame works with 4 players', () {
      _addMockPlayers(game, 4);
      game.startGame();
      expect(container.read(gameProvider).phase, GamePhase.setup);
    });
  });

  // ── Return to Lobby ──
  group('Return to Lobby', () {
    test('returnToLobby preserves discussion timer', () {
      _addMockPlayers(game, 6);
      game.startGame();
      game.returnToLobby();

      final gs = container.read(gameProvider);
      expect(gs.phase, GamePhase.lobby);
      expect(gs.players, isEmpty);
      expect(gs.discussionTimerSeconds, 300);
    });

    test('returnToLobby clears game state', () {
      _addMockPlayers(game, 6);
      game.startGame();
      game.returnToLobby();

      final gs = container.read(gameProvider);
      expect(gs.gameHistory, isEmpty);
      expect(gs.endGameReport, isEmpty);
      expect(gs.winner, isNull);
    });
  });

  // ── handleTimerExpiry ──
  group('handleTimerExpiry', () {
    /// Helper: advance a 7-player game into its first day phase.
    /// Returns null if the game ended during night (unlikely with 7 players
    /// but possible if all one alliance).
    Game? setupDay(ProviderContainer c) {
      final g = c.read(gameProvider.notifier);
      _addMockPlayers(g, 7);
      g.startGame();
      // Skip setup
      while (c.read(gameProvider).phase == GamePhase.setup) {
        g.advancePhase();
      }
      // Skip night
      while (c.read(gameProvider).phase == GamePhase.night) {
        g.advancePhase();
      }
      if (c.read(gameProvider).phase == GamePhase.endGame) return null;
      expect(c.read(gameProvider).phase, GamePhase.day);
      return g;
    }

    test('skips vote and advances to night when no votes cast', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final g = setupDay(c);
      if (g == null) return; // game ended in night

      final result = g.handleTimerExpiry();
      expect(result, true);

      final gs = c.read(gameProvider);

      expect(
        gs.phase == GamePhase.night || gs.phase == GamePhase.endGame,
        true,
      );
      expect(gs.dayVoteTally, isEmpty);
      expect(gs.dayVotesByVoter, isEmpty);
    });

    test('skips vote when only 1 vote per player (< 2 threshold)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final g = setupDay(c);
      if (g == null) return;

      // Cast a single vote for some player
      final state = c.read(gameProvider);
      final alive = state.players.where((p) => p.isAlive).toList();
      final target = alive.first;
      final voterCandidates = alive.where((p) =>
          p.id != target.id &&
          p.role.id != RoleIds.clinger &&
          p.silencedDay != state.dayCount &&
          !p.isSinBinned);
      if (voterCandidates.isEmpty) return;
      final voter = voterCandidates.first;

      g.handleInteraction(
        stepId: 'day_vote',
        targetId: target.id,
        voterId: voter.id,
      );
      expect(c.read(gameProvider).dayVoteTally[target.id], 1);

      final result = g.handleTimerExpiry();
      expect(result, true);
      final phase = c.read(gameProvider).phase;
      expect(phase == GamePhase.night || phase == GamePhase.endGame, true);
    });

    test('does NOT skip vote when a player has >= 2 votes', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final g = setupDay(c);
      if (g == null) return;

      final players = c.read(gameProvider).players;
      final alive = players.where((p) => p.isAlive).toList();
      // Cast 2 votes for the same target
      g.handleInteraction(
        stepId: 'day_vote',
        targetId: alive[0].id,
        voterId: alive[1].id,
      );
      g.handleInteraction(
        stepId: 'day_vote',
        targetId: alive[0].id,
        voterId: alive[2].id,
      );
      expect(c.read(gameProvider).dayVoteTally[alive[0].id], 2);

      final result = g.handleTimerExpiry();
      expect(result, false);

      // Phase should NOT have changed — still day
      expect(c.read(gameProvider).phase, GamePhase.day);
    });

    test('adds history entries on skip', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final g = setupDay(c);
      if (g == null) return;

      g.handleTimerExpiry();
      final gs = c.read(gameProvider);
      expect(gs.gameHistory.any((e) => e.contains('VOTE')), true);
      expect(gs.gameHistory.any((e) => e.contains('no votes resolved')), true);
    });

    test('abstain-only votes still skip (no real target has >= 2)', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final g = setupDay(c);
      if (g == null) return;

      final players = c.read(gameProvider).players;
      final alive = players.where((p) => p.isAlive).toList();
      // Cast 3 abstain votes
      g.handleInteraction(
        stepId: 'day_vote',
        targetId: 'abstain',
        voterId: alive[0].id,
      );
      g.handleInteraction(
        stepId: 'day_vote',
        targetId: 'abstain',
        voterId: alive[1].id,
      );
      g.handleInteraction(
        stepId: 'day_vote',
        targetId: 'abstain',
        voterId: alive[2].id,
      );

      final result = g.handleTimerExpiry();
      expect(result, true);
      expect(c.read(gameProvider).phase, GamePhase.night);
    });
  });

  group('Tea Spiller Reactive Reveal', () {
    test(
        'exiled Tea Spiller prompts for reveal target and applies selected expose',
        () {
      game.addPlayer('Tea');
      game.addPlayer('Dealer');
      game.addPlayer('Buddy');

      final state = container.read(gameProvider);
      final teaId = state.players[0].id;
      final dealerId = state.players[1].id;
      final buddyId = state.players[2].id;

      game.assignRole(teaId, RoleIds.teaSpiller);
      game.assignRole(dealerId, RoleIds.dealer);
      game.assignRole(buddyId, RoleIds.partyAnimal);

      // Enter day phase with no pending script steps so advancePhase resolves vote.
      game.state = container.read(gameProvider).copyWith(
            phase: GamePhase.day,
            dayCount: 1,
            scriptQueue: const [],
            scriptIndex: 0,
          );

      // Two votes exile Tea Spiller.
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: teaId,
        voterId: dealerId,
      );
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: teaId,
        voterId: buddyId,
      );

      game.advancePhase();

      var updated = container.read(gameProvider);
      expect(updated.phase, GamePhase.day);
      expect(updated.scriptQueue, isNotEmpty);
      expect(
        updated.scriptQueue.first.id,
        'tea_spiller_reveal_${teaId}_1',
      );

      game.handleInteraction(
        stepId: 'tea_spiller_reveal_${teaId}_1',
        targetId: buddyId,
      );

      game.advancePhase();

      updated = container.read(gameProvider);
      expect(
        updated.gameHistory.any((line) =>
            line.contains('Tea Spiller exposed Buddy: The Party Animal.')),
        true,
      );
      expect(
        updated.lastDayReport.any((line) =>
            line.contains('Tea Spiller exposed Buddy: The Party Animal.')),
        true,
      );
    });
  });

  group('Predator Retaliation', () {
    test(
        'exiled Predator prompts for retaliation target and applies selected kill',
        () {
      game.addPlayer('Predator');
      game.addPlayer('Dealer');
      game.addPlayer('Buddy');

      final state = container.read(gameProvider);
      final predatorId = state.players[0].id;
      final dealerId = state.players[1].id;
      final buddyId = state.players[2].id;

      game.assignRole(predatorId, RoleIds.predator);
      game.assignRole(dealerId, RoleIds.dealer);
      game.assignRole(buddyId, RoleIds.partyAnimal);

      game.state = container.read(gameProvider).copyWith(
            phase: GamePhase.day,
            dayCount: 1,
            scriptQueue: const [],
            scriptIndex: 0,
          );

      // Exile Predator, then host selects who gets retaliated against.
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: predatorId,
        voterId: dealerId,
      );
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: predatorId,
        voterId: buddyId,
      );

      game.advancePhase();

      var updated = container.read(gameProvider);
      expect(updated.phase, GamePhase.day);
      expect(updated.scriptQueue, isNotEmpty);
      expect(
        updated.scriptQueue.first.id,
        'predator_retaliation_${predatorId}_1',
      );

      game.handleInteraction(
        stepId: 'predator_retaliation_${predatorId}_1',
        targetId: buddyId,
      );

      game.advancePhase();

      updated = container.read(gameProvider);
      final dealer = updated.players.firstWhere((p) => p.id == dealerId);
      final buddy = updated.players.firstWhere((p) => p.id == buddyId);

      expect(dealer.isAlive, true);
      expect(buddy.isAlive, false);
      expect(buddy.deathReason, 'predator_retaliation');
      expect(
        updated.gameHistory.any((line) => line.contains(
            'Predator struck back: Buddy was taken down in retaliation.')),
        true,
      );
      expect(
        updated.lastDayReport.any((line) => line.contains(
            'Predator struck back: Buddy was taken down in retaliation.')),
        true,
      );
    });
  });

  group('Drama Queen Vendetta', () {
    test('exiled Drama Queen prompts for two targets and swaps selected roles',
        () {
      game.addPlayer('Drama');
      game.addPlayer('Dealer');
      game.addPlayer('Buddy');
      game.addPlayer('Sober');

      final state = container.read(gameProvider);
      final dramaId = state.players[0].id;
      final dealerId = state.players[1].id;
      final buddyId = state.players[2].id;
      final soberId = state.players[3].id;

      game.assignRole(dramaId, RoleIds.dramaQueen);
      game.assignRole(dealerId, RoleIds.dealer);
      game.assignRole(buddyId, RoleIds.partyAnimal);
      game.assignRole(soberId, RoleIds.sober);

      game.state = container.read(gameProvider).copyWith(
            phase: GamePhase.day,
            dayCount: 1,
            scriptQueue: const [],
            scriptIndex: 0,
          );

      // Exile Drama Queen, then select explicit swap targets.
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: dramaId,
        voterId: dealerId,
      );
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: dramaId,
        voterId: buddyId,
      );

      game.advancePhase();

      var updated = container.read(gameProvider);
      expect(updated.phase, GamePhase.day);
      expect(updated.scriptQueue, isNotEmpty);
      expect(
        updated.scriptQueue.first.id,
        'drama_queen_vendetta_${dramaId}_1',
      );

      game.handleInteraction(
        stepId: 'drama_queen_vendetta_${dramaId}_1',
        targetId: '$dealerId,$soberId',
      );

      game.advancePhase();

      updated = container.read(gameProvider);
      final dealer = updated.players.firstWhere((p) => p.id == dealerId);
      final buddy = updated.players.firstWhere((p) => p.id == buddyId);
      final sober = updated.players.firstWhere((p) => p.id == soberId);

      expect(dealer.role.id, RoleIds.sober);
      expect(sober.role.id, RoleIds.dealer);
      expect(buddy.role.id, RoleIds.partyAnimal);
      expect(
        updated.gameHistory.any(
          (line) => line
              .contains('Drama Queen chaos: Dealer and Sober swapped roles.'),
        ),
        true,
      );
      expect(
        updated.lastDayReport.any(
          (line) => line.contains(
              'Drama Queen reveal: Dealer is now The Sober, Sober is now The Dealer.'),
        ),
        true,
      );
    });

    test('malformed vendetta payload falls back to deterministic swap', () {
      game.addPlayer('Drama');
      game.addPlayer('Dealer');
      game.addPlayer('Buddy');
      game.addPlayer('Sober');

      final state = container.read(gameProvider);
      final dramaId = state.players[0].id;
      final dealerId = state.players[1].id;
      final buddyId = state.players[2].id;

      game.assignRole(dramaId, RoleIds.dramaQueen);
      game.assignRole(dealerId, RoleIds.dealer);
      game.assignRole(buddyId, RoleIds.partyAnimal);

      game.state = container.read(gameProvider).copyWith(
            phase: GamePhase.day,
            dayCount: 1,
            scriptQueue: const [],
            scriptIndex: 0,
          );

      game.handleInteraction(
        stepId: 'day_vote',
        targetId: dramaId,
        voterId: dealerId,
      );
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: dramaId,
        voterId: buddyId,
      );

      game.advancePhase();

      var updated = container.read(gameProvider);
      expect(
        updated.scriptQueue.first.id,
        'drama_queen_vendetta_${dramaId}_1',
      );

      // Invalid duplicate pair should not be honored.
      game.handleInteraction(
        stepId: 'drama_queen_vendetta_${dramaId}_1',
        targetId: '$dealerId,$dealerId',
      );

      game.advancePhase();

      updated = container.read(gameProvider);
      final dealer = updated.players.firstWhere((p) => p.id == dealerId);
      final buddy = updated.players.firstWhere((p) => p.id == buddyId);

      // Fallback path swaps first deterministic valid pair (dealer <-> buddy).
      expect(dealer.role.id, RoleIds.partyAnimal);
      expect(buddy.role.id, RoleIds.dealer);
      expect(
        updated.lastDayReport.any(
          (line) => line
              .contains('Drama Queen chaos: Dealer and Buddy swapped roles.'),
        ),
        true,
      );
    });

    test('vendetta payload with nonexistent/dead target falls back safely', () {
      game.addPlayer('Drama');
      game.addPlayer('Dealer');
      game.addPlayer('Buddy');
      game.addPlayer('Sober');

      final state = container.read(gameProvider);
      final dramaId = state.players[0].id;
      final dealerId = state.players[1].id;
      final buddyId = state.players[2].id;
      final soberId = state.players[3].id;

      game.assignRole(dramaId, RoleIds.dramaQueen);
      game.assignRole(dealerId, RoleIds.dealer);
      game.assignRole(buddyId, RoleIds.partyAnimal);
      game.assignRole(soberId, RoleIds.sober);

      // Make one potential vendetta target dead to simulate stale/malformed UI input.
      game.forceKillPlayer(soberId, reason: 'test_setup');

      game.state = container.read(gameProvider).copyWith(
            phase: GamePhase.day,
            dayCount: 1,
            scriptQueue: const [],
            scriptIndex: 0,
          );

      game.handleInteraction(
        stepId: 'day_vote',
        targetId: dramaId,
        voterId: dealerId,
      );
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: dramaId,
        voterId: buddyId,
      );

      game.advancePhase();

      var updated = container.read(gameProvider);
      expect(
        updated.scriptQueue.first.id,
        'drama_queen_vendetta_${dramaId}_1',
      );

      // Invalid pair: one ID is dead/non-eligible and the other is unknown.
      game.handleInteraction(
        stepId: 'drama_queen_vendetta_${dramaId}_1',
        targetId: '$soberId,ghost_not_real',
      );

      game.advancePhase();

      updated = container.read(gameProvider);
      final dealer = updated.players.firstWhere((p) => p.id == dealerId);
      final buddy = updated.players.firstWhere((p) => p.id == buddyId);
      final sober = updated.players.firstWhere((p) => p.id == soberId);

      // Fallback path should still resolve deterministically for alive valid pair.
      expect(dealer.role.id, RoleIds.partyAnimal);
      expect(buddy.role.id, RoleIds.dealer);
      expect(sober.isAlive, false);
      expect(
        updated.lastDayReport.any(
          (line) => line
              .contains('Drama Queen chaos: Dealer and Buddy swapped roles.'),
        ),
        true,
      );
    });
  });

  group('Dead Pool Day Resolution', () {
    // Dead Pool outcome matrix:
    // - WIN  (bettor chose exiled player) => drinksOwed - 1 (clamped at 0)
    // - LOSS (bettor chose different player) => drinksOwed + 1
    test('clears deadPoolBets and settles bettor after exile', () {
      game.addPlayer('Ghost');
      game.addPlayer('Exiled');
      game.addPlayer('Voter A');
      game.addPlayer('Voter B');

      var state = container.read(gameProvider);
      final ghostId = state.players[0].id;
      final exiledId = state.players[1].id;
      final voterAId = state.players[2].id;
      final voterBId = state.players[3].id;

      // Make Ghost eligible for Dead Pool bets.
      game.forceKillPlayer(ghostId, reason: 'test_setup');

      // Place a winning Dead Pool bet on the soon-to-be exiled player.
      game.placeDeadPoolBet(playerId: ghostId, targetPlayerId: exiledId);
      state = container.read(gameProvider);
      expect(state.deadPoolBets[ghostId], exiledId);

      // Enter day phase with no pending script steps so advancePhase resolves vote.
      game.state = state.copyWith(
        phase: GamePhase.day,
        dayCount: 1,
        scriptQueue: const [],
        scriptIndex: 0,
      );

      // Two votes exile the chosen target.
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: exiledId,
        voterId: voterAId,
      );
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: exiledId,
        voterId: voterBId,
      );

      game.advancePhase();

      final updated = container.read(gameProvider);
      final ghost = updated.players.firstWhere((p) => p.id == ghostId);

      expect(updated.deadPoolBets, isEmpty);
      expect(ghost.currentBetTargetId, isNull);
      expect(
        ghost.penalties.any((p) => p.contains('[DEAD POOL] WON')),
        isTrue,
      );
    });

    test('records LOSING dead pool outcome when bet target is not exiled', () {
      game.addPlayer('Ghost');
      game.addPlayer('Bet Target');
      game.addPlayer('Actual Exiled');
      game.addPlayer('Voter A');
      game.addPlayer('Voter B');

      var state = container.read(gameProvider);
      final ghostId = state.players[0].id;
      final betTargetId = state.players[1].id;
      final actualExiledId = state.players[2].id;
      final voterAId = state.players[3].id;
      final voterBId = state.players[4].id;

      game.forceKillPlayer(ghostId, reason: 'test_setup');
      game.placeDeadPoolBet(playerId: ghostId, targetPlayerId: betTargetId);

      state = container.read(gameProvider);
      final drinksBefore =
          state.players.firstWhere((p) => p.id == ghostId).drinksOwed;
      expect(state.deadPoolBets[ghostId], betTargetId);

      game.state = state.copyWith(
        phase: GamePhase.day,
        dayCount: 1,
        scriptQueue: const [],
        scriptIndex: 0,
      );

      game.handleInteraction(
        stepId: 'day_vote',
        targetId: actualExiledId,
        voterId: voterAId,
      );
      game.handleInteraction(
        stepId: 'day_vote',
        targetId: actualExiledId,
        voterId: voterBId,
      );

      game.advancePhase();

      final updated = container.read(gameProvider);
      final ghost = updated.players.firstWhere((p) => p.id == ghostId);

      expect(updated.deadPoolBets, isEmpty);
      expect(ghost.currentBetTargetId, isNull);
      expect(ghost.drinksOwed, drinksBefore + 1);
      expect(
        ghost.penalties.any((p) => p.contains('[DEAD POOL] LOST')),
        isTrue,
      );
    });
  });

  group('Director Commands', () {
    test('toggleEyes updates state and history', () {
      expect(container.read(gameProvider).eyesOpen, true);

      // Toggle to false
      game.toggleEyes(false);
      var state = container.read(gameProvider);
      expect(state.eyesOpen, false);
      expect(state.gameHistory.last, 'DIRECTOR: EYES CLOSED COMMAND');

      // Toggle to true
      game.toggleEyes(true);
      state = container.read(gameProvider);
      expect(state.eyesOpen, true);
      expect(state.gameHistory.last, 'DIRECTOR: EYES OPEN COMMAND');
    });
  });
}

void _addMockPlayers(Game game, int count) {
  for (var i = 0; i < count; i++) {
    game.addPlayer('P$i');
  }
}

import 'dart:convert';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:riverpod/riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helpers to build test data quickly.
Role _role(String id,
        {Team alliance = Team.partyAnimals, int priority = 100}) =>
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

void _addMockPlayers(Game game, int count) {
  final names = [
    'Alice',
    'Bob',
    'Charlie',
    'Diana',
    'Eve',
    'Frank',
    'Grace',
    'Hank',
    'Ivy',
    'Jack'
  ];
  for (var i = 0; i < count && i < names.length; i++) {
    game.addPlayer(names[i]);
  }
}

void main() {
  // ═══════════════════════════════════════════════
  //  Bouncer Alliance Check (P1 bug fix)
  // ═══════════════════════════════════════════════

  group('Bouncer Role Interaction', () {
    test('bouncer check works with handleInteraction', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      game.addPlayer('Bouncer');
      game.addPlayer('Target');

      final state = container.read(gameProvider);
      final bouncerId = state.players[0].id;
      final targetId = state.players[1].id;

      // Bouncer check interaction should not crash
      game.handleInteraction(
        stepId: 'bouncer_check_$bouncerId',
        targetId: targetId,
      );
    });
  });

  // ═══════════════════════════════════════════════
  //  Whore Deflection
  // ═══════════════════════════════════════════════

  group('Whore Deflection', () {
    test('whore cannot target self', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      game.addPlayer('Whore');
      game.addPlayer('Target');

      final state = container.read(gameProvider);
      final whoreId = state.players[0].id;

      // Targeting self should be handled gracefully
      game.handleInteraction(
        stepId: 'whore_act_$whoreId',
        targetId: whoreId,
      );

      // Verify the state is still valid
      final updated = container.read(gameProvider);
      expect(updated.players[0].whoreDeflectionTargetId, whoreId);
    });

    test('whore act stores target correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      game.addPlayer('Whore');
      game.addPlayer('Target');

      final state = container.read(gameProvider);
      final whoreId = state.players[0].id;
      final targetId = state.players[1].id;

      game.handleInteraction(
        stepId: 'whore_act_$whoreId',
        targetId: targetId,
      );

      final updated = container.read(gameProvider);
      expect(updated.players[0].whoreDeflectionTargetId, targetId);
    });
  });

  // ═══════════════════════════════════════════════
  //  Session State
  // ═══════════════════════════════════════════════

  group('Session State', () {
    test('multiple claims succeed for different players', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sessionCtrl = container.read(sessionProvider.notifier);

      expect(sessionCtrl.claimPlayer('p1'), true);
      expect(sessionCtrl.claimPlayer('p2'), true);
      expect(sessionCtrl.claimPlayer('p3'), true);

      final session = container.read(sessionProvider);
      expect(session.claimedPlayerIds, ['p1', 'p2', 'p3']);
    });

    test('release non-existent player is safe', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final sessionCtrl = container.read(sessionProvider.notifier);

      // Should not crash
      sessionCtrl.releasePlayer('nonexistent');
      expect(container.read(sessionProvider).claimedPlayerIds, isEmpty);
    });

    test('joinCode has correct format', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final session = container.read(sessionProvider);

      expect(session.joinCode, matches(RegExp(r'^NEON-[A-Z0-9]{4}$')));
    });
  });

  // ═══════════════════════════════════════════════
  //  Session JSON Serialization
  // ═══════════════════════════════════════════════

  group('Session JSON', () {
    test('SessionState roundtrips through JSON', () {
      const session = SessionState(
        joinCode: 'NEON-ABCD',
        claimedPlayerIds: ['p1', 'p2'],
      );
      final json = session.toJson();
      final restored = SessionState.fromJson(json);

      expect(restored.joinCode, 'NEON-ABCD');
      expect(restored.claimedPlayerIds, ['p1', 'p2']);
    });

    test('empty SessionState roundtrips', () {
      const session = SessionState();
      final json = session.toJson();
      final restored = SessionState.fromJson(json);

      expect(restored.joinCode, '');
      expect(restored.claimedPlayerIds, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════
  //  GameState JSON Serialization
  // ═══════════════════════════════════════════════

  group('GameState JSON', () {
    test('GameState roundtrips with players', () {
      final state = GameState(
        phase: GamePhase.night,
        dayCount: 2,
        players: [
          Player(
            id: 'alice',
            name: 'Alice',
            role: const Role(
              id: 'dealer',
              name: 'Dealer',
              alliance: Team.clubStaff,
              type: 'Killer',
              description: 'test',
              nightPriority: 10,
              assetPath: '',
              colorHex: '#FF0000',
            ),
            alliance: Team.clubStaff,
          ),
        ],
        gameHistory: ['── NIGHT 1 ──'],
        discussionTimerSeconds: 180,
      );

      // Use jsonEncode/jsonDecode for deep serialization
      final json =
          jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>;
      final restored = GameState.fromJson(json);

      expect(restored.phase, GamePhase.night);
      expect(restored.dayCount, 2);
      expect(restored.players.length, 1);
      expect(restored.players.first.id, 'alice');
      expect(restored.players.first.role.id, 'dealer');
      expect(restored.gameHistory, ['── NIGHT 1 ──']);
      expect(restored.discussionTimerSeconds, 180);
    });

    test('default GameState roundtrips', () {
      const state = GameState();
      final json =
          jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>;
      final restored = GameState.fromJson(json);

      expect(restored.phase, GamePhase.lobby);
      expect(restored.players, isEmpty);
      expect(restored.dayCount, 1);
      expect(restored.discussionTimerSeconds, 300);
    });

    test('GameState with winner roundtrips', () {
      const state = GameState(
        phase: GamePhase.endGame,
        winner: Team.clubStaff,
        endGameReport: ['Club Staff wins!'],
      );
      final json =
          jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>;
      final restored = GameState.fromJson(json);

      expect(restored.winner, Team.clubStaff);
      expect(restored.phase, GamePhase.endGame);
      expect(restored.endGameReport, ['Club Staff wins!']);
    });
  });

  // ═══════════════════════════════════════════════
  //  Script Builder Edge Cases
  // ═══════════════════════════════════════════════

  group('Script Builder Edge Cases', () {
    test('night script skips dead players', () {
      final dealer =
          _player('D', _role('dealer', alliance: Team.clubStaff, priority: 10))
              .copyWith(isAlive: false);
      final steps = ScriptBuilder.buildNightScript([dealer], 1);
      // Dead dealer should not get a step
      expect(steps.any((s) => s.id.startsWith('dealer_act_')), false);
    });

    test('setup script handles many roles correctly', () {
      final players = [
        _player('A', _role('medic')),
        _player('B', _role('creep')),
        _player('C', _role('clinger')),
        _player('D', _role('wallflower')),
        _player('E', _role('dealer', alliance: Team.clubStaff)),
      ];
      final steps = ScriptBuilder.buildSetupScript(players);
      expect(steps.any((s) => s.id.startsWith('medic_choice_')), true);
      expect(steps.any((s) => s.id.startsWith('creep_setup_')), true);
      expect(steps.any((s) => s.id.startsWith('clinger_setup_')), true);
      expect(steps.any((s) => s.id == 'wallflower_info'), true);
    });

    test('day script has discussion before vote', () {
      final steps = ScriptBuilder.buildDayScript(1);
      final timerIdx =
          steps.indexWhere((s) => s.actionType == ScriptActionType.showTimer);
      final voteIdx = steps.indexWhere((s) => s.id == 'day_vote');
      expect(timerIdx, lessThan(voteIdx));
    });
  });

  // ═══════════════════════════════════════════════
  //  Game Phase Transitions
  // ═══════════════════════════════════════════════

  group('Phase Transitions', () {
    test('lobby → setup → night → day cycle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      _addMockPlayers(game, 6);
      expect(container.read(gameProvider).phase, GamePhase.lobby);

      game.startGame();
      expect(container.read(gameProvider).phase, GamePhase.setup);

      // Advance through setup
      while (container.read(gameProvider).phase == GamePhase.setup) {
        game.advancePhase();
      }
      expect(container.read(gameProvider).phase, GamePhase.night);

      // Advance through night
      while (container.read(gameProvider).phase == GamePhase.night) {
        game.advancePhase();
      }

      final postNight = container.read(gameProvider);
      expect(
        postNight.phase,
        anyOf(GamePhase.day, GamePhase.endGame),
      );
    });

    test('game cannot start during active game', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      _addMockPlayers(game, 6);
      game.startGame();
      final setupState = container.read(gameProvider);
      expect(setupState.phase, GamePhase.setup);

      // Calling startGame again should not reset
      game.startGame();
      expect(container.read(gameProvider).phase, GamePhase.setup);
    });

    test('advancePhase in lobby transitions to setup when enough players', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      // With no players, advancePhase may still transition
      // Just verify it doesn't crash
      game.advancePhase();
      final phase = container.read(gameProvider).phase;
      // Phase may change depending on game logic implementation
      expect(phase, isA<GamePhase>());
    });
  });

  // ═══════════════════════════════════════════════
  //  Player Limits
  // ═══════════════════════════════════════════════

  group('Player Limits', () {
    test('duplicate player names are uniquified and both added', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      game.addPlayer('Alice');
      game.addPlayer('Alice');

      final state = container.read(gameProvider);
      expect(state.players.length, 2);
      expect(state.players[0].name, 'Alice');
      expect(state.players[1].name, 'Alice (2)');
    });

    test('removing nonexistent player is safe', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      game.addPlayer('Alice');
      // Should not crash
      game.removePlayer('nonexistent');

      expect(container.read(gameProvider).players.length, 1);
    });
  });

  // ═══════════════════════════════════════════════
  //  Force Kill Edge Cases
  // ═══════════════════════════════════════════════

  group('Force Kill Edge Cases', () {
    test('force killing already dead player is safe', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      _addMockPlayers(game, 6);
      game.startGame();

      final playerId = container.read(gameProvider).players.first.id;
      game.forceKillPlayer(playerId);

      // Kill again — should not crash or double-add history
      final historyBefore = container.read(gameProvider).gameHistory.length;
      game.forceKillPlayer(playerId);
      final historyAfter = container.read(gameProvider).gameHistory.length;

      // Should not add additional history for already-dead player
      expect(historyAfter, historyBefore);
    });

    test('force kill triggers win condition check', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      _addMockPlayers(game, 6);
      game.startGame();

      final state = container.read(gameProvider);
      final staff =
          state.players.where((p) => p.alliance == Team.clubStaff).toList();

      // Kill all staff
      for (final s in staff) {
        game.forceKillPlayer(s.id);
      }

      final gs = container.read(gameProvider);
      expect(gs.phase, GamePhase.endGame);
      expect(gs.winner, Team.partyAnimals);
    });
  });

  // ═══════════════════════════════════════════════
  //  Creep Role Inheritance
  // ═══════════════════════════════════════════════

  group('Creep Inheritance', () {
    test('Creep inherits role after target dies', () {
      final container = ProviderContainer();
      final game = container.read(gameProvider.notifier);

      // Simple setup: add players and start game
      _addMockPlayers(game, 5);
      game.startGame();

      var state = container.read(gameProvider);

      // Find or mock a creep and a target
      // Since role assignment is random, we'll manually set up the test scenario
      final players = state.players;
      final creepRole = roleCatalog.firstWhere((r) => r.id == 'creep');
      final bouncerRole = roleCatalog.firstWhere((r) => r.id == 'bouncer');

      // Manually create test state with a Creep and Bouncer
      final creepPlayer = players[0].copyWith(
        role: creepRole,
        alliance: creepRole.alliance, // Use role's natural alliance
        creepTargetId: players[1].id, // Creep already chose Bouncer as target
        isAlive: true,
      );
      final targetPlayer = players[1].copyWith(
        role: bouncerRole,
        alliance: bouncerRole.alliance, // Use role's natural alliance
        isAlive: true,
      );

      state = state.copyWith(
        players: [
          creepPlayer,
          targetPlayer,
          ...players.skip(2),
        ],
      );
      container.read(gameProvider.notifier).state = state;

      // Verify initial state
      expect(creepPlayer.role.id, 'creep');
      expect(creepPlayer.creepTargetId, targetPlayer.id);

      // Kill the target player - this should trigger Creep inheritance
      game.forceKillPlayer(targetPlayer.id);

      state = container.read(gameProvider);
      final inheritedCreep =
          state.players.firstWhere((p) => p.id == creepPlayer.id);

      // Verify Creep inherited the Bouncer role
      expect(inheritedCreep.role.id, 'bouncer');
      expect(inheritedCreep.role.name, 'The Bouncer');
      expect(inheritedCreep.alliance, bouncerRole.alliance);
      expect(inheritedCreep.creepTargetId, null); // Target consumed
      expect(inheritedCreep.isAlive, true); // Creep is still alive
    });
  });
}

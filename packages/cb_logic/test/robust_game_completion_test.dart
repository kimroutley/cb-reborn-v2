import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

void _addPlayers(Game game, int count) {
  for (var i = 0; i < count; i++) {
    game.addPlayer('P$i');
  }
}

void _assertStateInvariants(GameState state) {
  final ids = state.players.map((p) => p.id).toList();
  expect(ids.toSet().length, ids.length,
      reason: 'Player IDs must remain unique.');

  for (final p in state.players) {
    if (p.isAlive) {
      expect(p.isSinBinned, isFalse,
          reason: 'Alive player ${p.name} should not be sin-binned.');
    }
  }

  if (state.scriptQueue.isNotEmpty) {
    expect(
      state.scriptIndex,
      inInclusiveRange(0, state.scriptQueue.length - 1),
      reason: 'scriptIndex must remain within scriptQueue bounds.',
    );
    if (state.currentStep != null) {
      expect(
        state.currentStep!.id,
        state.scriptQueue[state.scriptIndex].id,
        reason: 'currentStep should align with scriptQueue/scriptIndex.',
      );
    }
  }

  if (state.phase == GamePhase.endGame) {
    expect(state.winner, isNotNull,
        reason: 'End game state must have a winner.');
  }
}

void _runUntilEndOrFail(
  ProviderContainer container,
  Game game, {
  int maxTicks = 3000,
  int maxStagnantTicks = 120,
}) {
  var ticks = 0;
  var stagnantTicks = 0;
  String? lastFingerprint;

  while (ticks < maxTicks) {
    final state = container.read(gameProvider);
    _assertStateInvariants(state);

    if (state.phase == GamePhase.endGame) {
      return;
    }

    final step = state.currentStep;
    if (step != null) {
      final isInteractive =
          step.actionType == ScriptActionType.selectPlayer ||
              step.actionType == ScriptActionType.selectTwoPlayers ||
              step.actionType == ScriptActionType.binaryChoice ||
              step.actionType == ScriptActionType.multiSelect ||
              step.actionType == ScriptActionType.optional ||
              step.id.startsWith('day_vote_');

      if (isInteractive) {
        game.simulatePlayersForCurrentStep();
      }
    }

    game.advancePhase();
    ticks++;

    final next = container.read(gameProvider);
    final fingerprint =
        '${next.phase.name}|${next.dayCount}|${next.scriptIndex}|${next.currentStep?.id}|${next.actionLog.length}|${next.dayVotesByVoter.length}';

    if (fingerprint == lastFingerprint) {
      stagnantTicks++;
    } else {
      stagnantTicks = 0;
      lastFingerprint = fingerprint;
    }

    expect(
      stagnantTicks,
      lessThan(maxStagnantTicks),
      reason: 'Game flow appears stalled at $fingerprint.',
    );
  }

  final stuck = container.read(gameProvider);
  fail(
    'Game did not finish within $maxTicks ticks. '
    'phase=${stuck.phase}, day=${stuck.dayCount}, '
    'step=${stuck.currentStep?.id}, scriptIndex=${stuck.scriptIndex}.',
  );
}

void main() {
  group('Robust game completion regressions', () {
    test('manual high-friction roster reaches valid completion', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final game = container.read(gameProvider.notifier);
      game.setGameStyle(GameStyle.manual);

      const criticalRoles = <String>[
        RoleIds.dealer,
        RoleIds.medic,
        RoleIds.secondWind,
        RoleIds.dramaQueen,
        RoleIds.clinger,
        RoleIds.creep,
        RoleIds.teaSpiller,
        RoleIds.predator,
        RoleIds.bouncer,
        RoleIds.sober,
      ];

      for (var i = 0; i < criticalRoles.length; i++) {
        game.addPlayer('R$i');
        final state = container.read(gameProvider);
        game.assignRole(state.players.last.id, criticalRoles[i]);
      }

      final started = game.startGame();
      expect(started, isTrue, reason: 'Manual high-friction game must start.');

      _runUntilEndOrFail(container, game, maxTicks: 3500);

      final finalState = container.read(gameProvider);
      expect(finalState.phase, GamePhase.endGame);
      expect(finalState.winner, isNotNull);
    });

    test('multi-style invariant soak completes repeatedly', () {
      final styles = <GameStyle>[
        GameStyle.offensive,
        GameStyle.defensive,
        GameStyle.reactive,
        GameStyle.chaos,
      ];

      const runsPerStyle = 8;
      var totalRuns = 0;

      for (final style in styles) {
        for (var i = 0; i < runsPerStyle; i++) {
          final container = ProviderContainer();
          final game = container.read(gameProvider.notifier);

          game.setGameStyle(style);
          _addPlayers(game, 11);

          final started = game.startGame();
          expect(started, isTrue,
              reason: 'Game must start for $style run ${i + 1}.');

          _runUntilEndOrFail(
            container,
            game,
            maxTicks: 3000,
            maxStagnantTicks: 140,
          );

          final finalState = container.read(gameProvider);
          expect(finalState.phase, GamePhase.endGame,
              reason: 'Expected endGame for $style run ${i + 1}.');
          expect(finalState.winner, isNotNull,
              reason: 'Winner missing for $style run ${i + 1}.');

          totalRuns++;
          container.dispose();
        }
      }

      expect(totalRuns, styles.length * runsPerStyle);
    });
  });
}

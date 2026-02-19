import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

List<Player> _allRolePlayers() {
  return roleCatalog
      .map(
        (role) => Player(
          id: 'p_${role.id}',
          name: role.name,
          role: role,
          alliance: role.alliance,
        ),
      )
      .toList();
}

void main() {
  group('All-roles script audit', () {
    test('setup script includes expected role setup directives', () {
      final players = _allRolePlayers();
      final steps = ScriptBuilder.buildSetupScript(players, dayCount: 0);

      expect(steps, isNotEmpty);
      expect(steps.first.id, 'intro_01');
      expect(steps[1].id, 'assign_roles_warning');

      expect(steps.any((s) => s.id.startsWith('medic_choice_')), isTrue);
      expect(steps.any((s) => s.id.startsWith('creep_setup_')), isTrue);
      expect(steps.any((s) => s.id.startsWith('clinger_setup_')), isTrue);
      expect(steps.any((s) => s.id.startsWith('drama_queen_setup_')), isTrue);
      expect(steps.any((s) => s.id.startsWith('wallflower_info_')), isTrue);
    });

    test('night script keeps core action priorities in ascending order', () {
      final players = _allRolePlayers();
      final steps = ScriptBuilder.buildNightScript(players, 1);

      expect(steps.first.id, 'night_start_1');
      expect(steps.last.id, 'night_end_1');

      final dealerIdx = steps.indexWhere((s) => s.id.startsWith('dealer_act_'));
      final observationIdx =
          steps.indexWhere((s) => s.id.startsWith('wallflower_observe_'));
      expect(dealerIdx, greaterThanOrEqualTo(0));
      expect(observationIdx, dealerIdx + 1);

      int? priorityForStep(String stepId) {
        if (stepId.startsWith('dealer_act_')) {
          return roleCatalogMap[RoleIds.dealer]?.nightPriority;
        }
        if (stepId.startsWith('silver_fox_act_')) {
          return roleCatalogMap[RoleIds.silverFox]?.nightPriority;
        }
        if (stepId.startsWith('whore_act_')) {
          return roleCatalogMap[RoleIds.whore]?.nightPriority;
        }
        if (stepId.startsWith('sober_act_')) {
          return roleCatalogMap[RoleIds.sober]?.nightPriority;
        }
        if (stepId.startsWith('roofi_act_')) {
          return roleCatalogMap[RoleIds.roofi]?.nightPriority;
        }
        if (stepId.startsWith('bouncer_act_')) {
          return roleCatalogMap[RoleIds.bouncer]?.nightPriority;
        }
        if (stepId.startsWith('medic_act_')) {
          return roleCatalogMap[RoleIds.medic]?.nightPriority;
        }
        if (stepId.startsWith('bartender_act_')) {
          return roleCatalogMap[RoleIds.bartender]?.nightPriority;
        }
        if (stepId.startsWith('lightweight_act_')) {
          return roleCatalogMap[RoleIds.lightweight]?.nightPriority;
        }
        if (stepId.startsWith('messy_bitch_act_')) {
          return roleCatalogMap[RoleIds.messyBitch]?.nightPriority;
        }
        if (stepId.startsWith('club_manager_act_')) {
          return roleCatalogMap[RoleIds.clubManager]?.nightPriority;
        }
        return null;
      }

      final orderedPriorities =
          steps.map((s) => priorityForStep(s.id)).whereType<int>().toList();

      for (var i = 1; i < orderedPriorities.length; i++) {
        expect(
          orderedPriorities[i],
          greaterThanOrEqualTo(orderedPriorities[i - 1]),
          reason: 'Night priorities should not decrease at index $i',
        );
      }
    });

    test(
        'manual game with all roles progresses setup->night->day->night in order',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final game = container.read(gameProvider.notifier);
      game.setGameStyle(GameStyle.manual);

      final roles = roleCatalog;
      for (final role in roles) {
        final name = role.name;
        game.addPlayer(name);
        final state = container.read(gameProvider);
        final id = state.players.last.id;
        game.assignRole(id, role.id);
      }

      final started = game.startGame();
      expect(started, isTrue);

      var reachedNextNight = false;
      var guard = 0;
      while (guard < 400) {
        guard++;
        final state = container.read(gameProvider);

        if (state.phase == GamePhase.night && state.dayCount >= 2) {
          reachedNextNight = true;
          break;
        }

        if (state.scriptQueue.isNotEmpty &&
            state.scriptIndex >= 0 &&
            state.scriptIndex < state.scriptQueue.length) {
          expect(state.currentStep, isNotNull);
          expect(
            state.currentStep!.id,
            state.scriptQueue[state.scriptIndex].id,
            reason: 'currentStep should align with scriptQueue/scriptIndex',
          );
        }

        final step = state.currentStep;
        if (step != null) {
          if (step.id.startsWith('day_vote_')) {
            final alive = state.players
                .where((p) => p.isAlive && !p.isSinBinned)
                .toList();
            if (alive.length >= 2) {
              final voter = alive.first;
              final target = alive.firstWhere(
                (p) => p.id != voter.id,
                orElse: () => alive.last,
              );
              game.handleInteraction(
                stepId: step.id,
                voterId: voter.id,
                targetId: target.id,
              );
            }
          } else if (step.actionType == ScriptActionType.binaryChoice ||
              step.actionType == ScriptActionType.selectPlayer ||
              step.actionType == ScriptActionType.selectTwoPlayers) {
            game.simulatePlayersForCurrentStep();
          }
        }

        game.advancePhase();

        final afterAdvance = container.read(gameProvider);
        if (afterAdvance.phase == GamePhase.endGame) {
          break;
        }
      }

      expect(guard, lessThan(400), reason: 'Flow should not stall');
      expect(
        reachedNextNight ||
            container.read(gameProvider).phase == GamePhase.endGame,
        isTrue,
        reason: 'Game should reach next night or end naturally after one cycle',
      );
    });
  });
}

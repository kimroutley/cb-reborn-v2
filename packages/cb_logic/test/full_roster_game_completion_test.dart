import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

// ─── HELPER FUNCTIONS ───

/// Runs a game loop simulation until EndGame or maxSteps reached.
/// Returns true if game finished successfully.
Future<void> _runSimulation(ProviderContainer container, Game game, {int maxSteps = 3000}) async {
  var guard = 0;

  while (container.read(gameProvider).phase != GamePhase.endGame && guard < maxSteps) {
    final state = container.read(gameProvider);
    final step = state.currentStep;

    if (step != null) {
      // Is this an interactive step?
      final isInteractive = step.actionType == ScriptActionType.selectPlayer ||
          step.actionType == ScriptActionType.selectTwoPlayers ||
          step.actionType == ScriptActionType.binaryChoice ||
          step.actionType == ScriptActionType.multiSelect ||
          step.actionType == ScriptActionType.optional ||
          step.id.startsWith('day_vote');

      if (isInteractive) {
        // Check if input is already provided (Host mediated or player action)
        final alreadyActed = state.actionLog.containsKey(step.id);

        // Day Votes require special handling as they don't always populate actionLog 1:1 like night actions
        // Host actions (roleId == null) also need simulation
        if (!alreadyActed || step.id.startsWith('day_vote')) {
           // Simulate inputs for all players/bots/host required for this step
           game.simulatePlayersForCurrentStep();
        }
      }
    }

    // Advance logic (Resolution or Next Step)
    game.advancePhase();
    guard++;
  }

  if (container.read(gameProvider).phase != GamePhase.endGame) {
    fail('Simulation timed out after $maxSteps steps. Stuck in ${container.read(gameProvider).phase}');
  }
}

void main() {
  group(
    'Superseded full roster game completion suite',
    skip: 'Superseded: removed from required automated test gates',
    () {
  // ─── SUITE 1: COMPREHENSIVE ROSTER STRESS TESTS ───
  group('Comprehensive Game Flow Tests', () {

    test('Scenario A: "The Full House" (Manual Setup, All Roles)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      game.setGameStyle(GameStyle.manual);

      // Add every single role
      for (final role in roleCatalog) {
        final name = role.name.replaceAll(' ', '');
        game.addPlayer(name);
        final state = container.read(gameProvider);
        game.assignRole(state.players.last.id, role.id);
      }

      expect(game.startGame(), isTrue, reason: "Failed to start Full House game");
      await _runSimulation(container, game);

      final finalState = container.read(gameProvider);
      expect(finalState.winner, isNotNull);
    });

    test('Scenario B: "Offensive Meta" (Auto-Assign, High Aggression)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      game.setGameStyle(GameStyle.offensive);

      // Add 15 generic players
      for (var i = 0; i < 15; i++) {
        game.addPlayer('Player_$i');
      }

      expect(game.startGame(), isTrue);

      // Verify role distribution leans offensive
      final state = container.read(gameProvider);
      final hasDealers = state.players.any((p) => p.role.id == RoleIds.dealer);
      expect(hasDealers, isTrue);

      await _runSimulation(container, game);
      expect(container.read(gameProvider).winner, isNotNull);
    });

    test('Scenario C: "Defensive Meta" (Auto-Assign, Protection Heavy)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final game = container.read(gameProvider.notifier);

      game.setGameStyle(GameStyle.defensive);

      for (var i = 0; i < 12; i++) {
        game.addPlayer('Player_$i');
      }

      expect(game.startGame(), isTrue);
      await _runSimulation(container, game);
      expect(container.read(gameProvider).winner, isNotNull);
    });
  });

  // ─── SUITE 2: TARGETED MECHANICS SCENARIOS ───
  // These tests "force" specific outcomes to ensure the logic engine handles them correctly.

  group('Targeted Mechanics Scenarios', () {

    test('Mechanic: Medic Save (Prevention of Death)', () async {
      final container = ProviderContainer();
      final game = container.read(gameProvider.notifier);
      game.setGameStyle(GameStyle.manual);

      // Roster: Dealer, Medic, Victim, Bystander
      game.addPlayer('Dealer');
      game.addPlayer('Medic');
      game.addPlayer('Victim');
      game.addPlayer('Bystander');

      final s1 = container.read(gameProvider);
      game.assignRole(s1.players[0].id, RoleIds.dealer);
      game.assignRole(s1.players[1].id, RoleIds.medic);
      game.assignRole(s1.players[2].id, RoleIds.partyAnimal); // Victim
      game.assignRole(s1.players[3].id, RoleIds.partyAnimal);

      game.startGame();

      // Advance through setup
      while(container.read(gameProvider).phase == GamePhase.setup) {
        // Handle medic choice
        final step = container.read(gameProvider).currentStep;
        if (step != null && step.id.startsWith('medic_choice')) {
           game.handleInteraction(stepId: step.id, targetId: 'PROTECT_DAILY');
        }
        game.advancePhase();
      }

      // Now in Night 1. Respect scripted queue order and only submit
      // interactions when the matching step is active.
      final dealer = s1.players[0];
      final victim = s1.players[2];
      final medic = s1.players[1];

      while (container.read(gameProvider).phase == GamePhase.night) {
        final step = container.read(gameProvider).currentStep;

        if (step != null) {
          if (step.id.startsWith('dealer_act_${dealer.id}_')) {
            game.handleInteraction(stepId: step.id, targetId: victim.id);
          } else if (step.id.startsWith('medic_act_${medic.id}_')) {
            game.handleInteraction(stepId: step.id, targetId: victim.id);
          } else {
            game.simulatePlayersForCurrentStep();
          }
        }

        game.advancePhase();
      }

      // Assert Victim is Alive
      final dayState = container.read(gameProvider);
      final victimState = dayState.players.firstWhere((p) => p.id == victim.id);

      expect(victimState.isAlive, isTrue, reason: "Medic save failed - Victim died");
      expect(dayState.lastNightReport.any((s) => s.contains('Medic protected')), isTrue);
    });

    test('Mechanic: Whore Deflection (Sacrificial Lamb)', () async {
      final container = ProviderContainer();
      final game = container.read(gameProvider.notifier);
      game.setGameStyle(GameStyle.manual);

      // Roster: Whore, Dealer, Scapegoat, Voter
      game.addPlayer('Whore');
      game.addPlayer('Dealer');
      game.addPlayer('Scapegoat');
      game.addPlayer('Voter');

      final s1 = container.read(gameProvider);
      final whore = s1.players[0];
      final dealer = s1.players[1];
      final scapegoat = s1.players[2];
      final voter = s1.players[3];

      game.assignRole(whore.id, RoleIds.whore);
      game.assignRole(dealer.id, RoleIds.dealer);
      game.assignRole(scapegoat.id, RoleIds.partyAnimal);
      game.assignRole(voter.id, RoleIds.partyAnimal);

      game.startGame();

      // Advance to Night 1
      while(container.read(gameProvider).phase != GamePhase.night) { game.advancePhase(); }

      // Whore selects Scapegoat
      final whoreStep = 'whore_act_${whore.id}_1';
      game.handleInteraction(stepId: whoreStep, targetId: scapegoat.id);

      // Advance to Day 1
      while(container.read(gameProvider).phase != GamePhase.day) {
        // Skip other night actions
        game.simulatePlayersForCurrentStep();
        game.advancePhase();
      }

      // Skip to voting
      while(container.read(gameProvider).currentStep?.id.startsWith('day_vote') != true) {
        game.advancePhase();
      }

      // Everyone votes for Dealer
      final voteStep = 'day_vote_1';
      game.handleInteraction(stepId: voteStep, voterId: voter.id, targetId: dealer.id);
      game.handleInteraction(stepId: voteStep, voterId: scapegoat.id, targetId: dealer.id);
      game.handleInteraction(stepId: voteStep, voterId: whore.id, targetId: dealer.id);
      // Dealer votes self just to ensure majority
      game.handleInteraction(stepId: voteStep, voterId: dealer.id, targetId: dealer.id);

      // Resolve Day
      game.advancePhase();

      final endState = container.read(gameProvider);

      final dealerState = endState.players.firstWhere((p) => p.id == dealer.id);
      final scapegoatState = endState.players.firstWhere((p) => p.id == scapegoat.id);

      expect(dealerState.isAlive, isTrue, reason: "Whore deflection failed: Dealer died");
      expect(scapegoatState.isAlive, isFalse, reason: "Whore deflection failed: Scapegoat survived");
      expect(scapegoatState.deathReason, 'whore_deflection');
    });

    test('Mechanic: Second Wind (Survival & Conversion)', () async {
      final container = ProviderContainer();
      final game = container.read(gameProvider.notifier);
      game.setGameStyle(GameStyle.manual);

      game.addPlayer('Dealer');
      game.addPlayer('SecondWind');
      game.addPlayer('Bystander1');
      game.addPlayer('Bystander2');

      final s1 = container.read(gameProvider);
      final dealer = s1.players[0];
      final sw = s1.players[1];

      game.assignRole(dealer.id, RoleIds.dealer);
      game.assignRole(sw.id, RoleIds.secondWind);

      game.startGame();

      // Setup -> Night 1
      while(container.read(gameProvider).phase != GamePhase.night) { game.advancePhase(); }

      // Dealer kills Second Wind
      final dealerStep = 'dealer_act_${dealer.id}_1';
      game.handleInteraction(stepId: dealerStep, targetId: sw.id);

      // Resolve Night -> Day 1
      while(container.read(gameProvider).phase != GamePhase.day) {
        game.simulatePlayersForCurrentStep(); // Handle other passive/skips
        game.advancePhase();
      }

      // Assert Second Wind is Alive
      var dayState = container.read(gameProvider);
      var swState = dayState.players.firstWhere((p) => p.id == sw.id);
      expect(swState.isAlive, isTrue, reason: "Second Wind should survive first kill");
      expect(swState.secondWindPendingConversion, isTrue);

      // Verify Prompt appears
      final currentStep = dayState.currentStep;
      expect(currentStep?.id, startsWith('second_wind_convert_'));

      // Host chooses CONVERT
      game.handleInteraction(stepId: currentStep!.id, targetId: 'CONVERT');
      game.advancePhase();

      dayState = container.read(gameProvider);
      swState = dayState.players.firstWhere((p) => p.id == sw.id);

      expect(swState.alliance, Team.clubStaff, reason: "Second Wind should be converted to Staff");
    });

    test('Mechanic: Clinger / Attack Dog (Partner Death Trigger)', () async {
      final container = ProviderContainer();
      final game = container.read(gameProvider.notifier);
      game.setGameStyle(GameStyle.manual);

      game.addPlayer('Clinger');
      game.addPlayer('Partner');
      game.addPlayer('Dealer');
      game.addPlayer('Bystander');

      final s1 = container.read(gameProvider);
      final clinger = s1.players[0];
      final partner = s1.players[1];
      final dealer = s1.players[2];

      game.assignRole(clinger.id, RoleIds.clinger);
      game.assignRole(partner.id, RoleIds.partyAnimal);
      game.assignRole(dealer.id, RoleIds.dealer);

      game.startGame();

      // Handle Clinger Setup (Night 0)
      while(container.read(gameProvider).phase == GamePhase.setup) {
        final step = container.read(gameProvider).currentStep;
        if (step != null && step.id.startsWith('clinger_setup_')) {
          game.handleInteraction(stepId: step.id, targetId: partner.id);
        }
        game.advancePhase();
      }

      // Night 1: Dealer kills Partner
      final dealerStep = 'dealer_act_${dealer.id}_1';
      game.handleInteraction(stepId: dealerStep, targetId: partner.id);

      // Resolve Night
      while(container.read(gameProvider).phase != GamePhase.day) {
        game.simulatePlayersForCurrentStep();
        game.advancePhase();
      }

      final dayState = container.read(gameProvider);
      final partnerState = dayState.players.firstWhere((p) => p.id == partner.id);
      final clingerState = dayState.players.firstWhere((p) => p.id == clinger.id);

      expect(partnerState.isAlive, isFalse, reason: "Partner should be dead");
      expect(clingerState.isAlive, isFalse, reason: "Clinger should die of broken heart");
      expect(clingerState.deathReason, 'clinger_bond');
    });
  });
    },
  );
}

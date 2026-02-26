import 'package:flutter_test/flutter_test.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';

void main() {
  // Helper to create a Role
  Role createRole(String id, {Team alliance = Team.partyAnimals}) {
    return Role(
      id: id,
      name: id.toUpperCase(),
      alliance: alliance,
      type: 'Test',
      description: 'Test role',
      nightPriority: 100,
      assetPath: '',
      colorHex: '#FF0000',
    );
  }

  // Helper to create a Player
  Player createPlayer(
    String id,
    Role role, {
    bool alive = true,
    int lives = 1,
    int? silencedDay,
  }) {
    return Player(
      id: id,
      name: id,
      role: role,
      alliance: role.alliance,
      isAlive: alive,
      lives: lives,
      silencedDay: silencedDay,
    );
  }

  // Helper to create a GameState
  GameState createGameState({
    required List<Player> players,
    int dayCount = 1,
    Map<String, int> dayVoteTally = const {},
    Map<String, String> dayVotesByVoter = const {},
  }) {
    return GameState(
      players: players,
      dayCount: dayCount,
      dayVoteTally: dayVoteTally,
      dayVotesByVoter: dayVotesByVoter,
    );
  }

  group('StrategyGenerator', () {
    test('generateTips returns correct base tip for known roles', () {
      final dealer = createRole('dealer', alliance: Team.clubStaff);
      final medic = createRole('medic', alliance: Team.partyAnimals);

      final dealerTips = StrategyGenerator.generateTips(role: dealer);
      final medicTips = StrategyGenerator.generateTips(role: medic);

      expect(dealerTips, contains(contains("Coordination is key")));
      expect(medicTips, contains(contains("Self-protect on Night 1")));
    });

    test('generateTips returns default base tip for unknown role', () {
      final unknown = createRole('unknown_role');
      final tips = StrategyGenerator.generateTips(role: unknown);

      expect(
        tips,
        contains("Survive the night and use your vote wisely during the day."),
      );
    });

    group('Club Staff Alerts', () {
      test('warns when Bouncer is ALIVE', () {
        final dealer = createRole('dealer', alliance: Team.clubStaff);
        final bouncer = createRole('bouncer', alliance: Team.partyAnimals);

        final players = [
          createPlayer('p1', dealer, alive: true),
          createPlayer('p2', bouncer, alive: true),
        ];

        final state = createGameState(players: players);
        final tips = StrategyGenerator.generateTips(role: dealer, state: state);

        expect(
          tips.any((t) => t.contains("Bouncer is currently ALIVE")),
          isTrue,
        );
      });

      test('warns when Medic is DEAD', () {
        final dealer = createRole('dealer', alliance: Team.clubStaff);
        final medic = createRole('medic', alliance: Team.partyAnimals);

        final players = [
          createPlayer('p1', dealer, alive: true),
          createPlayer('p2', medic, alive: false),
        ];

        final state = createGameState(players: players);
        final tips = StrategyGenerator.generateTips(role: dealer, state: state);

        expect(tips.any((t) => t.contains("Medic is DEAD")), isTrue);
      });

      test('shows both alerts if Bouncer alive AND Medic dead', () {
        final dealer = createRole('dealer', alliance: Team.clubStaff);
        final bouncer = createRole('bouncer', alliance: Team.partyAnimals);
        final medic = createRole('medic', alliance: Team.partyAnimals);

        final players = [
          createPlayer('p1', dealer, alive: true),
          createPlayer('p2', bouncer, alive: true),
          createPlayer('p3', medic, alive: false),
        ];

        final state = createGameState(players: players);
        final tips = StrategyGenerator.generateTips(role: dealer, state: state);

        expect(
          tips.any((t) => t.contains("Bouncer is currently ALIVE")),
          isTrue,
        );
        expect(tips.any((t) => t.contains("Medic is DEAD")), isTrue);
      });

      test('shows no alerts if Bouncer dead AND Medic alive', () {
        final dealer = createRole('dealer', alliance: Team.clubStaff);
        final bouncer = createRole('bouncer', alliance: Team.partyAnimals);
        final medic = createRole('medic', alliance: Team.partyAnimals);

        final players = [
          createPlayer('p1', dealer, alive: true),
          createPlayer('p2', bouncer, alive: false),
          createPlayer('p3', medic, alive: true),
        ];

        final state = createGameState(players: players);
        final tips = StrategyGenerator.generateTips(role: dealer, state: state);

        expect(
          tips.any((t) => t.contains("Bouncer is currently ALIVE")),
          isFalse,
        );
        expect(tips.any((t) => t.contains("Medic is DEAD")), isFalse);
      });
    });

    group('Party Animals Alerts', () {
      test('warns when multiple Dealers are active (> 2)', () {
        final dealerRole = createRole('dealer', alliance: Team.clubStaff);
        final medicRole = createRole('medic', alliance: Team.partyAnimals);

        final players = [
          createPlayer('d1', dealerRole, alive: true),
          createPlayer('d2', dealerRole, alive: true),
          createPlayer('d3', dealerRole, alive: true),
          createPlayer('m1', medicRole, alive: true),
        ];

        final state = createGameState(players: players);
        final tips = StrategyGenerator.generateTips(
          role: medicRole,
          state: state,
        );

        expect(
          tips.any((t) => t.contains("Multiple Dealers are active")),
          isTrue,
        );
      });

      test('does NOT warn when 2 or fewer Dealers are active', () {
        final dealerRole = createRole('dealer', alliance: Team.clubStaff);
        final medicRole = createRole('medic', alliance: Team.partyAnimals);

        final players = [
          createPlayer('d1', dealerRole, alive: true),
          createPlayer('d2', dealerRole, alive: true),
          createPlayer('m1', medicRole, alive: true),
        ];

        final state = createGameState(players: players);
        final tips = StrategyGenerator.generateTips(
          role: medicRole,
          state: state,
        );

        expect(
          tips.any((t) => t.contains("Multiple Dealers are active")),
          isFalse,
        );
      });
    });

    group('What If Scenarios', () {
      test('shows Minor safety tip when Bouncer is DEAD', () {
        final minor = createRole('minor', alliance: Team.partyAnimals);
        final bouncer = createRole('bouncer', alliance: Team.partyAnimals);

        final players = [
          createPlayer('p1', minor, alive: true),
          createPlayer('p2', bouncer, alive: false), // Bouncer dead
        ];

        final state = createGameState(players: players);
        final tips = StrategyGenerator.generateTips(role: minor, state: state);

        expect(tips.any((t) => t.contains("WHAT IF I'M ATTACKED?")), isTrue);
      });

      test('does NOT show Minor safety tip when Bouncer is ALIVE', () {
        final minor = createRole('minor', alliance: Team.partyAnimals);
        final bouncer = createRole('bouncer', alliance: Team.partyAnimals);

        final players = [
          createPlayer('p1', minor, alive: true),
          createPlayer('p2', bouncer, alive: true), // Bouncer alive
        ];

        final state = createGameState(players: players);
        final tips = StrategyGenerator.generateTips(role: minor, state: state);

        expect(tips.any((t) => t.contains("WHAT IF I'M ATTACKED?")), isFalse);
      });
    });

    group('Personal Status', () {
      test('shows lives status when player has > 1 lives', () {
        final role = createRole('seasoned_drinker');
        final player = createPlayer('p1', role, lives: 2);

        final tips = StrategyGenerator.generateTips(role: role, player: player);

        expect(
          tips.any((t) => t.contains("You have 2 lives remaining")),
          isTrue,
        );
      });

      test('does NOT show lives status when player has 1 life', () {
        final role = createRole('villager');
        final player = createPlayer('p1', role, lives: 1);

        final tips = StrategyGenerator.generateTips(role: role, player: player);

        expect(tips.any((t) => t.contains("lives remaining")), isFalse);
      });

      test('shows silenced status when player is silenced for current day', () {
        final role = createRole('villager');
        final player = createPlayer('p1', role, silencedDay: 2);

        // GameState day matches silencedDay
        final state = createGameState(players: [player], dayCount: 2);

        final tips = StrategyGenerator.generateTips(
          role: role,
          state: state,
          player: player,
        );

        expect(
          tips.any((t) => t.contains("You are currently SILENCED")),
          isTrue,
        );
      });

      test('does NOT show silenced status when silencedDay mismatches', () {
        final role = createRole('villager');
        // Player silenced for day 1, but it is day 2
        final player = createPlayer('p1', role, silencedDay: 1);

        final state = createGameState(players: [player], dayCount: 2);

        final tips = StrategyGenerator.generateTips(
          role: role,
          state: state,
          player: player,
        );

        expect(
          tips.any((t) => t.contains("You are currently SILENCED")),
          isFalse,
        );
      });
    });

    group('Null Inputs', () {
      test('handles null state and player gracefully', () {
        final role = createRole('villager');

        // Only role provided
        final tips = StrategyGenerator.generateTips(
          role: role,
          state: null,
          player: null,
        );

        // Should only contain base tip
        expect(tips.length, 1);
        expect(tips.first, contains("Survive the night"));
      });
    });

    group('Public Pattern Hints', () {
      test('adds stacked-vote and razor-thin tips when tally is close', () {
        final role = createRole('villager');
        final players = [
          createPlayer('p1', role),
          createPlayer('p2', role),
          createPlayer('p3', role),
          createPlayer('p4', role),
          createPlayer('p5', role),
        ];

        final state = createGameState(
          players: players,
          dayVoteTally: const {'p2': 3, 'p3': 2},
          dayVotesByVoter: const {'p1': 'p2', 'p2': 'p3', 'p3': 'p2'},
        );

        final tips = StrategyGenerator.generateTips(role: role, state: state);

        expect(
          tips.any((t) => t.contains('public votes are currently stacked')),
          isTrue,
        );
        expect(tips.any((t) => t.contains('vote is razor-thin')), isTrue);
      });

      test('adds low-turnout pattern when fewer than 60% have voted', () {
        final role = createRole('villager');
        final players = [
          createPlayer('p1', role),
          createPlayer('p2', role),
          createPlayer('p3', role),
          createPlayer('p4', role),
          createPlayer('p5', role),
        ];

        final state = createGameState(
          players: players,
          dayVotesByVoter: const {'p1': 'p2', 'p2': 'p1'},
        );

        final tips = StrategyGenerator.generateTips(role: role, state: state);

        expect(
          tips.any((t) => t.contains('Vote turnout is low (2/5)')),
          isTrue,
        );
      });

      test('adds heavy bar-tab pressure pattern from public player state', () {
        final role = createRole('villager');
        final players = [
          createPlayer('p1', role).copyWith(drinksOwed: 4),
          createPlayer('p2', role).copyWith(drinksOwed: 3),
          createPlayer('p3', role).copyWith(drinksOwed: 1),
          createPlayer('p4', role),
        ];

        final state = createGameState(players: players);
        final tips = StrategyGenerator.generateTips(role: role, state: state);

        expect(tips.any((t) => t.contains('carrying heavy bar tabs')), isTrue);
      });

      test('adds casualty-spike pattern when 2+ players died this day', () {
        final role = createRole('villager');
        final players = [
          createPlayer('p1', role),
          createPlayer('p2', role, alive: false).copyWith(deathDay: 3),
          createPlayer('p3', role, alive: false).copyWith(deathDay: 3),
          createPlayer('p4', role),
        ];

        final state = createGameState(players: players, dayCount: 3);
        final tips = StrategyGenerator.generateTips(role: role, state: state);

        expect(
          tips.any((t) => t.contains('Multiple casualties hit Day 3')),
          isTrue,
        );
      });
    });
  });
}

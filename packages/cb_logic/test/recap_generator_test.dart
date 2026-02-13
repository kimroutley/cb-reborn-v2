import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecapGenerator', () {
    test('generateRecap calculates awards correctly', () {
      final games = _generateTestGames();
      final session = _generateSession(games);

      final recap = RecapGenerator.generateRecap(session, games);

      expect(recap.totalGames, 2);
      expect(recap.uniquePlayers, 5);
      expect(recap.gameSummaries.length, 2);
    });

    test('generateRecap handles empty games list', () {
      final games = <GameRecord>[];
      final session = _generateSession(games);

      final recap = RecapGenerator.generateRecap(session, games);

      expect(recap.totalGames, 0);
      expect(recap.mvp, isNull);
      expect(recap.mainCharacter, isNull);
      expect(recap.ghost, isNull);
      expect(recap.dealerOfDeath, isNull);
      expect(recap.spiciestMoment, isNull);
      expect(recap.gameSummaries, isEmpty);
    });

    test('Main Character award finds most targeted player', () {
      final games = _generateTestGames();
      final session = _generateSession(games);

      // In game-0: Bob is targeted 2 times (votes from Alice and Charlie).
      // In game-1: Alice is targeted 1 time (vote from Bob).
      // Bob should be Main Character with 2 targets.

      final recap = RecapGenerator.generateRecap(session, games);

      expect(recap.mainCharacter?.playerName, 'Bob');
      expect(recap.mainCharacter?.value, 2);
    });

    test('Dealer of Death finds most successful dealer', () {
      final games = _generateTestGames();
      final session = _generateSession(games);

      // In game-0: Dealer Eve killed Charlie.

      final recap = RecapGenerator.generateRecap(session, games);

      expect(recap.dealerOfDeath?.playerName, 'Eve');
      expect(recap.dealerOfDeath?.value, 1);
    });

    test('Ghost finds player who survived longest on average', () {
      final games = _generateTestGames();
      final session = _generateSession(games);

      // Game 0 (3 days):
      // Alice, Bob, Eve survived (3 days)
      // Charlie died day 2, David died day 1.

      // Game 1 (3 days):
      // Alice, Bob, Charlie, David survived (3 days)
      // Eve died/absent (1 day implicit).

      final recap = RecapGenerator.generateRecap(session, games);

      // Alice (avg 3.0) or Bob (avg 3.0) should be Ghost.
      expect(recap.ghost?.value, 3);
      expect(recap.ghost?.playerName, anyOf('Alice', 'Bob'));
    });

    test('Spiciest Moment selection - explicit spicy event', () {
      final game = _createGame(
        id: 'g1',
        history: ['Player A voted for B', 'Something SPICY happen!'],
        dayCount: 5,
      );
      final games = [game];
      final session = _generateSession(games);

      final recap = RecapGenerator.generateRecap(session, games);

      expect(recap.spiciestMoment, contains('SPICY'));
    });

    test('Spiciest Moment selection - fallback to shortest game', () {
      final g1 = _createGame(id: 'g1', dayCount: 5, history: ['Vote A']);
      final g2 = _createGame(id: 'g2', dayCount: 2, history: ['Vote B']);
      final games = [g1, g2];
      final session = _generateSession(games);

      final recap = RecapGenerator.generateRecap(session, games);

      expect(recap.spiciestMoment, 'Game ended in just 2 days!');
    });

    test('MVP logic - rewards consistency and participation', () {
      final g1 = _createGame(
        id: 'g1',
        winner: Team.clubStaff,
        roster: [
          _player('A', Team.clubStaff, true),
          _player('B', Team.clubStaff, true),
          _player('C', Team.clubStaff, true),
        ]
      );

      final g2 = _createGame(
        id: 'g2',
        winner: Team.partyAnimals,
        roster: [
          _player('B', Team.partyAnimals, true), // Win
          _player('C', Team.partyAnimals, true), // Win
        ]
      );

      final g3 = _createGame(
        id: 'g3',
        winner: Team.partyAnimals,
        roster: [
          _player('B', Team.clubStaff, false), // Loss
          _player('C', Team.partyAnimals, true), // Win
        ]
      );

      final games = [g1, g2, g3];

      // Session needs to reflect correct games count
      final session = GamesNightRecord(
        id: 's1',
        sessionName: 'Test',
        startedAt: DateTime.now(),
        gameIds: ['g1', 'g2', 'g3'],
        playerNames: ['A', 'B', 'C'],
        playerGamesCount: {
          'A': 1,
          'B': 3,
          'C': 3,
        }
      );

      final recap = RecapGenerator.generateRecap(session, games);

      // C should be MVP (100% win rate over 3 games)
      expect(recap.mvp?.playerName, 'C');
      expect(recap.mvp?.value, 100); // 100%

      // Test A vs B (comparing 1 game vs 3 games with lower win rate)
      final sessionAB = GamesNightRecord(
        id: 's2',
        sessionName: 'AB',
        startedAt: DateTime.now(),
        gameIds: ['g1', 'g2', 'g3'],
        playerNames: ['A', 'B'],
        playerGamesCount: {'A': 1, 'B': 3}
      );

      final recapAB = RecapGenerator.generateRecap(sessionAB, games);

      // B has higher score due to participation weight despite lower win rate
      expect(recapAB.mvp?.playerName, 'B');
    });

    test('Main Character - handles regex variations', () {
      final g1 = _createGame(
        id: 'g1',
        history: [
          'Vote for Alice.', // Matches "Vote for" (capitalized) + punctuation
          'Bob voted for Alice', // Matches "voted for" + end of string (no punctuation)
          'Charlie voted for Alice.', // Matches "voted for" + punctuation
          'Dealer David killed Alice', // Should NOT match (regex expects "was killed" or "died")
          'Alice died mysteriously', // Matches "Alice died"
        ]
      );

      final games = [g1];
      final session = _generateSession(games);

      final recap = RecapGenerator.generateRecap(session, games);

      // Expected matches:
      // 1. "Vote for Alice."
      // 2. "Bob voted for Alice"
      // 3. "Charlie voted for Alice."
      // 4. "Alice died mysteriously"
      // Total: 4

      expect(recap.mainCharacter?.playerName, 'Alice');
      expect(recap.mainCharacter?.value, 4);
    });
  });
}

// ────────────────────── Helpers ──────────────────────

GamesNightRecord _generateSession(List<GameRecord> games) {
  final playerNames = <String>{};
  final playerGames = <String, int>{};

  for (final game in games) {
    for (final p in game.roster) {
      playerNames.add(p.name);
      playerGames[p.name] = (playerGames[p.name] ?? 0) + 1;
    }
  }

  return GamesNightRecord(
    id: 'session-1',
    sessionName: 'Test Session',
    startedAt: DateTime.now().subtract(const Duration(hours: 2)),
    endedAt: DateTime.now(),
    gameIds: games.map((g) => g.id).toList(),
    playerNames: playerNames.toList(),
    playerGamesCount: playerGames,
  );
}

GameRecord _createGame({
  required String id,
  Team winner = Team.clubStaff,
  int dayCount = 3,
  List<String> history = const [],
  List<PlayerSnapshot>? roster,
}) {
  return GameRecord(
    id: id,
    startedAt: DateTime.now(),
    endedAt: DateTime.now().add(const Duration(minutes: 15)),
    winner: winner,
    playerCount: roster?.length ?? 5,
    dayCount: dayCount,
    roster: roster ?? _defaultRoster(),
    history: history,
  );
}

List<PlayerSnapshot> _defaultRoster() {
  return [
    _player('Alice', Team.clubStaff, true),
    _player('Bob', Team.partyAnimals, true),
    _player('Charlie', Team.partyAnimals, false),
    _player('David', Team.partyAnimals, false),
    _player('Eve', Team.clubStaff, true),
  ];
}

PlayerSnapshot _player(String name, Team alliance, bool alive) {
  return PlayerSnapshot(
    id: name.toLowerCase(),
    name: name,
    roleId: 'villager',
    alliance: alliance,
    alive: alive,
  );
}

List<GameRecord> _generateTestGames() {
  // Game 0: Club Staff wins, 3 days
  final game0 = GameRecord(
    id: 'game-0',
    startedAt: DateTime.now(),
    endedAt: DateTime.now().add(const Duration(minutes: 15)),
    winner: Team.clubStaff,
    playerCount: 5,
    dayCount: 3,
    roster: [
      _player('Alice', Team.clubStaff, true),
      _player('Bob', Team.partyAnimals, true),
      _player('Charlie', Team.partyAnimals, false), // Dead
      _player('David', Team.partyAnimals, false), // Dead
      _player('Eve', Team.clubStaff, true), // Dealer
    ],
    history: [
      '─── DAY 1 ───',
      'David died mysteriously.',
      '─── DAY 2 ───',
      'Alice voted for Bob.',
      'Charlie voted for Bob.',
      'Dealer Eve killed Charlie',
      '─── DAY 3 ───',
    ],
  );

  // Game 1: Party Animals wins, 3 days
  final game1 = GameRecord(
    id: 'game-1',
    startedAt: DateTime.now(),
    endedAt: DateTime.now().add(const Duration(minutes: 15)),
    winner: Team.partyAnimals,
    playerCount: 5,
    dayCount: 3,
    roster: [
      _player('Alice', Team.partyAnimals, true),
      _player('Bob', Team.partyAnimals, true),
      _player('Charlie', Team.partyAnimals, true),
      _player('David', Team.partyAnimals, true),
      _player('Eve', Team.clubStaff, false),
    ],
    history: [
      '─── DAY 1 ───',
      'Bob voted for Alice.',
      '─── DAY 2 ───',
      '─── DAY 3 ───',
    ],
  );

  return [game0, game1];
}

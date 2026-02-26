import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecapGenerator with Structured Events', () {
    test('Main Character award finds most targeted player using events', () {
      final games = _generateEventBasedGames();
      final session = _generateSession(games);

      // In game-0: Bob is targeted 2 times (vote + death).
      // In game-1: Alice is targeted 1 time (vote).
      // Bob should be Main Character with 2 targets.

      final recap = RecapGenerator.generateRecap(session, games);

      expect(recap.mainCharacter?.playerName, 'Bob');
      expect(recap.mainCharacter?.value, 2);
    });

    test('Dealer of Death finds most successful dealer using events', () {
      final games = _generateEventBasedGames();
      final session = _generateSession(games);

      // In game-0: Eve kills Charlie.

      final recap = RecapGenerator.generateRecap(session, games);

      expect(recap.dealerOfDeath?.playerName, 'Eve');
      expect(recap.dealerOfDeath?.value, 1);
    });

    test('Ghost finds player who survived longest on average using events', () {
      final games = _generateEventBasedGames();
      final session = _generateSession(games);

      // Game 0 (3 days):
      // Alice, Bob, Eve survived (3 days)
      // Charlie died day 2, David died day 1.

      // Game 1 (3 days):
      // Alice, Bob, Charlie, David survived (3 days)
      // Eve died day 1.

      final recap = RecapGenerator.generateRecap(session, games);

      // Alice or Bob survived 3 days in both games. Avg = 3.0.
      expect(recap.ghost?.value, 3);
      expect(recap.ghost?.playerName, anyOf('Alice', 'Bob'));
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

GameRecordPlayerSnapshot _player(String name, Team alliance, bool alive) {
  return GameRecordPlayerSnapshot(
    id: name.toLowerCase(),
    name: name,
    roleId: 'villager',
    alliance: alliance,
    alive: alive,
  );
}

List<GameRecord> _generateEventBasedGames() {
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
      _player('Charlie', Team.partyAnimals, false), // Dead day 2
      _player('David', Team.partyAnimals, false), // Dead day 1
      _player('Eve', Team.clubStaff, true), // Dealer
    ],
    history: [], // Empty history to force event usage
    eventLog: [
      GameEvent.death(playerId: 'david', reason: 'murder', day: 1),
      GameEvent.vote(voterId: 'alice', targetId: 'bob', day: 2),
      GameEvent.vote(
        voterId: 'charlie',
        targetId: 'bob',
        day: 2,
      ), // Added 2nd vote
      GameEvent.kill(killerId: 'eve', victimId: 'charlie', day: 2),
      GameEvent.death(playerId: 'charlie', reason: 'murder', day: 2),
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
      _player('Eve', Team.clubStaff, false), // Dead day 1
    ],
    history: [], // Empty history
    eventLog: [
      GameEvent.vote(voterId: 'bob', targetId: 'alice', day: 1),
      GameEvent.death(playerId: 'eve', reason: 'exile', day: 1),
    ],
  );

  return [game0, game1];
}

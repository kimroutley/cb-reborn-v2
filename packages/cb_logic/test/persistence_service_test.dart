import 'dart:convert';
import 'dart:io';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

/// Helper to build a minimal GameState for persistence testing.
GameState _fakeGameState({
  GamePhase phase = GamePhase.night,
  int dayCount = 1,
}) {
  return GameState(
    phase: phase,
    dayCount: dayCount,
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
      Player(
        id: 'bob',
        name: 'Bob',
        role: const Role(
          id: 'party_animal',
          name: 'Party Animal',
          alliance: Team.partyAnimals,
          type: 'Civilian',
          description: 'test',
          nightPriority: 100,
          assetPath: '',
          colorHex: '#00FF00',
        ),
        alliance: Team.partyAnimals,
      ),
    ],
    gameHistory: ['── NIGHT 0 ──', 'Alice used dealer on Bob.'],
  );
}

SessionState _fakeSession() {
  return const SessionState(joinCode: 'NEON-TEST', claimedPlayerIds: ['alice']);
}

GameRecord _fakeRecord({
  String id = 'game-1',
  Team winner = Team.partyAnimals,
  int playerCount = 6,
  int dayCount = 3,
}) {
  return GameRecord(
    id: id,
    startedAt: DateTime(2025, 1, 1, 20, 0),
    endedAt: DateTime(2025, 1, 1, 21, 30),
    winner: winner,
    playerCount: playerCount,
    dayCount: dayCount,
    rolesInPlay: ['dealer', 'bouncer', 'party_animal', 'medic'],
    roster: [
      const GameRecordPlayerSnapshot(
        id: 'p1',
        name: 'Alice',
        roleId: 'dealer',
        alliance: Team.clubStaff,
        alive: true,
      ),
      const GameRecordPlayerSnapshot(
        id: 'p2',
        name: 'Bob',
        roleId: 'party_animal',
        alliance: Team.partyAnimals,
        alive: true,
      ),
      const GameRecordPlayerSnapshot(
        id: 'p3',
        name: 'Charlie',
        roleId: 'medic',
        alliance: Team.partyAnimals,
        alive: false,
      ),
    ],
    history: ['Night 0: Dealer killed Bob'],
  );
}

void main() {
  late Directory tempDir;
  late PersistenceService service;
  late Box<String> activeBox;
  late Box<String> recordsBox;
  late Box<String> sessionsBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    activeBox = await Hive.openBox<String>('test_active');
    recordsBox = await Hive.openBox<String>('test_records');
    sessionsBox = await Hive.openBox<String>('test_sessions');
    service = PersistenceService.initWithBoxes(
      activeBox,
      recordsBox,
      sessionsBox,
    );
  });

  tearDown(() async {
    await service.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ═══════════════════════════════════════════════
  //  Active Game (Crash Recovery)
  // ═══════════════════════════════════════════════

  group('Active Game', () {
    test('listSaveSlots returns default slot set', () {
      expect(service.listSaveSlots(), ['slot_1', 'slot_2', 'slot_3']);
    });

    test('hasActiveGame is false initially', () {
      expect(service.hasActiveGame, false);
    });

    test('saveGameSlot + loadGameSlot roundtrips non-default slot', () async {
      await service.saveGameSlot('slot_2', _fakeGameState(), _fakeSession());

      final slot2 = service.loadGameSlot('slot_2');
      expect(slot2, isNotNull);
      expect(slot2!.$1.players.first.name, 'Alice');
      expect(slot2.$2.joinCode, 'NEON-TEST');

      // Default slot remains empty.
      expect(service.loadActiveGame(), isNull);
    });

    test('clearGameSlot removes only selected slot', () async {
      await service.saveGameSlot(
          'slot_1', _fakeGameState(dayCount: 1), _fakeSession());
      await service.saveGameSlot(
          'slot_2', _fakeGameState(dayCount: 5), _fakeSession());

      await service.clearGameSlot('slot_2');

      expect(service.loadGameSlot('slot_2'), isNull);
      expect(service.loadGameSlot('slot_1'), isNotNull);
      expect(service.loadGameSlot('slot_1')!.$1.dayCount, 1);
    });

    test('saveActiveGame + loadActiveGame roundtrips', () async {
      final game = _fakeGameState();
      final session = _fakeSession();

      await service.saveActiveGame(game, session);

      expect(service.hasActiveGame, true);

      final result = service.loadActiveGame();
      expect(result, isNotNull);
      final (loadedGame, loadedSession) = result!;

      expect(loadedGame.phase, GamePhase.night);
      expect(loadedGame.dayCount, 1);
      expect(loadedGame.players.length, 2);
      expect(loadedGame.players[0].id, 'alice');
      expect(loadedGame.players[0].name, 'Alice');
      expect(loadedGame.players[0].role.id, 'dealer');
      expect(loadedGame.players[1].id, 'bob');
      expect(loadedGame.gameHistory.length, 2);

      expect(loadedSession.joinCode, 'NEON-TEST');
      expect(loadedSession.claimedPlayerIds, ['alice']);
    });

    test('clearActiveGame removes saved data', () async {
      await service.saveActiveGame(_fakeGameState(), _fakeSession());
      expect(service.hasActiveGame, true);

      await service.clearActiveGame();

      expect(service.hasActiveGame, false);
      expect(service.loadActiveGame(), isNull);
    });

    test('loadActiveGame returns null when nothing saved', () {
      expect(service.loadActiveGame(), isNull);
    });

    test('overwriting active game replaces previous', () async {
      await service.saveActiveGame(_fakeGameState(dayCount: 1), _fakeSession());

      await service.saveActiveGame(
        _fakeGameState(dayCount: 5, phase: GamePhase.day),
        const SessionState(joinCode: 'NEON-NEW', claimedPlayerIds: ['bob']),
      );

      final result = service.loadActiveGame()!;
      expect(result.$1.dayCount, 5);
      expect(result.$1.phase, GamePhase.day);
      expect(result.$2.joinCode, 'NEON-NEW');
    });

    test('loadActiveGameDetailed reports partial snapshot', () async {
      await activeBox.put(
        'game_state',
        jsonEncode(_fakeGameState().toJson()),
      );

      final result = service.loadActiveGameDetailed();
      expect(result.data, isNull);
      expect(result.failure, ActiveGameLoadFailure.partialSnapshot);
      expect(result.hasAnyData, true);

      expect(service.loadActiveGame(), isNull);
      expect(service.hasActiveGame, false);

      await service.clearActiveGame();
      expect(service.loadActiveGameDetailed().hasAnyData, false);
    });

    test('loadActiveGameDetailed reports corrupted snapshot', () async {
      await activeBox.put('game_state', '{not-json');
      await activeBox.put('session_state', '{not-json');

      final result = service.loadActiveGameDetailed();
      expect(result.data, isNull);
      expect(result.failure, ActiveGameLoadFailure.corruptedSnapshot);
      expect(result.hasAnyData, true);

      expect(service.loadActiveGame(), isNull);
      expect(service.hasActiveGame, true);

      await service.clearActiveGame();
      expect(service.hasActiveGame, false);
      expect(service.loadActiveGameDetailed().hasAnyData, false);
    });

    test('loadGameSlotDetailed reports partial snapshot for that slot only',
        () async {
      await activeBox.put(
        'game_state::slot_3',
        jsonEncode(_fakeGameState().toJson()),
      );

      final slot3 = service.loadGameSlotDetailed('slot_3');
      expect(slot3.data, isNull);
      expect(slot3.failure, ActiveGameLoadFailure.partialSnapshot);
      expect(slot3.hasAnyData, true);

      final slot1 = service.loadGameSlotDetailed('slot_1');
      expect(slot1.hasAnyData, false);
      expect(slot1.failure, isNull);
    });
  });

  // ═══════════════════════════════════════════════
  //  Game Records (History)
  // ═══════════════════════════════════════════════

  group('Game Records', () {
    test('initially empty', () {
      expect(service.loadGameRecords(), isEmpty);
    });

    test('saveGameRecord + loadGameRecords roundtrips', () async {
      final record = _fakeRecord();
      await service.saveGameRecord(record);

      final records = service.loadGameRecords();
      expect(records.length, 1);
      expect(records.first.id, 'game-1');
      expect(records.first.winner, Team.partyAnimals);
      expect(records.first.playerCount, 6);
      expect(records.first.dayCount, 3);
      expect(records.first.rolesInPlay, contains('dealer'));
      expect(records.first.roster.length, 3);
      expect(records.first.history.length, 1);
    });

    test('records sorted newest first', () async {
      await service.saveGameRecord(_fakeRecord(id: 'old'));
      await service.saveGameRecord(
        GameRecord(
          id: 'new',
          startedAt: DateTime(2025, 2, 1),
          endedAt: DateTime(2025, 2, 1, 1, 0),
          winner: Team.clubStaff,
          playerCount: 8,
          dayCount: 2,
        ),
      );

      final records = service.loadGameRecords();
      expect(records.first.id, 'new');
      expect(records.last.id, 'old');
    });

    test('deleteGameRecord removes specific record', () async {
      await service.saveGameRecord(_fakeRecord(id: 'keep'));
      await service.saveGameRecord(_fakeRecord(id: 'remove'));

      await service.deleteGameRecord('remove');

      final records = service.loadGameRecords();
      expect(records.length, 1);
      expect(records.first.id, 'keep');
    });

    test('clearGameRecords removes all', () async {
      await service.saveGameRecord(_fakeRecord(id: 'a'));
      await service.saveGameRecord(_fakeRecord(id: 'b'));
      await service.saveGameRecord(_fakeRecord(id: 'c'));

      await service.clearGameRecords();

      expect(service.loadGameRecords(), isEmpty);
    });

    test('PlayerSnapshot preserves alive field', () async {
      await service.saveGameRecord(_fakeRecord());
      final roster = service.loadGameRecords().first.roster;
      expect(roster[0].alive, true); // Alice
      expect(roster[2].alive, false); // Charlie
    });
  });

  // ═══════════════════════════════════════════════
  //  Aggregate Stats
  // ═══════════════════════════════════════════════

  group('computeStats', () {
    test('returns empty stats when no records', () {
      final stats = service.computeStats();
      expect(stats.totalGames, 0);
      expect(stats.clubStaffWins, 0);
      expect(stats.partyAnimalsWins, 0);
      expect(stats.averagePlayerCount, 0);
      expect(stats.averageDayCount, 0);
      expect(stats.roleFrequency, isEmpty);
      expect(stats.roleWinCount, isEmpty);
    });

    test('computes correct win counts', () async {
      await service.saveGameRecord(
        _fakeRecord(id: '1', winner: Team.partyAnimals),
      );
      await service.saveGameRecord(
        _fakeRecord(id: '2', winner: Team.clubStaff),
      );
      await service.saveGameRecord(
        _fakeRecord(id: '3', winner: Team.partyAnimals),
      );

      final stats = service.computeStats();
      expect(stats.totalGames, 3);
      expect(stats.partyAnimalsWins, 2);
      expect(stats.clubStaffWins, 1);
    });

    test('does not count neutral wins as partyAnimals wins', () async {
      await service.saveGameRecord(
        _fakeRecord(id: 'n1', winner: Team.neutral),
      );

      final stats = service.computeStats();
      expect(stats.totalGames, 1);
      expect(stats.clubStaffWins, 0);
      expect(stats.partyAnimalsWins, 0);
    });

    test('computes correct averages', () async {
      await service.saveGameRecord(
        _fakeRecord(id: '1', playerCount: 6, dayCount: 2),
      );
      await service.saveGameRecord(
        _fakeRecord(id: '2', playerCount: 10, dayCount: 4),
      );

      final stats = service.computeStats();
      expect(stats.averagePlayerCount, 8); // (6+10)/2 = 8
      expect(stats.averageDayCount, 3); // (2+4)/2 = 3
    });

    test('tracks role frequency across games', () async {
      await service.saveGameRecord(_fakeRecord(id: '1'));
      await service.saveGameRecord(_fakeRecord(id: '2'));

      final stats = service.computeStats();
      // 'dealer' appears in both games
      expect(stats.roleFrequency['dealer'], 2);
      expect(stats.roleFrequency['party_animal'], 2);
    });

    test('tracks role wins correctly', () async {
      // Game 1: PA wins, dealer (staff) loses, party_animal (PA) wins
      await service.saveGameRecord(
        _fakeRecord(id: '1', winner: Team.partyAnimals),
      );
      // Game 2: Staff wins, dealer (staff) wins, party_animal (PA) loses
      await service.saveGameRecord(
        _fakeRecord(id: '2', winner: Team.clubStaff),
      );

      final stats = service.computeStats();
      // dealer is staff -> wins in game 2
      expect(stats.roleWinCount['dealer'], 1);
      // party_animal is PA -> wins in game 1
      expect(stats.roleWinCount['party_animal'], 1);
    });
  });

  // ═══════════════════════════════════════════════
  //  Role Award Progress
  // ═══════════════════════════════════════════════

  group('Role Award Progress', () {
    test('rebuildRoleAwardProgresses creates deterministic progress rows',
        () async {
      await service.saveGameRecord(_fakeRecord());

      final rebuilt = await service.roleAwards.rebuildRoleAwardProgresses();
      expect(rebuilt, isNotEmpty);

      final byPlayer = service.roleAwards.loadRoleAwardProgressesByPlayer('p1');
      expect(byPlayer.length, roleAwardsForRoleId(RoleIds.dealer).length);

      final rookie = byPlayer.firstWhere(
        (row) =>
            roleAwardDefinitionById(row.awardId)?.tier == RoleAwardTier.rookie,
      );
      expect(rookie.progressValue, 1);
      expect(rookie.isUnlocked, true);
    });

    test('query helpers filter by role, tier, and recent unlocks', () async {
      await service.saveGameRecord(_fakeRecord(id: 'g1'));
      await service.saveGameRecord(
        _fakeRecord(id: 'g2', winner: Team.clubStaff),
      );

      await service.roleAwards.rebuildRoleAwardProgresses();

      final dealerProgress =
          service.roleAwards.loadRoleAwardProgressesByRole(RoleIds.dealer);
      expect(dealerProgress, isNotEmpty);

      final rookieProgress =
          service.roleAwards.loadRoleAwardProgressesByTier(RoleAwardTier.rookie);
      expect(rookieProgress, isNotEmpty);

      final recent = service.roleAwards.loadRecentRoleAwardUnlocks(limit: 5);
      expect(recent.length, lessThanOrEqualTo(5));
      expect(recent.every((row) => row.isUnlocked), true);
    });

    test('survivals metric unlocks survival-based bonus awards', () async {
      await service.saveGameRecord(_fakeRecord(id: 's1'));
      await service.saveGameRecord(_fakeRecord(id: 's2'));
      await service.saveGameRecord(_fakeRecord(id: 's3'));

      await service.roleAwards.rebuildRoleAwardProgresses();

      final aliceRows = service.roleAwards.loadRoleAwardProgressesByPlayer('p1');
      final survivalBonus = aliceRows.firstWhere(
        (row) {
          final definition = roleAwardDefinitionById(row.awardId);
          return definition?.tier == RoleAwardTier.bonus &&
              definition?.unlockRule['metric'] == 'survivals';
        },
      );

      expect(survivalBonus.progressValue, 3);
      expect(survivalBonus.isUnlocked, true);
    });

    test('clearRoleAwardProgresses removes award rows only', () async {
      await service.saveGameRecord(_fakeRecord(id: 'g1'));
      await service.roleAwards.rebuildRoleAwardProgresses();

      expect(service.roleAwards.loadRoleAwardProgresses(), isNotEmpty);

      await service.roleAwards.clearRoleAwardProgresses();

      expect(service.roleAwards.loadRoleAwardProgresses(), isEmpty);
      expect(service.loadGameRecords(), isNotEmpty);
    });
  });

  // ═══════════════════════════════════════════════
  //  Freezed Model Serialization
  // ═══════════════════════════════════════════════

  group('GameRecord JSON', () {
    test('roundtrip through toJson / fromJson', () {
      final record = _fakeRecord();
      // Use jsonEncode/jsonDecode for proper deep serialization
      final json =
          jsonDecode(jsonEncode(record.toJson())) as Map<String, dynamic>;
      final restored = GameRecord.fromJson(json);

      expect(restored.id, record.id);
      expect(restored.winner, record.winner);
      expect(restored.playerCount, record.playerCount);
      expect(restored.roster.length, record.roster.length);
      expect(restored.roster.first.name, 'Alice');
    });
  });

  group('GameStats JSON', () {
    test('roundtrip through toJson / fromJson', () {
      const stats = GameStats(
        totalGames: 5,
        clubStaffWins: 2,
        partyAnimalsWins: 3,
        averagePlayerCount: 7,
        averageDayCount: 3,
        roleFrequency: {'dealer': 5, 'medic': 3},
        roleWinCount: {'dealer': 2, 'medic': 2},
      );
      final json = stats.toJson();
      final restored = GameStats.fromJson(json);

      expect(restored.totalGames, 5);
      expect(restored.clubStaffWins, 2);
      expect(restored.roleFrequency['dealer'], 5);
      expect(restored.roleWinCount['medic'], 2);
    });

    test('defaults produce valid JSON', () {
      const stats = GameStats();
      final json = stats.toJson();
      final restored = GameStats.fromJson(json);
      expect(restored.totalGames, 0);
      expect(restored.roleFrequency, isEmpty);
    });
  });
}

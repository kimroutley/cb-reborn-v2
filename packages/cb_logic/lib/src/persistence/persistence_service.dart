import 'dart:convert';
import 'dart:isolate';

import 'package:cb_models/cb_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';

/// Keys used for Hive boxes.
const _activeGameBox = 'active_game';
const _gameRecordsBox = 'game_records';
const _sessionsBoxKey = 'games_night_sessions';
const _activeGameKey = 'game_state';
const _activeSessionKey = 'session_state';
const _activeSavedAtKey = 'saved_at';
const _encryptionKeyStorageKey = 'hive_encryption_key';
const _awardProgressKeyPrefix = 'role_award_progress::';
const defaultSaveSlotId = 'slot_1';
const manualSaveSlotCount = 3;

/// Failure reasons when reading an active (recovery) snapshot.
///
/// Note: Encryption/key errors generally occur during [PersistenceService.init]
/// (when opening encrypted boxes), not during reads.
enum ActiveGameLoadFailure {
  /// One of the required keys exists, but the other is missing.
  partialSnapshot,

  /// JSON exists but could not be decoded into models.
  corruptedSnapshot,
}

/// Detailed outcome for loading an active (recovery) snapshot.
class ActiveGameLoadResult {
  final (GameState, SessionState)? data;
  final ActiveGameLoadFailure? failure;
  final bool hasAnyData;

  const ActiveGameLoadResult._({
    required this.data,
    required this.failure,
    required this.hasAnyData,
  });

  factory ActiveGameLoadResult.none() {
    return const ActiveGameLoadResult._(
      data: null,
      failure: null,
      hasAnyData: false,
    );
  }

  factory ActiveGameLoadResult.success((GameState, SessionState) data) {
    return ActiveGameLoadResult._(data: data, failure: null, hasAnyData: true);
  }

  factory ActiveGameLoadResult.failure(
    ActiveGameLoadFailure failure, {
    required bool hasAnyData,
  }) {
    return ActiveGameLoadResult._(
      data: null,
      failure: failure,
      hasAnyData: hasAnyData,
    );
  }

  bool get isSuccess => data != null;
}

/// Persistence service backed by Hive CE.
///
/// Provides:
/// - Active game save / restore (crash recovery)
/// - Completed game records (history database)
/// - Aggregate stats computed from records
class PersistenceService {
  PersistenceService._();

  static PersistenceService? _instance;

  /// Singleton accessor. Call [init] before using.
  static PersistenceService get instance {
    assert(_instance != null, 'Call PersistenceService.init() first');
    return _instance!;
  }

  late Box<String> _activeBox;
  late Box<String> _recordsBox;
  late Box<String> _sessionsBox;

  /// Initialise Hive and open boxes. Call once at app startup.
  static Future<PersistenceService> init() async {
    if (_instance != null) return _instance!;
    final service = PersistenceService._();

    const secureStorage = FlutterSecureStorage();
    List<int> encryptionKey;

    // Check if an encryption key exists
    String? keyString = await secureStorage.read(key: _encryptionKeyStorageKey);

    if (keyString == null) {
      // No key found. Check for legacy unencrypted data to migrate.
      final hasLegacyData =
          await Hive.boxExists(_activeGameBox) ||
          await Hive.boxExists(_gameRecordsBox) ||
          await Hive.boxExists(_sessionsBoxKey);

      if (hasLegacyData) {
        // Migration: Unencrypted -> Encrypted
        await _migrateLegacyData(secureStorage);
        // Key should now exist
        keyString = await secureStorage.read(key: _encryptionKeyStorageKey);
        if (keyString == null) {
          throw Exception('Migration failed: Encryption key not saved.');
        }
        encryptionKey = base64Url.decode(keyString);
      } else {
        // Fresh install: Generate and save new key
        encryptionKey = Hive.generateSecureKey();
        await secureStorage.write(
          key: _encryptionKeyStorageKey,
          value: base64Url.encode(encryptionKey),
        );
      }
    } else {
      encryptionKey = base64Url.decode(keyString);
    }

    final cipher = HiveAesCipher(encryptionKey);
    service._activeBox = await Hive.openBox<String>(
      _activeGameBox,
      encryptionCipher: cipher,
    );
    service._recordsBox = await Hive.openBox<String>(
      _gameRecordsBox,
      encryptionCipher: cipher,
    );
    service._sessionsBox = await Hive.openBox<String>(
      _sessionsBoxKey,
      encryptionCipher: cipher,
    );

    _instance = service;
    return service;
  }

  /// Migrates data from unencrypted boxes to encrypted boxes.
  static Future<void> _migrateLegacyData(
    FlutterSecureStorage secureStorage,
  ) async {
    // 1. Open existing unencrypted boxes
    final activeBox = await Hive.openBox<String>(_activeGameBox);
    final recordsBox = await Hive.openBox<String>(_gameRecordsBox);
    final sessionsBox = await Hive.openBox<String>(_sessionsBoxKey);

    // 2. Read all data into memory
    final activeData = Map<dynamic, String>.from(activeBox.toMap());
    final recordsData = Map<dynamic, String>.from(recordsBox.toMap());
    final sessionsData = Map<dynamic, String>.from(sessionsBox.toMap());

    // 3. Close and delete unencrypted boxes
    await activeBox.close();
    await recordsBox.close();
    await sessionsBox.close();

    await Hive.deleteBoxFromDisk(_activeGameBox);
    await Hive.deleteBoxFromDisk(_gameRecordsBox);
    await Hive.deleteBoxFromDisk(_sessionsBoxKey);

    // 4. Generate and save new encryption key
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: _encryptionKeyStorageKey,
      value: base64Url.encode(key),
    );

    // 5. Open new boxes with encryption
    final cipher = HiveAesCipher(key);
    final newActiveBox = await Hive.openBox<String>(
      _activeGameBox,
      encryptionCipher: cipher,
    );
    final newRecordsBox = await Hive.openBox<String>(
      _gameRecordsBox,
      encryptionCipher: cipher,
    );
    final newSessionsBox = await Hive.openBox<String>(
      _sessionsBoxKey,
      encryptionCipher: cipher,
    );

    // 6. Restore data
    await newActiveBox.putAll(activeData);
    await newRecordsBox.putAll(recordsData);
    await newSessionsBox.putAll(sessionsData);

    // 7. Close boxes (they will be re-opened by init)
    await newActiveBox.close();
    await newRecordsBox.close();
    await newSessionsBox.close();
  }

  /// Create an instance backed by the given boxes (for testing).
  static PersistenceService initWithBoxes(
    Box<String> activeBox,
    Box<String> recordsBox,
    Box<String> sessionsBox,
  ) {
    final service = PersistenceService._();
    service._activeBox = activeBox;
    service._recordsBox = recordsBox;
    service._sessionsBox = sessionsBox;
    _instance = service;
    return service;
  }

  // ────────────────────── Active Game ──────────────────────
  String _normalizeSlotId(String slotId) {
    final normalized = slotId.trim().toLowerCase();
    return normalized.isEmpty ? defaultSaveSlotId : normalized;
  }

  String _gameKeyForSlot(String slotId) {
    final normalized = _normalizeSlotId(slotId);
    if (normalized == defaultSaveSlotId) {
      return _activeGameKey;
    }
    return '$_activeGameKey::$normalized';
  }

  String _sessionKeyForSlot(String slotId) {
    final normalized = _normalizeSlotId(slotId);
    if (normalized == defaultSaveSlotId) {
      return _activeSessionKey;
    }
    return '$_activeSessionKey::$normalized';
  }

  String _savedAtKeyForSlot(String slotId) {
    final normalized = _normalizeSlotId(slotId);
    if (normalized == defaultSaveSlotId) {
      return _activeSavedAtKey;
    }
    return '$_activeSavedAtKey::$normalized';
  }

  /// Human-facing fixed save slots (slot_1..slot_3 by default).
  List<String> listSaveSlots({int count = manualSaveSlotCount}) {
    final clampedCount = count < 1 ? 1 : count;
    return List<String>.generate(clampedCount, (index) => 'slot_${index + 1}');
  }

  /// Load a saved game for a specific slot with failure details.
  ActiveGameLoadResult loadGameSlotDetailed(String slotId) {
    final gameJson = _activeBox.get(_gameKeyForSlot(slotId));
    final sessionJson = _activeBox.get(_sessionKeyForSlot(slotId));

    final hasAnyData = gameJson != null || sessionJson != null;
    if (!hasAnyData) return ActiveGameLoadResult.none();

    if (gameJson == null || sessionJson == null) {
      return ActiveGameLoadResult.failure(
        ActiveGameLoadFailure.partialSnapshot,
        hasAnyData: true,
      );
    }

    try {
      return ActiveGameLoadResult.success((
        GameState.fromJson(jsonDecode(gameJson) as Map<String, dynamic>),
        SessionState.fromJson(jsonDecode(sessionJson) as Map<String, dynamic>),
      ));
    } catch (_) {
      return ActiveGameLoadResult.failure(
        ActiveGameLoadFailure.corruptedSnapshot,
        hasAnyData: true,
      );
    }
  }

  /// Save the current game + session state to a specific slot.
  Future<void> saveGameSlot(
    String slotId,
    GameState game,
    SessionState session,
  ) async {
    final gameJson = await Isolate.run(() => jsonEncode(game.toJson()));
    final sessionJson = await Isolate.run(() => jsonEncode(session.toJson()));

    await _activeBox.put(_gameKeyForSlot(slotId), gameJson);
    await _activeBox.put(_sessionKeyForSlot(slotId), sessionJson);
    await _activeBox.put(
      _savedAtKeyForSlot(slotId),
      DateTime.now().toIso8601String(),
    );
  }

  /// Load a specific slot snapshot, or null if none exists.
  (GameState, SessionState)? loadGameSlot(String slotId) {
    return loadGameSlotDetailed(slotId).data;
  }

  /// Clear a specific save slot.
  Future<void> clearGameSlot(String slotId) async {
    await _activeBox.delete(_gameKeyForSlot(slotId));
    await _activeBox.delete(_sessionKeyForSlot(slotId));
    await _activeBox.delete(_savedAtKeyForSlot(slotId));
  }

  /// When the given slot was last saved (best-effort).
  DateTime? gameSlotSavedAt(String slotId) {
    final raw = _activeBox.get(_savedAtKeyForSlot(slotId));
    if (raw == null) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  /// Whether a specific save slot is complete and loadable.
  bool hasGameSlot(String slotId) {
    return _activeBox.get(_gameKeyForSlot(slotId)) != null &&
        _activeBox.get(_sessionKeyForSlot(slotId)) != null;
  }

  /// Load a previously saved active game with failure details.
  ///
  /// This method never clears data implicitly. If you want to discard an
  /// unreadable/partial snapshot, call [clearActiveGame] explicitly.
  ActiveGameLoadResult loadActiveGameDetailed() {
    return loadGameSlotDetailed(defaultSaveSlotId);
  }

  /// Save the current game + session state for crash recovery.
  Future<void> saveActiveGame(GameState game, SessionState session) async {
    await saveGameSlot(defaultSaveSlotId, game, session);
  }

  /// Load a previously saved active game, or null if none exists.
  (GameState, SessionState)? loadActiveGame() {
    return loadGameSlot(defaultSaveSlotId);
  }

  /// Clear the saved active game (after returning to lobby or archiving).
  Future<void> clearActiveGame() async {
    await clearGameSlot(defaultSaveSlotId);
  }

  /// When the active game was last saved (best-effort).
  DateTime? get activeGameSavedAt {
    return gameSlotSavedAt(defaultSaveSlotId);
  }

  /// Whether a saved active game exists.
  bool get hasActiveGame => hasGameSlot(defaultSaveSlotId);

  // ────────────────── Game Records (History) ──────────────────

  /// Archive a completed game.
  Future<void> saveGameRecord(GameRecord record) async {
    final recordJson = await Isolate.run(() => jsonEncode(record.toJson()));
    await _recordsBox.put(record.id, recordJson);
  }

  /// Load all game records, newest first.
  List<GameRecord> loadGameRecords() {
    final records = <GameRecord>[];
    for (final key in _recordsBox.keys) {
      if (key is String && key.startsWith(_awardProgressKeyPrefix)) {
        continue;
      }
      final raw = _recordsBox.get(key);
      if (raw == null) {
        continue;
      }
      try {
        records.add(
          GameRecord.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        );
      } catch (_) {
        // skip corrupted entries
      }
    }
    records.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    return records;
  }

  /// Delete a single game record by ID.
  Future<void> deleteGameRecord(String id) async {
    await _recordsBox.delete(id);
    await rebuildRoleAwardProgresses();
  }

  /// Delete all game records.
  Future<void> clearGameRecords() async {
    await _recordsBox.clear();
  }

  // ────────────────── Role Award Progress ──────────────────

  String _awardProgressKey(String playerKey, String awardId) {
    return '$_awardProgressKeyPrefix$playerKey::$awardId';
  }

  Future<void> saveRoleAwardProgress(PlayerRoleAwardProgress progress) async {
    await _recordsBox.put(
      _awardProgressKey(progress.playerKey, progress.awardId),
      jsonEncode(progress.toJson()),
    );
  }

  List<PlayerRoleAwardProgress> loadRoleAwardProgresses() {
    final progressList = <PlayerRoleAwardProgress>[];
    for (final key in _recordsBox.keys) {
      if (key is! String || !key.startsWith(_awardProgressKeyPrefix)) {
        continue;
      }
      final raw = _recordsBox.get(key);
      if (raw == null) {
        continue;
      }
      try {
        progressList.add(
          PlayerRoleAwardProgress.fromJson(
            jsonDecode(raw) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        // skip corrupted entries
      }
    }
    return progressList;
  }

  List<PlayerRoleAwardProgress> loadRoleAwardProgressesByPlayer(
    String playerKey,
  ) {
    return loadRoleAwardProgresses()
        .where((progress) => progress.playerKey == playerKey)
        .toList(growable: false);
  }

  List<PlayerRoleAwardProgress> loadRoleAwardProgressesByRole(String roleId) {
    return loadRoleAwardProgresses()
        .where((progress) {
          final definition = roleAwardDefinitionById(progress.awardId);
          return definition?.roleId == roleId;
        })
        .toList(growable: false);
  }

  List<PlayerRoleAwardProgress> loadRoleAwardProgressesByTier(
    RoleAwardTier tier,
  ) {
    return loadRoleAwardProgresses()
        .where((progress) {
          final definition = roleAwardDefinitionById(progress.awardId);
          return definition?.tier == tier;
        })
        .toList(growable: false);
  }

  List<PlayerRoleAwardProgress> loadRecentRoleAwardUnlocks({int limit = 20}) {
    final unlocked =
        loadRoleAwardProgresses()
            .where(
              (progress) => progress.isUnlocked && progress.unlockedAt != null,
            )
            .toList(growable: false)
          ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
    return unlocked.take(limit).toList(growable: false);
  }

  Future<void> clearRoleAwardProgresses() async {
    final keysToDelete = _recordsBox.keys
        .whereType<String>()
        .where((key) {
          return key.startsWith(_awardProgressKeyPrefix);
        })
        .toList(growable: false);

    for (final key in keysToDelete) {
      await _recordsBox.delete(key);
    }
  }

  Future<List<PlayerRoleAwardProgress>> rebuildRoleAwardProgresses() async {
    await clearRoleAwardProgresses();
    final records = loadGameRecords();
    final definitions = allRoleAwardDefinitions();
    if (records.isEmpty || definitions.isEmpty) {
      return const <PlayerRoleAwardProgress>[];
    }

    final roleStatsByPlayer = _buildRoleStatsByPlayer(records);
    final rebuilt = <PlayerRoleAwardProgress>[];

    for (final entry in roleStatsByPlayer.entries) {
      final playerKey = entry.key;
      final roleStats = entry.value;

      for (final roleEntry in roleStats.entries) {
        final roleId = roleEntry.key;
        final stats = roleEntry.value;
        final awardDefinitions = roleAwardsForRoleId(roleId);

        for (final definition in awardDefinitions) {
          final metric = _metricValueForRule(stats, definition.unlockRule);
          final threshold = _minimumForRule(definition.unlockRule);
          final unlocked = metric >= threshold;
          final progress = PlayerRoleAwardProgress(
            playerKey: playerKey,
            awardId: definition.awardId,
            progressValue: metric,
            isUnlocked: unlocked,
            unlockedAt: unlocked ? stats.latestEndedAt : null,
            sourceGameId: unlocked ? stats.latestGameId : null,
          );
          rebuilt.add(progress);
          await saveRoleAwardProgress(progress);
        }
      }
    }

    return rebuilt;
  }

  int _minimumForRule(Map<String, dynamic> unlockRule) {
    final raw = unlockRule['minimum'] ?? unlockRule['min'] ?? 1;
    if (raw is num) {
      return raw.toInt().clamp(0, 1000000);
    }
    return 1;
  }

  int _metricValueForRule(
    _RoleUsageStats stats,
    Map<String, dynamic> unlockRule,
  ) {
    final metric = (unlockRule['metric'] as String? ?? 'gamesPlayed').trim();
    switch (metric) {
      case 'wins':
      case 'gamesWon':
        return stats.gamesWon;
      case 'survivals':
      case 'gamesSurvived':
        return stats.survivals;
      case 'gamesPlayed':
      default:
        return stats.gamesPlayed;
    }
  }

  Map<String, Map<String, _RoleUsageStats>> _buildRoleStatsByPlayer(
    List<GameRecord> records,
  ) {
    final roleStatsByPlayer = <String, Map<String, _RoleUsageStats>>{};

    for (final record in records) {
      for (final player in record.roster) {
        final playerKey = player.id.trim().isEmpty ? player.name : player.id;
        final perRole = roleStatsByPlayer.putIfAbsent(
          playerKey,
          () => <String, _RoleUsageStats>{},
        );

        final current = perRole[player.roleId] ?? const _RoleUsageStats();
        perRole[player.roleId] = current.copyWith(
          gamesPlayed: current.gamesPlayed + 1,
          gamesWon: record.winner == player.alliance
              ? current.gamesWon + 1
              : current.gamesWon,
          survivals: player.alive ? current.survivals + 1 : current.survivals,
          latestEndedAt: record.endedAt,
          latestGameId: record.id,
        );
      }
    }

    return roleStatsByPlayer;
  }

  // ────────────────── Aggregate Stats ──────────────────

  /// Compute aggregate statistics from all stored game records.
  GameStats computeStats() {
    final records = loadGameRecords();
    if (records.isEmpty) return const GameStats();

    int staffWins = 0;
    int paWins = 0;
    int totalPlayers = 0;
    int totalDays = 0;
    final roleFreq = <String, int>{};
    final roleWins = <String, int>{};

    for (final r in records) {
      if (r.winner == Team.clubStaff) {
        staffWins++;
      } else if (r.winner == Team.partyAnimals) {
        paWins++;
      }
      totalPlayers += r.playerCount;
      totalDays += r.dayCount;

      for (final roleId in r.rolesInPlay) {
        roleFreq[roleId] = (roleFreq[roleId] ?? 0) + 1;
        // Count a "win" for the role if its team won
        final roleAlliance = r.roster
            .where((p) => p.roleId == roleId)
            .map((p) => p.alliance)
            .firstOrNull;
        if (roleAlliance == r.winner) {
          roleWins[roleId] = (roleWins[roleId] ?? 0) + 1;
        }
      }
    }

    return GameStats(
      totalGames: records.length,
      clubStaffWins: staffWins,
      partyAnimalsWins: paWins,
      averagePlayerCount: records.isEmpty
          ? 0
          : (totalPlayers / records.length).round(),
      averageDayCount: records.isEmpty
          ? 0
          : (totalDays / records.length).round(),
      roleFrequency: roleFreq,
      roleWinCount: roleWins,
    );
  }

  // ────────────────── Lifecycle ──────────────────

  // ────────────────── Games Night Sessions ──────────────────

  /// Save a Games Night session record.
  Future<void> saveGamesNightRecord(GamesNightRecord record) async {
    final recordJson = await Isolate.run(() => jsonEncode(record.toJson()));
    await _sessionsBox.put(record.id, recordJson);
  }

  /// Load all Games Night session records, sorted by start time (newest first).
  Future<List<GamesNightRecord>> loadAllSessions() async {
    final jsonStrings = _sessionsBox.values.whereType<String>().toList();

    if (jsonStrings.isEmpty) return [];

    return Isolate.run(() {
      final records = <GamesNightRecord>[];
      for (final jsonString in jsonStrings) {
        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          records.add(GamesNightRecord.fromJson(json));
        } catch (_) {
          // skip corrupted
        }
      }
      records.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return records;
    });
  }

  /// Load the currently active session, if any.
  Future<GamesNightRecord?> loadActiveSession() async {
    final sessions = await loadAllSessions();
    try {
      return sessions.firstWhere((s) => s.isActive);
    } catch (_) {
      return null;
    }
  }

  /// Update a session with a newly completed game.
  Future<void> updateSessionWithGame(
    String sessionId,
    String gameId,
    List<String> playerNames,
  ) async {
    final jsonString = _sessionsBox.get(sessionId);
    if (jsonString == null) return;

    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final session = GamesNightRecord.fromJson(json);

    // Add game ID
    final updatedGameIds = [...session.gameIds, gameId];

    // Update player games count
    final updatedGamesCount = Map<String, int>.from(session.playerGamesCount);
    for (final name in playerNames) {
      updatedGamesCount[name] = (updatedGamesCount[name] ?? 0) + 1;
    }

    // Merge player names (unique set)
    final updatedPlayerNames = {
      ...session.playerNames,
      ...playerNames,
    }.toList();

    final updatedSession = session.copyWith(
      gameIds: updatedGameIds,
      playerGamesCount: updatedGamesCount,
      playerNames: updatedPlayerNames,
    );

    await saveGamesNightRecord(updatedSession);
  }

  /// End an active session.
  Future<void> endSession(String sessionId) async {
    final jsonString = _sessionsBox.get(sessionId);
    if (jsonString == null) return;

    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final session = GamesNightRecord.fromJson(json);

    final updatedSession = session.copyWith(
      isActive: false,
      endedAt: DateTime.now(),
    );

    await saveGamesNightRecord(updatedSession);
  }

  /// Delete a session record.
  Future<void> deleteSession(String sessionId) async {
    await _sessionsBox.delete(sessionId);
  }

  /// Clear all session records.
  Future<void> clearAllSessions() async {
    await _sessionsBox.clear();
  }

  // ────────────────── Lifecycle ──────────────────

  /// Close all boxes. Call on app shutdown if needed.
  Future<void> close() async {
    await _activeBox.close();
    await _recordsBox.close();
    await _sessionsBox.close();
    _instance = null;
  }

  /// Reset the singleton instance (for testing only).
  static void reset() {
    _instance = null;
  }
}

class _RoleUsageStats {
  const _RoleUsageStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.survivals = 0,
    this.latestEndedAt,
    this.latestGameId,
  });

  final int gamesPlayed;
  final int gamesWon;
  final int survivals;
  final DateTime? latestEndedAt;
  final String? latestGameId;

  _RoleUsageStats copyWith({
    int? gamesPlayed,
    int? gamesWon,
    int? survivals,
    DateTime? latestEndedAt,
    String? latestGameId,
  }) {
    return _RoleUsageStats(
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      gamesWon: gamesWon ?? this.gamesWon,
      survivals: survivals ?? this.survivals,
      latestEndedAt: latestEndedAt ?? this.latestEndedAt,
      latestGameId: latestGameId ?? this.latestGameId,
    );
  }
}

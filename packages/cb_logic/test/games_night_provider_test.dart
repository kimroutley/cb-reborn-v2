import 'dart:convert';
import 'dart:io';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  late Directory tempDir;
  late PersistenceService service;
  late Box<String> activeBox;
  late Box<String> recordsBox;
  late Box<String> sessionsBox;
  late ProviderContainer container;

  setUp(() async {
    // Setup Hive with temp directory
    tempDir = await Directory.systemTemp.createTemp('games_night_test_');
    Hive.init(tempDir.path);

    // Open boxes
    activeBox = await Hive.openBox<String>('test_active_game');
    recordsBox = await Hive.openBox<String>('test_game_records');
    sessionsBox = await Hive.openBox<String>('test_games_night_sessions');

    // Initialize PersistenceService with boxes
    service = PersistenceService.initWithBoxes(
      activeBox,
      recordsBox,
      sessionsBox,
    );

    // Initialize ProviderContainer
    // We override dependencies if needed, but GamesNight uses the singleton PersistenceService directly.
    // Ideally we would override a persistenceServiceProvider, but since it's a singleton,
    // initializing it before creating the container should work if the provider accesses .instance.
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    await service.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
    PersistenceService.reset();
  });

  group('GamesNight Provider', () {
    test('Initial state is null', () {
      final state = container.read(gamesNightProvider);
      expect(state, isNull);
    });

    test('Loads active session on initialization', () async {
      // Setup: Create an active session in persistence
      final session = GamesNightRecord(
        id: 'session_123',
        sessionName: 'Existing Session',
        startedAt: DateTime.now(),
        isActive: true,
      );
      await service.saveGamesNightRecord(session);

      // Verify: Provider loads it
      // Since build() is async (side-effect), we need to wait for the state to update.
      // We can use a subscription to wait for the first non-null value.

      // However, the provider returns null initially and updates later.
      // Let's force a read and then wait a bit or use expectLater.

      // Note: GamesNight.build() is synchronous but calls _loadActiveSession() which is async.
      // The state update happens after await.

      // Re-create container to trigger build
      container.dispose();
      container = ProviderContainer();

      // Listen to the provider
      final listener = container.listen(gamesNightProvider, (_, __) {});

      // Wait for the state to be updated
      await Future.delayed(Duration(milliseconds: 100));

      final state = container.read(gamesNightProvider);
      expect(state, isNotNull);
      expect(state!.id, session.id);
      expect(state.sessionName, session.sessionName);

      listener.close();
    });

    test('startSession creates new active session', () async {
      final notifier = container.read(gamesNightProvider.notifier);

      await notifier.startSession('New Session');

      final state = container.read(gamesNightProvider);
      expect(state, isNotNull);
      expect(state!.sessionName, 'New Session');
      expect(state.isActive, isTrue);

      // Verify persistence
      final savedSessions = await service.loadAllSessions();
      expect(savedSessions, isNotEmpty);
      expect(savedSessions.first.id, state.id);
      expect(savedSessions.first.sessionName, 'New Session');
    });

    test('endSession ends the active session', () async {
      final notifier = container.read(gamesNightProvider.notifier);

      // Start a session
      await notifier.startSession('To Be Ended');
      GamesNightRecord? state = container.read(gamesNightProvider);
      expect(state!.isActive, isTrue);

      // End it
      await notifier.endSession();

      state = container.read<GamesNightRecord?>(gamesNightProvider);
      expect(state!.isActive, isFalse);
      expect(state.endedAt, isNotNull);

      // Verify persistence
      final savedSessions = await service.loadAllSessions();
      final savedSession = savedSessions.firstWhere((s) => s.id == state!.id);
      expect(savedSession.isActive, isFalse);
      expect(savedSession.endedAt, isNotNull);
    });

    test('refreshSession reloads from persistence', () async {
      final notifier = container.read(gamesNightProvider.notifier);

      await notifier.startSession('Original Name');
      GamesNightRecord? state = container.read(gamesNightProvider);
      final sessionId = state!.id;

      // Modify persistence directly
      final sessions = await service.loadAllSessions();
      final session = sessions.firstWhere((s) => s.id == sessionId);
      final updatedSession = session.copyWith(sessionName: 'Updated Name');
      await service.saveGamesNightRecord(updatedSession);

      // Refresh
      await notifier.refreshSession();

      state = container.read<GamesNightRecord?>(gamesNightProvider);
      expect(state!.sessionName, 'Updated Name');
    });

    test('refreshSession clears state if session deleted', () async {
      final notifier = container.read(gamesNightProvider.notifier);

      await notifier.startSession('To Be Deleted');
      GamesNightRecord? state = container.read(gamesNightProvider);
      final sessionId = state!.id;

      // Delete from persistence
      await service.deleteSession(sessionId);

      // Refresh
      await notifier.refreshSession();

      state = container.read<GamesNightRecord?>(gamesNightProvider);
      expect(state, isNull);
    });

    test('clearActiveSession clears state but keeps persistence', () async {
      final notifier = container.read(gamesNightProvider.notifier);

      await notifier.startSession('Persisted Session');

      notifier.clearActiveSession();

      final state = container.read(gamesNightProvider);
      expect(state, isNull);

      // Verify persistence still has it
      final sessions = await service.loadAllSessions();
      expect(sessions, isNotEmpty);
      expect(sessions.first.sessionName, 'Persisted Session');
    });
  });
}

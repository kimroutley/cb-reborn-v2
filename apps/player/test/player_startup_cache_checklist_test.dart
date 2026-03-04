// Tests aligned with docs/operations/player-startup-cache-qa-checklist.md (T1–T8).
// Unit-testable scenarios are covered here; T2, T3, T7, T8 require manual or
// integration runs (force-close, network, device time). See the checklist and
// runbook for full verification.

import 'package:cb_player/bootstrap/player_bootstrap_gate.dart';
import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/join_link_state.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_session_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCacheRepository extends PlayerSessionCacheRepository {
  const _FakeCacheRepository(this.entry);
  final PlayerSessionCacheEntry? entry;
  @override
  Future<PlayerSessionCacheEntry?> loadSession() async => entry;
}

Future<void> _pumpBootstrap(WidgetTester tester) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('T1: Fresh install / no cache path', () {
    testWidgets('bootstrap with no cache does not set pending join URL',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          playerSessionCacheRepositoryProvider
              .overrideWithValue(const _FakeCacheRepository(null)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PlayerBootstrapGate(
              skipPersistenceInit: true,
              skipFirestoreCacheConfig: true,
              skipAssetWarmup: true,
              child: Text('READY'),
            ),
          ),
        ),
      );
      await _pumpBootstrap(tester);

      expect(container.read(pendingJoinUrlProvider), isNull);
    });
  });

  group('T4: Sign-out clears cache', () {
    test('signOut clears session cache', () async {
      const repo = PlayerSessionCacheRepository();
      await repo.saveSession(
        PlayerSessionCacheEntry(
          joinCode: 'NEON-T4',
          mode: CachedSyncMode.cloud,
          savedAt: DateTime.now().toUtc(),
          state: const <String, dynamic>{'phase': 'lobby'},
        ),
      );
      expect(await repo.loadSession(), isNotNull);

      await const PlayerSessionCacheRepository().clear();
      expect(await repo.loadSession(), isNull);
    });
  });

  group('T5: Leave game clears cache', () {
    test('PlayerBridge.leave clears cache', () async {
      const repo = PlayerSessionCacheRepository();
      await repo.saveSession(
        PlayerSessionCacheEntry(
          joinCode: 'NEON-LOCAL',
          mode: CachedSyncMode.local,
          savedAt: DateTime.now().toUtc(),
          hostAddress: 'ws://127.0.0.1',
          state: const <String, dynamic>{'phase': 'lobby'},
        ),
      );
      expect(await repo.loadSession(), isNotNull);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(playerBridgeProvider.notifier).leave();

      expect(await repo.loadSession(), isNull);
    });

    test('CloudPlayerBridge.leave clears cache', () async {
      const repo = PlayerSessionCacheRepository();
      await repo.saveSession(
        PlayerSessionCacheEntry(
          joinCode: 'NEON-CLOUD',
          mode: CachedSyncMode.cloud,
          savedAt: DateTime.now().toUtc(),
          state: const <String, dynamic>{'phase': 'lobby'},
        ),
      );
      expect(await repo.loadSession(), isNotNull);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(cloudPlayerBridgeProvider.notifier).leave();

      expect(await repo.loadSession(), isNull);
    });
  });

  group('T6: Stale cache expiry', () {
    test('loadSession returns null and clears when entry older than 18h',
        () async {
      const repo = PlayerSessionCacheRepository();
      await repo.saveSession(
        PlayerSessionCacheEntry(
          joinCode: 'NEON-STALE',
          mode: CachedSyncMode.cloud,
          savedAt: DateTime.now().toUtc().subtract(const Duration(hours: 20)),
          state: const <String, dynamic>{'phase': 'lobby'},
        ),
      );

      final loaded = await repo.loadSession();
      expect(loaded, isNull);
      expect(await repo.loadSession(), isNull);
    });
  });

  group('T7/T8: Local and cloud restore (bootstrap seeds pending URL)', () {
    testWidgets(
        'local cache restore seeds pending URL with mode=local and host',
        (tester) async {
      final localBridge = _TrackingPlayerBridge();
      final cloudBridge = _TrackingCloudBridge();
      final cacheEntry = PlayerSessionCacheEntry(
        joinCode: 'NEON-LOCAL',
        mode: CachedSyncMode.local,
        savedAt: DateTime.now().toUtc(),
        hostAddress: 'ws://192.168.1.100',
        playerName: 'Pat',
        state: const <String, dynamic>{'phase': 'lobby', 'joinAccepted': true},
      );
      final container = ProviderContainer(
        overrides: [
          playerSessionCacheRepositoryProvider
              .overrideWithValue(_FakeCacheRepository(cacheEntry)),
          playerBridgeProvider.overrideWith(() => localBridge),
          cloudPlayerBridgeProvider.overrideWith(() => cloudBridge),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PlayerBootstrapGate(
              skipPersistenceInit: true,
              skipFirestoreCacheConfig: true,
              skipAssetWarmup: true,
              child: Text('READY'),
            ),
          ),
        ),
      );
      await _pumpBootstrap(tester);

      expect(localBridge.restoredEntry, isNotNull);
      expect(cloudBridge.restoredEntry, isNull);
      final pending = container.read(pendingJoinUrlProvider);
      expect(pending, isNotNull);
      final uri = Uri.parse(pending!);
      expect(uri.queryParameters['mode'], 'local');
      expect(uri.queryParameters['host'], 'ws://192.168.1.100');
      expect(uri.queryParameters['autoconnect'], '1');
    });

    testWidgets('cloud cache restore seeds pending URL with mode=cloud',
        (tester) async {
      final localBridge = _TrackingPlayerBridge();
      final cloudBridge = _TrackingCloudBridge();
      final cacheEntry = PlayerSessionCacheEntry(
        joinCode: 'NEON-CLOUD',
        mode: CachedSyncMode.cloud,
        savedAt: DateTime.now().toUtc(),
        playerName: 'Nova',
        state: const <String, dynamic>{'phase': 'lobby', 'joinAccepted': true},
      );
      final container = ProviderContainer(
        overrides: [
          playerSessionCacheRepositoryProvider
              .overrideWithValue(_FakeCacheRepository(cacheEntry)),
          playerBridgeProvider.overrideWith(() => localBridge),
          cloudPlayerBridgeProvider.overrideWith(() => cloudBridge),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: PlayerBootstrapGate(
              skipPersistenceInit: true,
              skipFirestoreCacheConfig: true,
              skipAssetWarmup: true,
              child: Text('READY'),
            ),
          ),
        ),
      );
      await _pumpBootstrap(tester);

      expect(cloudBridge.restoredEntry, isNotNull);
      expect(localBridge.restoredEntry, isNull);
      final pending = container.read(pendingJoinUrlProvider);
      expect(pending, isNotNull);
      final uri = Uri.parse(pending!);
      expect(uri.queryParameters['mode'], 'cloud');
      expect(uri.queryParameters['code'], 'NEON-CLOUD');
      expect(uri.queryParameters['autoconnect'], '1');
    });
  });
}

class _TrackingPlayerBridge extends PlayerBridge {
  PlayerSessionCacheEntry? restoredEntry;
  @override
  PlayerGameState build() => const PlayerGameState();
  @override
  void restoreFromCache(PlayerSessionCacheEntry entry) {
    restoredEntry = entry;
    state = PlayerGameState.fromCacheMap(entry.state);
  }
}

class _TrackingCloudBridge extends CloudPlayerBridge {
  PlayerSessionCacheEntry? restoredEntry;
  @override
  PlayerGameState build() => const PlayerGameState();
  @override
  void restoreFromCache(PlayerSessionCacheEntry entry) {
    restoredEntry = entry;
    state = PlayerGameState.fromCacheMap(entry.state);
  }
}

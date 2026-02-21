import 'dart:async';

import 'package:cb_player/bootstrap/player_bootstrap_gate.dart';
import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/join_link_state.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_session_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCacheRepository extends PlayerSessionCacheRepository {
  const _FakeCacheRepository(this.entry);

  final PlayerSessionCacheEntry? entry;

  @override
  Future<PlayerSessionCacheEntry?> loadSession() async => entry;
}

class _DelayedCacheRepository extends PlayerSessionCacheRepository {
  _DelayedCacheRepository(this.completer);

  final Completer<PlayerSessionCacheEntry?> completer;

  @override
  Future<PlayerSessionCacheEntry?> loadSession() => completer.future;
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

Future<void> _pumpBootstrapProgress(WidgetTester tester) async {
  for (var i = 0; i < 120; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  testWidgets('bootstrap loader shows bounded progress label while restoring',
      (tester) async {
    final localBridge = _TrackingPlayerBridge();
    final cloudBridge = _TrackingCloudBridge();
    final completer = Completer<PlayerSessionCacheEntry?>();
    final container = ProviderContainer(
      overrides: [
        playerSessionCacheRepositoryProvider
            .overrideWithValue(_DelayedCacheRepository(completer)),
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

    await tester.pump();

    expect(find.text('RESTORING LAST SESSION...'), findsOneWidget);
    expect(find.text('0% - 0/1'), findsOneWidget);

    completer.complete(null);
    await _pumpBootstrapProgress(tester);

    expect(find.text('READY'), findsOneWidget);
  });

  testWidgets('bootstrap with no cache does not seed pending join URL',
      (tester) async {
    final localBridge = _TrackingPlayerBridge();
    final cloudBridge = _TrackingCloudBridge();
    final container = ProviderContainer(
      overrides: [
        playerSessionCacheRepositoryProvider
            .overrideWithValue(const _FakeCacheRepository(null)),
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

    await _pumpBootstrapProgress(tester);

    expect(localBridge.restoredEntry, isNull);
    expect(cloudBridge.restoredEntry, isNull);
    expect(container.read(pendingJoinUrlProvider), isNull);
  });

  testWidgets('bootstrap ignores local cache entries for cloud-only mode',
      (tester) async {
    final localBridge = _TrackingPlayerBridge();
    final cloudBridge = _TrackingCloudBridge();
    final cacheEntry = PlayerSessionCacheEntry(
      joinCode: 'NEON-ABCDEF',
      mode: CachedSyncMode.local,
      savedAt: DateTime.now().toUtc(),
      hostAddress: 'ws://192.168.1.50',
      playerName: 'Ava',
      state: const <String, dynamic>{
        'phase': 'lobby',
        'joinAccepted': true,
      },
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

    await _pumpBootstrapProgress(tester);

    expect(localBridge.restoredEntry, isNull);
    expect(cloudBridge.restoredEntry, isNull);
    expect(container.read(pendingJoinUrlProvider), isNull);
  });

  testWidgets('bootstrap restores cloud cache and seeds cloud autoconnect URL',
      (tester) async {
    final localBridge = _TrackingPlayerBridge();
    final cloudBridge = _TrackingCloudBridge();
    final cacheEntry = PlayerSessionCacheEntry(
      joinCode: 'NEON-UVWXYZ',
      mode: CachedSyncMode.cloud,
      savedAt: DateTime.now().toUtc(),
      playerName: 'Nova',
      state: const <String, dynamic>{
        'phase': 'night',
        'joinAccepted': true,
      },
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

    await _pumpBootstrapProgress(tester);

    expect(cloudBridge.restoredEntry, isNotNull);
    expect(localBridge.restoredEntry, isNull);

    final pendingJoin = container.read(pendingJoinUrlProvider);
    expect(pendingJoin, isNotNull);
    final uri = Uri.parse(pendingJoin!);
    expect(uri.queryParameters['mode'], 'cloud');
    expect(uri.queryParameters['code'], 'NEON-UVWXYZ');
    expect(uri.queryParameters['host'], isNull);
    expect(uri.queryParameters['autoconnect'], '1');
  });
}

import 'package:cb_player/player_session_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('PlayerSessionCacheRepository saves and loads entry', () async {
    final repo = const PlayerSessionCacheRepository();
    final entry = PlayerSessionCacheEntry(
      joinCode: 'NEON-ABCDEF',
      mode: CachedSyncMode.cloud,
      savedAt: DateTime.now().toUtc(),
      state: const {'phase': 'lobby', 'joinAccepted': true},
      playerName: 'Ava',
    );

    await repo.saveSession(entry);
    final loaded = await repo.loadSession();

    expect(loaded, isNotNull);
    expect(loaded!.joinCode, 'NEON-ABCDEF');
    expect(loaded.mode, CachedSyncMode.cloud);
    expect(loaded.playerName, 'Ava');
    expect(loaded.state['phase'], 'lobby');
  });

  test('PlayerSessionCacheRepository drops stale entries', () async {
    final repo = const PlayerSessionCacheRepository();
    final stale = PlayerSessionCacheEntry(
      joinCode: 'NEON-STALE1',
      mode: CachedSyncMode.local,
      savedAt: DateTime.now().toUtc().subtract(const Duration(days: 2)),
      state: const {'phase': 'day'},
      hostAddress: 'ws://192.168.1.1',
    );

    await repo.saveSession(stale);
    final loaded = await repo.loadSession();

    expect(loaded, isNull);
  });
}

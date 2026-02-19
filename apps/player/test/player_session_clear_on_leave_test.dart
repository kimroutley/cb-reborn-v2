import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_session_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('PlayerBridge.leave clears cached session', () async {
    final repo = const PlayerSessionCacheRepository();
    await repo.saveSession(
      PlayerSessionCacheEntry(
        joinCode: 'NEON-LOCAL1',
        mode: CachedSyncMode.local,
        savedAt: DateTime.now().toUtc(),
        hostAddress: 'ws://127.0.0.1:8080',
        state: const <String, dynamic>{'phase': 'lobby'},
      ),
    );
    expect(await repo.loadSession(), isNotNull);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(playerBridgeProvider.notifier).leave();

    expect(await repo.loadSession(), isNull);
  });

  test('CloudPlayerBridge.leave clears cached session', () async {
    final repo = const PlayerSessionCacheRepository();
    await repo.saveSession(
      PlayerSessionCacheEntry(
        joinCode: 'NEON-CLOUD1',
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
}

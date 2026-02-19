import 'package:cb_player/auth/auth_provider.dart';
import 'package:cb_player/player_session_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('signOut clears session cache even when Firebase is unavailable', () async {
    final repo = const PlayerSessionCacheRepository();
    await repo.saveSession(
      PlayerSessionCacheEntry(
        joinCode: 'NEON-ABCDEF',
        mode: CachedSyncMode.cloud,
        savedAt: DateTime.now().toUtc(),
        state: const <String, dynamic>{'phase': 'lobby'},
      ),
    );
    expect(await repo.loadSession(), isNotNull);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(authProvider.notifier).signOut();

    expect(await repo.loadSession(), isNull);
    expect(
      container.read(authProvider).status,
      AuthStatus.unauthenticated,
    );
  });
}

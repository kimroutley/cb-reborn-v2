import 'package:cb_player/auth/auth_provider.dart';
import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/join_link_state.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/screens/home_screen.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TrackingPlayerBridge extends PlayerBridge {
  int connectCalls = 0;
  int joinGameCalls = 0;
  int disconnectCalls = 0;
  String? lastConnectUrl;
  String? lastJoinCode;

  @override
  PlayerGameState build() => const PlayerGameState();

  @override
  Future<void> connect(String url) async {
    connectCalls += 1;
    lastConnectUrl = url;
    state = state.copyWith(isConnected: true);
  }

  @override
  Future<void> joinGame(String joinCode, String playerName) async {
    joinGameCalls += 1;
    lastJoinCode = joinCode;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
    state = const PlayerGameState();
  }
}

class _TrackingCloudBridge extends CloudPlayerBridge {
  int joinGameCalls = 0;
  int disconnectCalls = 0;
  String? lastJoinCode;

  @override
  PlayerGameState build() => const PlayerGameState();

  @override
  Future<void> joinGame(String joinCode, String playerName) async {
    joinGameCalls += 1;
    lastJoinCode = joinCode;
    state = state.copyWith(isConnected: true, joinAccepted: true);
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
    state = const PlayerGameState();
  }
}

class _FlakyCloudBridge extends CloudPlayerBridge {
  _FlakyCloudBridge(this.failuresBeforeSuccess);

  int failuresBeforeSuccess;
  int joinGameCalls = 0;

  @override
  PlayerGameState build() => const PlayerGameState();

  @override
  Future<void> joinGame(String joinCode, String playerName) async {
    joinGameCalls += 1;
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess -= 1;
      throw Exception('Transient cloud failure');
    }
    state = state.copyWith(isConnected: true, joinAccepted: true);
  }

  @override
  Future<void> disconnect() async {}
}

class _SeededPendingJoinUrlNotifier extends PendingJoinUrlNotifier {
  _SeededPendingJoinUrlNotifier(this.initial);

  final String? initial;

  @override
  String? build() => initial;
}

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this.initialState);

  final AuthState initialState;

  @override
  AuthState build() => initialState;
}

Future<void> _pumpFrames(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  test('resume retry delay uses capped backoff schedule', () {
    expect(resumeRetryDelayForAttempt(0), const Duration(seconds: 2));
    expect(resumeRetryDelayForAttempt(1), const Duration(seconds: 4));
    expect(resumeRetryDelayForAttempt(3), const Duration(seconds: 12));
    expect(resumeRetryDelayForAttempt(99), const Duration(seconds: 30));
  });

  testWidgets(
      'pending legacy local autoconnect URL is coerced to cloud reconnect flow',
      (tester) async {
    final playerBridge = _TrackingPlayerBridge();
    final cloudBridge = _TrackingCloudBridge();
    final pendingUrl = Uri(
      path: '/join',
      queryParameters: <String, String>{
        'code': 'NEON-ABCDEF',
        'mode': 'local',
        'host': 'ws://192.168.1.44',
        'autoconnect': '1',
      },
    ).toString();
    final container = ProviderContainer(
      overrides: [
        playerBridgeProvider.overrideWith(() => playerBridge),
        cloudPlayerBridgeProvider.overrideWith(() => cloudBridge),
        pendingJoinUrlProvider
            .overrideWith(() => _SeededPendingJoinUrlNotifier(pendingUrl)),
        authProvider.overrideWith(
          () => _StubAuthNotifier(const AuthState(AuthStatus.unauthenticated)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
          home: const HomeScreen(),
        ),
      ),
    );

    await _pumpFrames(tester);

    expect(playerBridge.connectCalls, 0);
    expect(playerBridge.joinGameCalls, 0);
    expect(playerBridge.lastConnectUrl, isNull);
    expect(playerBridge.lastJoinCode, isNull);
    expect(playerBridge.disconnectCalls, 1);
    expect(cloudBridge.joinGameCalls, 1);
    expect(cloudBridge.lastJoinCode, 'NEON-ABCDEF');
    expect(container.read(pendingJoinUrlProvider), isNull);
  });

  testWidgets('pending cloud autoconnect URL triggers cloud reconnect flow',
      (tester) async {
    final playerBridge = _TrackingPlayerBridge();
    final cloudBridge = _TrackingCloudBridge();
    final pendingUrl = Uri(
      path: '/join',
      queryParameters: <String, String>{
        'code': 'NEON-XYZ123',
        'mode': 'cloud',
        'autoconnect': '1',
      },
    ).toString();
    final container = ProviderContainer(
      overrides: [
        playerBridgeProvider.overrideWith(() => playerBridge),
        cloudPlayerBridgeProvider.overrideWith(() => cloudBridge),
        pendingJoinUrlProvider
            .overrideWith(() => _SeededPendingJoinUrlNotifier(pendingUrl)),
        authProvider.overrideWith(
          () => _StubAuthNotifier(const AuthState(AuthStatus.unauthenticated)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
          home: const HomeScreen(),
        ),
      ),
    );

    await _pumpFrames(tester);

    expect(cloudBridge.joinGameCalls, 1);
    expect(cloudBridge.lastJoinCode, 'NEON-XYZ123');
    expect(playerBridge.disconnectCalls, 1);
    expect(container.read(pendingJoinUrlProvider), isNull);
  });

  testWidgets('pending cloud autoconnect retries after transient failure',
      (tester) async {
    final playerBridge = _TrackingPlayerBridge();
    final cloudBridge = _FlakyCloudBridge(1);
    final pendingUrl = Uri(
      path: '/join',
      queryParameters: <String, String>{
        'code': 'NEON-RETRY1',
        'mode': 'cloud',
        'autoconnect': '1',
      },
    ).toString();
    final container = ProviderContainer(
      overrides: [
        playerBridgeProvider.overrideWith(() => playerBridge),
        cloudPlayerBridgeProvider.overrideWith(() => cloudBridge),
        pendingJoinUrlProvider
            .overrideWith(() => _SeededPendingJoinUrlNotifier(pendingUrl)),
        authProvider.overrideWith(
          () => _StubAuthNotifier(const AuthState(AuthStatus.unauthenticated)),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
          home: const HomeScreen(),
        ),
      ),
    );

    await _pumpFrames(tester);
    expect(cloudBridge.joinGameCalls, 1);

    await tester.pump(const Duration(seconds: 2));
    await _pumpFrames(tester);

    expect(cloudBridge.joinGameCalls, 2);
    expect(container.read(cloudPlayerBridgeProvider).joinAccepted, isTrue);
  });
}

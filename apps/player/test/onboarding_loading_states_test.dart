import 'dart:async';

import 'package:cb_player/auth/auth_provider.dart';
import 'package:cb_player/auth/player_auth_screen.dart';
import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/screens/claim_screen.dart';
import 'package:cb_player/screens/home_screen.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _SeededCloudBridge extends CloudPlayerBridge {
  _SeededCloudBridge(this._seed);

  final PlayerGameState _seed;

  @override
  PlayerGameState build() => _seed;

  @override
  Future<void> disconnect() async {}
}

class _DelayedCloudBridge extends CloudPlayerBridge {
  _DelayedCloudBridge(this.joinCompleter);

  final Completer<void> joinCompleter;

  @override
  PlayerGameState build() => const PlayerGameState();

  @override
  Future<void> joinGame(String joinCode, String playerName) {
    return joinCompleter.future;
  }

  @override
  Future<void> disconnect() async {}
}

class _NoopPlayerBridge extends PlayerBridge {
  @override
  PlayerGameState build() => const PlayerGameState();

  @override
  Future<void> disconnect() async {}
}

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this.initial);

  final AuthState initial;

  @override
  AuthState build() => initial;
}

void main() {
  testWidgets(
    'PlayerAuthScreen initial state shows neutral boot splash (no login flash)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              () => _StubAuthNotifier(const AuthState(AuthStatus.initial)),
            ),
          ],
          child: MaterialApp(
            theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
            home: const PlayerAuthScreen(
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('SYNCING SESSION...'), findsOneWidget);
      expect(find.text('GUEST LIST CHECK'), findsNothing);
    },
  );

  testWidgets(
    'PlayerAuthScreen shows loading dialog overlay while preserving splash context',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith(
              () => _StubAuthNotifier(const AuthState(AuthStatus.loading)),
            ),
          ],
          child: MaterialApp(
            theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
            home: const PlayerAuthScreen(
              child: SizedBox.shrink(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('VERIFYING VIP PASS...'), findsOneWidget);
      expect(
        find.text('Please wait while we validate your invite.'),
        findsOneWidget,
      );
      expect(find.text('GUEST LIST CHECK'), findsOneWidget);
    },
  );

  testWidgets(
    'HomeScreen shows modal loading dialog while connecting',
    (tester) async {
      final joinCompleter = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudPlayerBridgeProvider.overrideWith(
              () => _DelayedCloudBridge(joinCompleter),
            ),
            playerBridgeProvider.overrideWith(() => _NoopPlayerBridge()),
            authProvider.overrideWith(
              () => _StubAuthNotifier(
                  const AuthState(AuthStatus.unauthenticated)),
            ),
          ],
          child: MaterialApp(
            theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.enterText(
        find.byType(CBTextField).first,
        'NEON-ABCDEF',
      );
      await tester.tap(find.text('CONNECT TO HOST'));
      await tester.pump();

      expect(find.text('CONNECTING TO HOST...'), findsOneWidget);
      expect(
          find.text('Hang tight while we sync your invite.'), findsOneWidget);
      expect(find.text('CONNECTING...'), findsOneWidget);

      joinCompleter.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CONNECTING TO HOST...'), findsNothing);
    },
  );

  testWidgets(
    'ClaimScreen shows loading placeholder when identities have not synced yet',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudPlayerBridgeProvider.overrideWith(
              () => _SeededCloudBridge(
                const PlayerGameState(
                  players: [],
                  joinAccepted: true,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
            home: const ClaimScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CBBreathingLoader), findsOneWidget);
      expect(find.text('LOADING IDENTITIES...'), findsOneWidget);
      expect(find.text('Please wait for the Host to add you.'), findsNothing);
    },
  );

  testWidgets(
    'ClaimScreen shows waiting placeholder when all identities are already claimed',
    (tester) async {
      const players = [
        PlayerSnapshot(
          id: 'p1',
          name: 'Player 1',
          roleId: 'role_1',
          roleName: 'Role 1',
          alliance: 'unknown',
        ),
        PlayerSnapshot(
          id: 'p2',
          name: 'Player 2',
          roleId: 'role_2',
          roleName: 'Role 2',
          alliance: 'unknown',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudPlayerBridgeProvider.overrideWith(
              () => _SeededCloudBridge(
                const PlayerGameState(
                  players: players,
                  claimedPlayerIds: ['p1', 'p2'],
                  joinAccepted: true,
                ),
              ),
            ),
          ],
          child: MaterialApp(
            theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
            home: const ClaimScreen(),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CBBreathingLoader), findsOneWidget);
      expect(find.text('WAITING FOR AN OPEN IDENTITY...'), findsOneWidget);
      expect(find.text('Please wait for the Host to add you.'), findsOneWidget);
    },
  );
}

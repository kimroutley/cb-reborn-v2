import 'package:cb_player/auth/auth_provider.dart';
import 'package:cb_player/auth/player_auth_screen.dart';
import 'package:cb_player/cloud_player_bridge.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_destinations.dart';
import 'package:cb_player/player_navigation.dart';
import 'package:cb_player/screens/guides_screen.dart';
import 'package:cb_player/screens/home_screen.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Mocks & Stubs
class MockNavigationNotifier extends PlayerNavigationNotifier {
  PlayerDestination? lastDestination;

  @override
  void setDestination(PlayerDestination destination) {
    lastDestination = destination;
    super.setDestination(destination);
  }
}

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this.initial);
  final AuthState initial;
  @override
  AuthState build() => initial;
}

class _NoopCloudBridge extends CloudPlayerBridge {
  @override
  PlayerGameState build() => const PlayerGameState();
  @override
  Future<void> disconnect() async {}
}

class _NoopPlayerBridge extends PlayerBridge {
  @override
  PlayerGameState build() => const PlayerGameState();
  @override
  Future<void> disconnect() async {}
}

void main() {
  testWidgets('PlayerAuthScreen: Just Browsing CTA navigates to guides',
      (tester) async {
    final navNotifier = MockNavigationNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
              () => _StubAuthNotifier(const AuthState(AuthStatus.unauthenticated))),
          playerNavigationProvider.overrideWith(() => navNotifier),
        ],
        child: MaterialApp(
          theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
          home: const PlayerAuthScreen(),
        ),
      ),
    );

    await tester.pump();

    // Scroll to ensure visibility
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pump();

    expect(find.text('JUST BROWSING?'), findsOneWidget);
    await tester.tap(find.text('JUST BROWSING?'));

    expect(navNotifier.lastDestination, PlayerDestination.guides);
  });

  testWidgets('HomeScreen: Just Browsing CTA navigates to guides',
      (tester) async {
    final navNotifier = MockNavigationNotifier();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerNavigationProvider.overrideWith(() => navNotifier),
          cloudPlayerBridgeProvider.overrideWith(() => _NoopCloudBridge()),
          playerBridgeProvider.overrideWith(() => _NoopPlayerBridge()),
          authProvider.overrideWith(
              () => _StubAuthNotifier(const AuthState(AuthStatus.initial))),
        ],
        child: MaterialApp(
          theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    // Scroll to bottom to ensure visibility
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pump();

    expect(find.text('JUST BROWSING?'), findsOneWidget);
    await tester.tap(find.text('JUST BROWSING?'));

    expect(navNotifier.lastDestination, PlayerDestination.guides);
  });

  testWidgets('GuidesScreen: Renders in scaffold when disconnected',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudPlayerBridgeProvider.overrideWith(() => _NoopCloudBridge()),
          playerBridgeProvider.overrideWith(() => _NoopPlayerBridge()),
          playerNavigationProvider.overrideWith(() => MockNavigationNotifier()),
        ],
        child: MaterialApp(
          theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
          home: const GuidesScreen(),
        ),
      ),
    );

    await tester.pump();

    // Verify scaffold title
    expect(find.text('THE BLACKBOOK'), findsAtLeastNWidgets(1));
    
    // Verify guide screen content (tabs)
    expect(find.text('MANUAL'), findsOneWidget);
    expect(find.text('OPERATIVES'), findsOneWidget);
    expect(find.text('INTEL'), findsOneWidget);
  });
}

import 'package:cb_player/player_destinations.dart';
import 'package:cb_player/player_navigation.dart';
import 'package:cb_player/player_stats.dart';
import 'package:cb_player/screens/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cb_player/auth/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _FakePlayerStatsNotifier extends PlayerStatsNotifier {
  @override
  PlayerStats build() {
    return const PlayerStats(
      playerId: 'p1',
      gamesPlayed: 12,
      gamesWon: 6,
      rolesPlayed: <String, int>{'dealer': 5},
    );
  }
}

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this.initial);

  final AuthState initial;

  @override
  AuthState build() => initial;
}

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('Stats action opens Hall of Fame destination',
      (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        playerStatsProvider.overrideWith(_FakePlayerStatsNotifier.new),
        authProvider.overrideWith(
          () => _StubAuthNotifier(
              AuthState(AuthStatus.authenticated, user: _FakeUser())),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: StatsScreen()),
      ),
    );

    await tester.tap(find.text('VIEW HALL OF FAME'));
    await tester.pump();

    expect(
      container.read(playerNavigationProvider),
      PlayerDestination.hallOfFame,
    );
  });
}

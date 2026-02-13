import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cb_player/screens/games_night_recap_screen.dart';

void main() {
  testWidgets('GamesNightRecapScreen renders correctly',
      (WidgetTester tester) async {
    final now = DateTime.now();
    final session = GamesNightRecord(
      id: 'session-123',
      sessionName: 'Epic Night',
      startedAt: now.subtract(const Duration(hours: 3)),
      endedAt: now,
      isActive: false,
    );

    final games = [
      GameRecord(
        id: 'game-1',
        startedAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        endedAt: now.subtract(const Duration(hours: 2)),
        winner: Team.partyAnimals,
        playerCount: 10,
        dayCount: 5,
      ),
      GameRecord(
        id: 'game-2',
        startedAt: now.subtract(const Duration(hours: 1, minutes: 30)),
        endedAt: now.subtract(const Duration(hours: 1)),
        winner: Team.clubStaff,
        playerCount: 10,
        dayCount: 3,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
        home: GamesNightRecapScreen(
          session: session,
          games: games,
        ),
      ),
    );

    await tester.pump();

    // Verify Session Name
    // Note: CBTypography or Text widgets in the app might apply uppercase.
    // In our implementation: Text(session.sessionName.toUpperCase(), ...)
    expect(find.text('EPIC NIGHT'), findsOneWidget);

    // Verify Stats
    // "PARTY ANIMALS" appears in the stat card label and in the game tile subtitle.
    expect(find.text('PARTY ANIMALS'), findsAtLeastNWidgets(1));

    // "CLUB STAFF" appears in the stat card label and in the game tile subtitle.
    expect(find.text('CLUB STAFF'), findsAtLeastNWidgets(1));

    // Verify Win Counts (1 for each)
    // The text '1' should appear in the stat cards.
    expect(find.text('1'), findsAtLeastNWidgets(2));

    // Verify Game Tiles
    expect(find.text('GAME • 5 ROUNDS'), findsOneWidget);
    expect(find.text('GAME • 3 ROUNDS'), findsOneWidget);
  });
}

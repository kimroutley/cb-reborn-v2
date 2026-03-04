import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestApp(Widget child) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  group('CBDayRecapCard', () {
    testWidgets('shows collapsed bullets by default', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const CBDayRecapCard(
          title: 'DAY 1 RECAP',
          bullets: [
            'Bullet one',
            'Bullet two',
            'Bullet three',
            'Bullet four',
            'Bullet five',
          ],
          collapsedBulletCount: 3,
        ),
      ));

      // First 3 bullets visible (widget uppercases all text)
      expect(find.text('BULLET ONE'), findsOneWidget);
      expect(find.text('BULLET TWO'), findsOneWidget);
      expect(find.text('BULLET THREE'), findsOneWidget);
      // 4th+ bullet hidden
      expect(find.text('BULLET FOUR'), findsNothing);
      expect(find.text('BULLET FIVE'), findsNothing);
      // Expand control visible
      expect(find.text('EXPAND'), findsOneWidget);
    });

    testWidgets('expands to show all bullets when tapped', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const CBDayRecapCard(
          title: 'DAY 2 RECAP',
          bullets: [
            'Alpha',
            'Bravo',
            'Charlie',
            'Delta',
          ],
          collapsedBulletCount: 2,
        ),
      ));

      // Initially collapsed (widget uppercases all text)
      expect(find.text('DELTA'), findsNothing);

      // Tap EXPAND
      await tester.tap(find.text('EXPAND'));
      await tester.pump(const Duration(milliseconds: 500));

      // All visible
      expect(find.text('ALPHA'), findsOneWidget);
      expect(find.text('BRAVO'), findsOneWidget);
      expect(find.text('CHARLIE'), findsOneWidget);
      expect(find.text('DELTA'), findsOneWidget);
      expect(find.text('COLLAPSE'), findsOneWidget);
    });

    testWidgets('collapses again after tapping COLLAPSE', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const CBDayRecapCard(
          title: 'RECAP',
          bullets: ['A', 'B', 'C', 'D'],
          collapsedBulletCount: 2,
        ),
      ));

      // Expand
      await tester.tap(find.text('EXPAND'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('D'), findsOneWidget);

      // Collapse
      await tester.tap(find.text('COLLAPSE'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('D'), findsNothing);
    });

    testWidgets('shows fallback text when bullets are empty', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const CBDayRecapCard(
          title: 'EMPTY RECAP',
          bullets: [],
        ),
      ));

      expect(find.text('NO RECAP DATA AVAILABLE FOR THIS CYCLE.'), findsOneWidget);
      expect(find.text('EXPAND'), findsNothing);
    });

    testWidgets('hides expand when count <= collapsedBulletCount',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        const CBDayRecapCard(
          title: 'SHORT',
          bullets: ['One', 'Two'],
          collapsedBulletCount: 3,
        ),
      ));

      expect(find.text('ONE'), findsOneWidget);
      expect(find.text('TWO'), findsOneWidget);
      expect(find.text('EXPAND'), findsNothing);
    });

    testWidgets('shows HOST ONLY tag when tagText is provided', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const CBDayRecapCard(
          title: 'HOST RECAP',
          bullets: ['Spicy detail'],
          tagText: 'HOST ONLY',
        ),
      ));

      expect(find.text('HOST ONLY'), findsOneWidget);
    });
  });
}

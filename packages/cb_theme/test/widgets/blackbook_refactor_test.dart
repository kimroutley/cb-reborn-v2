import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test wrapper providing required Theme/MediaQuery context
Widget createTestWidget(Widget child) {
  return MaterialApp(
    theme: ThemeData.dark(), // Fallback to standard dark theme for testing
    home: Scaffold(body: child),
  );
}

void main() {
  group('Blackbook Refactor Tests', () {
    testWidgets('CBGuideScreen renders integrated navigation rail',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const CBGuideScreen()));

      // Verify main rail items
      expect(find.text('MANUAL'), findsOneWidget);
      expect(find.text('OPERATIVES'), findsOneWidget);
      expect(find.text('INTEL'), findsOneWidget);

      // Verify initial state (Manual tab active)
      // We expect Handbook content to be present
      expect(find.byType(CBIndexedHandbook), findsOneWidget);
    });

    testWidgets('Tapping OPERATIVES switches tab and shows list',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const CBGuideScreen()));

      // Tap OPERATIVES rail item
      await tester.tap(find.text('OPERATIVES'));
      await tester.pumpAndSettle();

      // Content should switch away from Handbook
      expect(find.byType(CBIndexedHandbook), findsNothing);

      // Should show list of roles (CBRoleIDCard)
      // Since roleCatalog is non-empty, we expect at least one card
      expect(find.byType(CBRoleIDCard), findsWidgets);

      // Verify SEARCH field is present
      expect(find.widgetWithText(CBTextField, 'SEARCH DOSSIERS...'),
          findsOneWidget);
    });

    testWidgets('Tapping a Role Card opens the Sliding Panel', (tester) async {
      await tester.pumpWidget(createTestWidget(const CBGuideScreen()));

      // Navigate to Operatives
      await tester.tap(find.text('OPERATIVES'));
      await tester.pumpAndSettle();

      // Find the first role card
      final firstCard = find.byType(CBRoleIDCard).first;
      expect(firstCard, findsOneWidget);

      // Tap it
      await tester.tap(firstCard);
      // Use explicit pumps instead of pumpAndSettle to avoid infinite animation timeout from breathing avatar
      await tester.pump(); // Start animation
      await tester
          .pump(const Duration(milliseconds: 500)); // Finish panel slide

      // Sliding Panel should be open
      expect(find.byType(CBSlidingPanel), findsOneWidget);

      // Verify content inside panel (e.g., "ACKNOWLEDGE" button)
      expect(find.text('ACKNOWLEDGE'), findsOneWidget);
    });

    testWidgets('Sliding Panel closes when ACKNOWLEDGE is tapped',
        (tester) async {
      await tester.pumpWidget(createTestWidget(const CBGuideScreen()));

      // Navigate to Operatives -> Open Panel
      await tester.tap(find.text('OPERATIVES'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CBRoleIDCard).first);

      // Pump to open panel
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Panel is open
      expect(find.text('ACKNOWLEDGE'), findsOneWidget);

      // Tap ACKNOWLEDGE
      await tester.tap(find.text('ACKNOWLEDGE'));

      // Pump to close panel
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify no crash
      expect(tester.takeException(), isNull);
    });

    testWidgets('CBIndexedHandbook renders sections correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(const CBIndexedHandbook()));

      // Verify Categories exist
      expect(find.text('OVERVIEW'), findsOneWidget);
      expect(find.text('HOW TO PLAY'), findsOneWidget);
      expect(find.text('ALLIANCES'), findsOneWidget);

      // Verify content section renders (random sample text)
      expect(find.textContaining('Welcome to Blackout', findRichText: true),
          findsOneWidget);
    });
  });
}

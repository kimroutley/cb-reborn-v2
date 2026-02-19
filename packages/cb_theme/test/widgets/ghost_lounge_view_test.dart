import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows current bet and places new dead-pool bet',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CBTheme.buildTheme(CBTheme.buildColorScheme(null)),
        home: GhostLoungeView(
          aliveTargets: const [
            GhostLoungeTarget(id: 'p1', name: 'Player 1'),
          ],
          activeBets: const [
            GhostLoungeBet(
              bettorName: 'Ghost A',
              targetName: 'Player 1',
              oddsCount: 2,
            ),
          ],
          currentBetTargetName: 'Player 2',
          onPlaceBet: (_) {},
        ),
      ),
    );

    expect(find.textContaining('YOUR BET: PLAYER 2'), findsOneWidget);
    expect(find.text('Ghost A → Player 1'), findsOneWidget);

    await tester
        .tap(find.widgetWithText(CBPrimaryButton, 'CHANGE DEAD POOL BET'));
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('PLACE DEAD POOL BET'), findsOneWidget);
  });
}

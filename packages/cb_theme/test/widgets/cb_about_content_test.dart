import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Finder richTextContaining(String text) {
    return find.byWidgetPredicate(
      (widget) =>
          widget is RichText && widget.text.toPlainText().contains(text),
    );
  }

  testWidgets('CBAboutContent renders required about fields', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CBAboutContent(
            appHeading: 'CLUB BLACKOUT: REBORN',
            appSubtitle: 'PLAYER COMPANION APP',
            versionLabel: '1.0.3 (Build 13)',
            releaseDateLabel: 'Feb 18, 2026',
            creditsLabel: 'Kim, Val, Lilo, Stitch and Mushu Kyrian',
            copyrightLabel: '© 2026 Kyrian Co. All rights reserved.',
            recentBuilds: const <AppBuildUpdate>[],
          ),
        ),
      ),
    );

    expect(find.text('A game by Kyrian Co.'), findsOneWidget);
    expect(richTextContaining('Version: 1.0.3 (Build 13)'), findsOneWidget);
    expect(richTextContaining('Release Date: Feb 18, 2026'), findsOneWidget);
    expect(
      richTextContaining('Credits: Kim, Val, Lilo, Stitch and Mushu Kyrian'),
      findsOneWidget,
    );
    expect(
      richTextContaining('Copyright: © 2026 Kyrian Co. All rights reserved.'),
      findsOneWidget,
    );
  });

  testWidgets('CBAboutContent shows at most three recent builds', (tester) async {
    final builds = <AppBuildUpdate>[
      AppBuildUpdate(
        version: '1.0.3',
        buildNumber: '13',
        releaseDate: DateTime(2026, 2, 18),
        highlights: <String>['A'],
      ),
      AppBuildUpdate(
        version: '1.0.2',
        buildNumber: '12',
        releaseDate: DateTime(2026, 2, 16),
        highlights: <String>['B'],
      ),
      AppBuildUpdate(
        version: '1.0.1',
        buildNumber: '11',
        releaseDate: DateTime(2026, 2, 12),
        highlights: <String>['C'],
      ),
      AppBuildUpdate(
        version: '1.0.0',
        buildNumber: '10',
        releaseDate: DateTime(2026, 2, 10),
        highlights: <String>['D'],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CBAboutContent(
            appHeading: 'CLUB BLACKOUT: REBORN',
            appSubtitle: 'HOST CONTROL APP',
            versionLabel: '1.0.3 (Build 13)',
            releaseDateLabel: 'Feb 18, 2026',
            creditsLabel: 'Kim, Val, Lilo, Stitch and Mushu Kyrian',
            copyrightLabel: '© 2026 Kyrian Co. All rights reserved.',
            recentBuilds: builds,
          ),
        ),
      ),
    );

    expect(find.text('View latest updates'), findsOneWidget);
    await tester.tap(find.text('View latest updates'));
    await tester.pumpAndSettle();

    expect(find.textContaining('v1.0.3 (Build 13)'), findsOneWidget);
    expect(find.textContaining('v1.0.2 (Build 12)'), findsOneWidget);
    expect(find.textContaining('v1.0.1 (Build 11)'), findsOneWidget);
    expect(find.textContaining('v1.0.0 (Build 10)'), findsNothing);
  });
}

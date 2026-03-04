import 'package:cb_host/widgets/personality_picker_modal.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PersonalityPickerModal renders list of personalities',
      (tester) async {
    const selectedId = 'the_cynic';

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PersonalityPickerModal(
            selectedPersonalityId: selectedId,
            onPersonalitySelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('HOST PERSONALITY PROTOCOL'), findsOneWidget);

    expect(find.byType(CBGlassTile), findsNWidgets(hostPersonalities.length));

    for (final p in hostPersonalities) {
      expect(find.text(p.name.toUpperCase()), findsOneWidget);
      expect(find.text(p.description.toUpperCase()), findsOneWidget);
    }
  });

  testWidgets('PersonalityPickerModal highlights selected personality',
      (tester) async {
    final p = hostPersonalities.first;
    final selectedId = p.id;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PersonalityPickerModal(
            selectedPersonalityId: selectedId,
            onPersonalitySelected: (_) {},
          ),
        ),
      ),
    );

    final tileFinder =
        find.widgetWithText(CBGlassTile, p.name.toUpperCase());
    expect(tileFinder, findsOneWidget);

    final iconFinder = find.descendant(
      of: tileFinder,
      matching: find.byIcon(Icons.verified_user_rounded),
    );
    expect(iconFinder, findsOneWidget);

    final otherP = hostPersonalities.lastWhere((x) => x.id != selectedId);
    final otherTileFinder =
        find.widgetWithText(CBGlassTile, otherP.name.toUpperCase());

    final otherIconFinder = find.descendant(
      of: otherTileFinder,
      matching: find.byIcon(Icons.verified_user_rounded),
    );
    expect(otherIconFinder, findsNothing);
  });

  testWidgets('PersonalityPickerModal triggers callback on selection',
      (tester) async {
    String? selectedId;
    final initialP = hostPersonalities.first;
    final targetP = hostPersonalities[1];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: PersonalityPickerModal(
            selectedPersonalityId: initialP.id,
            onPersonalitySelected: (id) => selectedId = id,
          ),
        ),
      ),
    );

    await tester.tap(find.text(targetP.name.toUpperCase()));
    await tester.pump();

    expect(selectedId, targetP.id);
  });
}

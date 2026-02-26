import 'package:cb_host/widgets/personality_picker_modal.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PersonalityPickerModal renders list of personalities', (
    tester,
  ) async {
    const selectedId = 'the_cynic';

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(), // Mock theme
        home: Scaffold(
          body: PersonalityPickerModal(
            selectedPersonalityId: selectedId,
            onPersonalitySelected: (_) {},
          ),
        ),
      ),
    );

    // Verify title
    expect(find.text('SELECT HOST PERSONALITY'), findsOneWidget);

    // Verify all personalities are listed
    expect(find.byType(ListTile), findsNWidgets(hostPersonalities.length));

    for (final p in hostPersonalities) {
      expect(find.text(p.name), findsOneWidget);
      expect(find.text(p.description), findsOneWidget);
    }
  });

  testWidgets('PersonalityPickerModal highlights selected personality', (
    tester,
  ) async {
    // Assuming 'the_cynic' is the first personality or one of them.
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

    final tileFinder = find.widgetWithText(ListTile, p.name);
    expect(tileFinder, findsOneWidget);

    // Verify check icon is present in the selected tile
    final iconFinder = find.descendant(
      of: tileFinder,
      matching: find.byIcon(Icons.check_circle),
    );
    expect(iconFinder, findsOneWidget);

    // Verify other tiles do not have check icon
    final otherP = hostPersonalities.lastWhere((x) => x.id != selectedId);
    final otherTileFinder = find.widgetWithText(ListTile, otherP.name);

    final otherIconFinder = find.descendant(
      of: otherTileFinder,
      matching: find.byIcon(Icons.check_circle),
    );
    expect(otherIconFinder, findsNothing);
  });

  testWidgets('PersonalityPickerModal triggers callback on selection', (
    tester,
  ) async {
    String? selectedId;
    // Select one that is NOT the initially selected one
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

    await tester.tap(find.text(targetP.name));
    await tester.pump();

    expect(selectedId, targetP.id);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cb_player/widgets/profile_action_buttons.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  testWidgets('save button is disabled when canSave is false', (tester) async {
    await tester.pumpWidget(
      wrap(
        ProfileActionButtons(
          saving: false,
          canSave: false,
          canDiscard: false,
          onSave: () {},
          onDiscard: () {},
          onReload: () {},
        ),
      ),
    );

    final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveButton.onPressed, isNull);
  });

  testWidgets('save button is enabled when canSave is true', (tester) async {
    await tester.pumpWidget(
      wrap(
        ProfileActionButtons(
          saving: false,
          canSave: true,
          canDiscard: true,
          onSave: () {},
          onDiscard: () {},
          onReload: () {},
        ),
      ),
    );

    final saveButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(saveButton.onPressed, isNotNull);
  });
}

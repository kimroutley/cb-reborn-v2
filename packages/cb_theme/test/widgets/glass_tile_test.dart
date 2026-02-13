import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cb_theme/cb_theme.dart';

void main() {
  testWidgets('CBGlassTile renders correctly with standard properties',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CBGlassTile(
            title: "Standard Tile",
            content: Text("Content"),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text("STANDARD TILE"), findsOneWidget); // Title is uppercased
    expect(find.text("Content"), findsOneWidget);
  });

  testWidgets('CBGlassTile renders correctly in Prismatic mode',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CBGlassTile(
            title: "Prismatic Tile",
            content: Text("Shimmer Content"),
            isPrismatic: true,
          ),
        ),
      ),
    );

    // Verify it builds without error and finds content
    expect(find.text("PRISMATIC TILE"), findsOneWidget);
    expect(find.text("Shimmer Content"), findsOneWidget);

    // Verify AnimationController initialization didn't throw
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });
}

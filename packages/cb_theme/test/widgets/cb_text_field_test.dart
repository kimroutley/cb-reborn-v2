import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cb_theme/src/widgets.dart';

void main() {
  testWidgets('CBTextField has default length limit when maxLength is not provided', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CBTextField(),
        ),
      ),
    );

    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final TextField textField = tester.widget(textFieldFinder);

    // Verify that inputFormatters contains a LengthLimitingTextInputFormatter
    // The default limit should be 8192 as per our security fix plan
    final formatters = textField.inputFormatters;
    expect(formatters, isNotNull);

    // Check if any formatter is a LengthLimitingTextInputFormatter with correct limit
    bool foundLimiter = false;
    if (formatters != null) {
      for (final formatter in formatters) {
        if (formatter is LengthLimitingTextInputFormatter) {
          if (formatter.maxLength == 8192) {
            foundLimiter = true;
            break;
          }
        }
      }
    }

    expect(foundLimiter, isTrue, reason: 'Should have a default LengthLimitingTextInputFormatter(8192)');
  });

  testWidgets('CBTextField respects maxLength and does not add default limiter', (tester) async {
    const int testLength = 100;
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CBTextField(maxLength: testLength),
        ),
      ),
    );

    final textFieldFinder = find.byType(TextField);
    final TextField textField = tester.widget(textFieldFinder);

    expect(textField.maxLength, equals(testLength));

    // Verify that the default limiter (8192) is NOT added when maxLength is provided
    final formatters = textField.inputFormatters;

    // If inputFormatters is null, then obviously no limiter.
    // But if it's not null, check contents.
    bool foundDefaultLimiter = false;
    if (formatters != null) {
      for (final formatter in formatters) {
        if (formatter is LengthLimitingTextInputFormatter && formatter.maxLength == 8192) {
          foundDefaultLimiter = true;
        }
      }
    }
    expect(foundDefaultLimiter, isFalse, reason: 'Should NOT have default limiter when maxLength is provided');
  });

  testWidgets('CBTextField allows explicit input formatters alongside default limiter', (tester) async {
    final explicitFormatter = FilteringTextInputFormatter.digitsOnly;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CBTextField(
            inputFormatters: [explicitFormatter],
          ),
        ),
      ),
    );

    final textFieldFinder = find.byType(TextField);
    final TextField textField = tester.widget(textFieldFinder);

    final formatters = textField.inputFormatters;
    expect(formatters, contains(explicitFormatter));

    // Should ALSO have the default limiter since maxLength was null
    bool foundDefaultLimiter = false;
    if (formatters != null) {
      for (final formatter in formatters) {
        if (formatter is LengthLimitingTextInputFormatter && formatter.maxLength == 8192) {
          foundDefaultLimiter = true;
        }
      }
    }
    expect(foundDefaultLimiter, isTrue, reason: 'Should preserve explicit formatters AND add default limiter');
  });
}

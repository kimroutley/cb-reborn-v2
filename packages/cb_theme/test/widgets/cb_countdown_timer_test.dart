import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CBCountdownTimer', () {
    testWidgets('renders initial state correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CBCountdownTimer(seconds: 60),
          ),
        ),
      );

      // Verify time format
      expect(find.text('01:00'), findsOneWidget);
      // Verify label
      expect(find.text('TIME REMAINING'), findsOneWidget);

      // Verify initial color (primary)
      final container = tester.widget<Container>(
        find.byKey(const Key('cb_countdown_timer_container')),
      );
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;

      final context = tester.element(find.byType(CBCountdownTimer));
      final theme = Theme.of(context);
      expect(border.top.color, theme.colorScheme.primary);
    });

    testWidgets('updates timer every second', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CBCountdownTimer(seconds: 10),
          ),
        ),
      );

      expect(find.text('00:10'), findsOneWidget);

      // Advance 1 second
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:09'), findsOneWidget);

      // Advance another second
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:08'), findsOneWidget);
    });

    testWidgets('switches to critical state when time <= 30s', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CBCountdownTimer(seconds: 31),
          ),
        ),
      );

      final context = tester.element(find.byType(CBCountdownTimer));
      final theme = Theme.of(context);

      // Initial state > 30s
      expect(find.text('TIME REMAINING'), findsOneWidget);
      var container = tester.widget<Container>(
        find.byKey(const Key('cb_countdown_timer_container')),
      );
      var decoration = container.decoration as BoxDecoration;
      var border = decoration.border as Border;
      expect(border.top.color, theme.colorScheme.primary);

      // Advance 1 second to 30s
      await tester.pump(const Duration(seconds: 1));

      // Critical state <= 30s
      expect(find.text('TIME RUNNING OUT'), findsOneWidget);
      container = tester.widget<Container>(
        find.byKey(const Key('cb_countdown_timer_container')),
      );
      decoration = container.decoration as BoxDecoration;
      border = decoration.border as Border;
      expect(border.top.color, theme.colorScheme.error);
    });

    testWidgets('calls onComplete when timer finishes', (tester) async {
      bool completed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CBCountdownTimer(
              seconds: 2,
              onComplete: () => completed = true,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      expect(completed, isFalse);

      await tester.pump(const Duration(seconds: 1));
      expect(completed, isTrue);
    });

    testWidgets('triggers haptic feedback', (tester) async {
      final List<String> log = [];

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'HapticFeedback.vibrate') {
            log.add(methodCall.arguments.toString());
          }
          return null;
        },
      );

      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      // Start with 6 seconds
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CBCountdownTimer(seconds: 6),
          ),
        ),
      );

      // 6 -> 5 seconds (trigger lightImpact)
      await tester.pump(const Duration(seconds: 1));
      expect(log, contains('HapticFeedbackType.lightImpact'));
      log.clear();

      // 5 -> 4 seconds (trigger lightImpact)
      await tester.pump(const Duration(seconds: 1));
      expect(log, contains('HapticFeedbackType.lightImpact'));
      log.clear();

      // Skip to end
      await tester.pump(const Duration(seconds: 4));

      // 0 seconds (trigger heavyImpact)
      expect(log, contains('HapticFeedbackType.heavyImpact'));
    });

    testWidgets('respects custom color', (tester) async {
      const customColor = Colors.purple;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CBCountdownTimer(
              seconds: 10, // Critical state would be error color, but custom color should override
              color: customColor,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byKey(const Key('cb_countdown_timer_container')),
      );
      final decoration = container.decoration as BoxDecoration;
      final border = decoration.border as Border;
      expect(border.top.color, customColor);

      // Verify text color
      final text = tester.widget<Text>(find.text('00:10'));
      expect(text.style?.color, customColor);
    });
  });
}

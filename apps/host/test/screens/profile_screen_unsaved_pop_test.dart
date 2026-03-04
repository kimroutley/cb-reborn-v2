import 'package:cb_host/profile_edit_guard.dart';
import 'package:cb_host/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('profile screen renders wallet view and pops cleanly',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final navKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: navKey,
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProfileScreen(
                            currentUserResolver: () => null,
                            startInEditMode: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Profile'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Profile'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Wallet view is rendered; the refactored screen has no inline TextFields.
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(container.read(hostProfileDirtyProvider), isFalse);

    // Pop should succeed without a discard dialog since no edits were made.
    await navKey.currentState!.maybePop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(navKey.currentState!.canPop(), isFalse);
    expect(container.read(hostProfileDirtyProvider), isFalse);
  });
}

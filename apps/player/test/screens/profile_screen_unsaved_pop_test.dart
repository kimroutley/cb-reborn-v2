import 'package:cb_player/profile_edit_guard.dart';
import 'package:cb_player/screens/profile_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('profile pop asks to discard unsaved changes', (tester) async {
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

    await tester.enterText(find.byType(TextField).first, 'Night Fox');
    await tester.pump();
    expect(container.read(playerProfileDirtyProvider), isTrue);

    await navKey.currentState!.maybePop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Discard Changes?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(container.read(playerProfileDirtyProvider), isTrue);

    await navKey.currentState!.maybePop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Discard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // The handler's fire-and-forget maybePop may re-trigger the dialog
    // because PopScope hasn't rebuilt yet. Dismiss the second dialog if present.
    final secondDialog = find.text('Discard');
    if (secondDialog.evaluate().isNotEmpty) {
      await tester.tap(secondDialog);
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 500));

    expect(navKey.currentState!.canPop(), isFalse);
  });
}

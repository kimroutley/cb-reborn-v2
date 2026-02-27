import 'package:cb_host/profile_edit_guard.dart';
import 'package:cb_host/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
                          builder: (_) =>
                              ProfileScreen(
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
    await tester.pump(); // Start navigation
    await tester.pump(const Duration(seconds: 1)); // Wait
    
    // Debug: check what is on screen
    expect(find.byType(ProfileScreen), findsOneWidget);
    // Try finding by explicit type if needed, or by key if available.
    // Assuming CBTextField uses TextField internally. 
    // If not found, look for any EditableText.
    final editable = find.byType(EditableText);
    if (editable.evaluate().isEmpty) {
       // Maybe it's still loading?
       if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
         print("Still loading...");
       }
    }
    
    final textField = find.byType(TextField).first;
    expect(textField, findsOneWidget);
    await tester.enterText(textField, 'Host One');
    await tester.pump();
    expect(container.read(hostProfileDirtyProvider), isTrue);

    await navKey.currentState!.maybePop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Discard Changes?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(container.read(hostProfileDirtyProvider), isTrue);

    await navKey.currentState!.maybePop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Discard'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(navKey.currentState!.canPop(), isFalse);
    expect(container.read(hostProfileDirtyProvider), isFalse);
  });
}

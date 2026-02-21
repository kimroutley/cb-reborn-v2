import 'package:cb_host/host_destinations.dart';
import 'package:cb_host/host_navigation.dart';
import 'package:cb_host/profile_edit_guard.dart';
import 'package:cb_host/widgets/custom_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('drawer asks to discard unsaved profile changes', (tester) async {
    final lobbyLabel = hostDestinations
      .firstWhere((d) => d.destination == HostDestination.lobby)
        .label;

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(hostNavigationProvider.notifier)
        .setDestination(HostDestination.profile);
    container.read(hostProfileDirtyProvider.notifier).setDirty(true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: CustomDrawer(),
          ),
        ),
      ),
    );

    await tester.tap(find.text(lobbyLabel).first);
    await tester.pumpAndSettle();

    expect(find.text('Discard Changes?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(container.read(hostNavigationProvider), HostDestination.profile);
    expect(container.read(hostProfileDirtyProvider), isTrue);

    await tester.tap(find.text(lobbyLabel).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(container.read(hostNavigationProvider), HostDestination.lobby);
    expect(container.read(hostProfileDirtyProvider), isFalse);
  });
}

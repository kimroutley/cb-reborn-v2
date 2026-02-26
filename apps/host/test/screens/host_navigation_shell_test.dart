import 'package:cb_host/host_destinations.dart';
import 'package:cb_host/host_navigation.dart';
import 'package:cb_host/screens/host_navigation_shell.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:qr_flutter/qr_flutter.dart';

class _FakeBox extends Fake implements Box<String> {
  @override
  bool get isOpen => true;

  @override
  Iterable<dynamic> get keys => [];

  @override
  Iterable<String> get values => [];

  @override
  String? get(key, {String? defaultValue}) => null;

  @override
  bool containsKey(key) => false;
}

void main() {
  setUp(() {
    PersistenceService.initWithBoxes(_FakeBox(), _FakeBox(), _FakeBox());
  });

  testWidgets('HostNavigationShell reacts to destination provider changes', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HostNavigationShell()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('HOST COMMAND CENTER'), findsOneWidget);

    container
        .read(hostNavigationProvider.notifier)
        .setDestination(HostDestination.guides);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('THE BLACKBOOK'), findsAtLeastNWidgets(1));

    container
        .read(hostNavigationProvider.notifier)
        .setDestination(HostDestination.lobby);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.textContaining('BROADCASTING ON CODE'),
      findsAtLeastNWidgets(1),
    );
    expect(find.text('JOIN BEACON'), findsOneWidget);
    expect(find.textContaining('CLOUD LINK:'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);

    // Allow debounced persistence timer from sync mode bootstrap to settle.
    await tester.pump(const Duration(milliseconds: 600));
  });
}

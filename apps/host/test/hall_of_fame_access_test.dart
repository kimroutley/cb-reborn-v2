import 'package:cb_host/host_destinations.dart';
import 'package:cb_host/host_navigation.dart';
import 'package:cb_host/screens/home_screen.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

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

  testWidgets('Home quick action opens Hall of Fame destination', (
    WidgetTester tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.tap(find.text('VIEW HALL OF FAME'));
    await tester.pump();

    expect(container.read(hostNavigationProvider), HostDestination.hallOfFame);
  });
}

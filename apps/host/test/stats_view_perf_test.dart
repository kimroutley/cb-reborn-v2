import 'dart:convert';

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:cb_host/screens/stats_view.dart';

class FakeBox extends Fake implements Box<String> {
  final Map<dynamic, String> _data = {};

  @override
  bool get isOpen => true;

  @override
  Iterable<dynamic> get keys => _data.keys;

  @override
  Iterable<String> get values => _data.values;

  @override
  String? get(key, {String? defaultValue}) => _data[key];

  @override
  Future<void> put(key, String value) async {
    _data[key] = value;
  }

  void addRaw(dynamic key, String value) {
    _data[key] = value;
  }

  @override
  Future<int> clear() async {
    _data.clear();
    return 0;
  }
}

void main() {
  late FakeBox activeBox;
  late FakeBox recordsBox;
  late FakeBox sessionsBox;

  setUp(() {
    activeBox = FakeBox();
    recordsBox = FakeBox();
    sessionsBox = FakeBox();
    PersistenceService.initWithBoxes(activeBox, recordsBox, sessionsBox);
  });

  testWidgets('StatsView builds items lazily (optimized)',
      (WidgetTester tester) async {
    // 1. Populate recordsBox with 1000 items
    for (int i = 0; i < 1000; i++) {
      final record = GameRecord(
        id: 'game_$i',
        startedAt: DateTime.now().subtract(Duration(days: i)),
        endedAt: DateTime.now().subtract(Duration(days: i, minutes: 30)),
        winner: i % 2 == 0 ? Team.clubStaff : Team.partyAnimals,
        playerCount: 10,
        dayCount: 3,
        rolesInPlay: ['dealer', 'bouncer'],
        roster: [],
        history: [],
      );
      recordsBox.addRaw('game_$i', jsonEncode(record.toJson()));
    }

    // 2. Pump StatsView
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatsView(
            gameState: GameState(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 3. Verify ListView is using SliverChildBuilderDelegate (lazy list)
    final listViewFinder = find.byType(ListView);
    expect(listViewFinder, findsOneWidget);

    final ListView listView = tester.widget(listViewFinder);
    final delegate = listView.childrenDelegate;

    expect(delegate, isA<SliverChildBuilderDelegate>(),
        reason:
            'Should be using SliverChildBuilderDelegate (ListView.builder) for lazy loading');

    // If it is a builder, verify we can scroll and more items appear (optional, but confirms functionality)
    // But testing the delegate type is sufficient to prove the structural change.
  });
}

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:cb_logic/cb_logic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

// Helper to create a fake session record
GamesNightRecord _fakeSession({
  required String id,
  required String name,
  required int gameCount,
}) {
  return GamesNightRecord(
    id: id,
    sessionName: name,
    startedAt: DateTime.now().subtract(const Duration(days: 1)),
    endedAt: DateTime.now(),
    isActive: false,
    gameIds: List.generate(gameCount, (index) => 'game_$index'),
    playerNames: List.generate(10, (index) => 'Player $index'),
    playerGamesCount: {for (var i = 0; i < 10; i++) 'Player $i': gameCount},
  );
}

void main() {
  late Directory tempDir;
  late PersistenceService service;
  late Box<String> sessionsBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_benchmark_');
    Hive.init(tempDir.path);
    final activeBox = await Hive.openBox<String>('bench_active');
    final recordsBox = await Hive.openBox<String>('bench_records');
    sessionsBox = await Hive.openBox<String>('bench_sessions');
    service = PersistenceService.initWithBoxes(
      activeBox,
      recordsBox,
      sessionsBox,
    );
  });

  tearDown(() async {
    await service.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('Benchmark loadAllSessions with 1000 records', () async {
    // 1. Populate data
    const recordCount = 1000;
    print('Generating $recordCount session records...');

    final batch = <String, String>{};
    for (var i = 0; i < recordCount; i++) {
      final record = _fakeSession(
        id: 'session_$i',
        name: 'Session $i',
        gameCount: 5, // simulate some data volume
      );
      batch['session_$i'] = jsonEncode(record.toJson());
    }
    await sessionsBox.putAll(batch);
    print('Data populated.');

    // 2. Measure load time
    final stopwatch = Stopwatch()..start();
    final sessions = await service.loadAllSessions();
    stopwatch.stop();

    print(
      'Loaded ${sessions.length} sessions in ${stopwatch.elapsedMilliseconds}ms',
    );

    expect(sessions.length, recordCount);
  });
}

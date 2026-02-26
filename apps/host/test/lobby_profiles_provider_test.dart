import 'dart:async';

import 'package:cb_host/providers/firestore_provider.dart';
import 'package:cb_host/providers/lobby_profiles_provider.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

// ─── MOCK FIRESTORE ───

class MockFirestore extends Fake implements FirebaseFirestore {
  final Map<String, MockCollectionReference> collections = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return collections.putIfAbsent(
      collectionPath,
      () => MockCollectionReference(collectionPath),
    );
  }
}

class MockCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  final String path;
  final List<MockQuery> queries = [];

  MockCollectionReference(this.path);

  @override
  Query<Map<String, dynamic>> where(
    Object field, {
    Object? isEqualTo,
    Object? isNotEqualTo,
    Object? isLessThan,
    Object? isLessThanOrEqualTo,
    Object? isGreaterThan,
    Object? isGreaterThanOrEqualTo,
    Object? arrayContains,
    Iterable<Object?>? arrayContainsAny,
    Iterable<Object?>? whereIn,
    Iterable<Object?>? whereNotIn,
    bool? isNull,
  }) {
    final query = MockQuery(this, field: field, whereIn: whereIn);
    queries.add(query);
    return query;
  }
}

class MockQuery extends Fake implements Query<Map<String, dynamic>> {
  final MockCollectionReference parent;
  final Object field;
  final Iterable<Object?>? whereIn;
  final StreamController<QuerySnapshot<Map<String, dynamic>>> controller =
      StreamController.broadcast();

  MockQuery(this.parent, {required this.field, this.whereIn});

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    bool includeOptions = false, // Just in case
    // ignore: avoid_annotating_with_dynamic
    dynamic source,
  }) {
    return controller.stream;
  }

  void emit(List<Map<String, dynamic>> docsData) {
    final docs = docsData.map((data) {
      return MockDocumentSnapshot(data['uid'] ?? 'unknown', data);
    }).toList();
    controller.add(MockQuerySnapshot(docs));
  }
}

class MockQuerySnapshot extends Fake
    implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  MockQuerySnapshot(this.docs);
}

class MockDocumentSnapshot extends Fake
    implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> _data;

  MockDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic> data() => _data;
}

// ─── FAKE HIVE (For PersistenceService) ───

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

  @override
  Future<int> clear() async {
    _data.clear();
    return 0;
  }
}

// ignore_for_file: subtype_of_sealed_class

// ─── TESTS ───

void main() {
  late ProviderContainer container;
  late MockFirestore mockFirestore;
  late FakeBox activeBox;
  late FakeBox recordsBox;
  late FakeBox sessionsBox;

  setUp(() {
    activeBox = FakeBox();
    recordsBox = FakeBox();
    sessionsBox = FakeBox();
    PersistenceService.initWithBoxes(activeBox, recordsBox, sessionsBox);

    mockFirestore = MockFirestore();
    container = ProviderContainer(
      overrides: [firestoreProvider.overrideWithValue(mockFirestore)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('lobbyProfilesProvider fetches profiles in chunks', () async {
    // 1. Add 15 players with authUids
    final gameNotifier = container.read(gameProvider.notifier);
    for (int i = 0; i < 15; i++) {
      // Use consistent formatting for IDs to match chunk sorting
      // i=0 -> id=00, etc.
      final id = i.toString().padLeft(2, '0');
      gameNotifier.addPlayer('Player $i', authUid: 'user_$id');
    }

    // 2. Read provider (this triggers the build)
    // Use subscribe/listen to ensure stream is active
    final profileStream = container.listen(
      lobbyProfilesProvider,
      (previous, next) {},
    );

    // Allow microtasks to propagate provider creation
    await Future.microtask(() {});

    // 3. Verify queries created
    // We expect chunks of 10.
    // 15 users. 2 chunks.
    // user_00 ... user_09 (10 items)
    // user_10 ... user_14 (5 items)

    final collection = mockFirestore.collections['user_profiles'];
    expect(collection, isNotNull);
    expect(collection!.queries.length, 2);

    final query1 = collection.queries[0];
    final query2 = collection.queries[1];

    // Verify whereIn clauses
    // Note: chunking logic sorts UIDs.
    // user_00 to user_09 should be in first chunk?
    // user_00, user_01... alphabetical sort matches loop insertion order here.

    final chunk1 = query1.whereIn!.cast<String>().toList();
    final chunk2 = query2.whereIn!.cast<String>().toList();

    expect(chunk1.length, 10);
    expect(chunk2.length, 5);
    expect(chunk1.first, 'user_00');
    expect(chunk1.last, 'user_09');
    expect(chunk2.first, 'user_10');
    expect(chunk2.last, 'user_14');

    // 4. Emit data
    // Emitting maps. The provider expects docs with data.
    // The key in the result map comes from doc.id.
    // My MockDocumentSnapshot takes id and data.

    // Chunk 1 data
    query1.emit([
      {'uid': 'user_00', 'username': 'User Zero'},
      {'uid': 'user_05', 'username': 'User Five'},
    ]);

    // Chunk 2 data
    query2.emit([
      {'uid': 'user_10', 'username': 'User Ten'},
    ]);

    // Wait for stream update
    await Future.delayed(const Duration(milliseconds: 10));

    // 5. Verify result
    final asyncValue = container.read(lobbyProfilesProvider);
    expect(asyncValue.hasValue, true);
    final profiles = asyncValue.value!;

    expect(profiles.length, 3);
    expect(profiles['user_00']?['username'], 'User Zero');
    expect(profiles['user_05']?['username'], 'User Five');
    expect(profiles['user_10']?['username'], 'User Ten');
    expect(
      profiles['user_01'],
      isNull,
    ); // Was requested but not returned in snapshot

    profileStream.close();
  });

  test('lobbyProfilesProvider handles updates', () async {
    final gameNotifier = container.read(gameProvider.notifier);
    gameNotifier.addPlayer('P1', authUid: 'u1');

    final profileStream = container.listen(
      lobbyProfilesProvider,
      (previous, next) {},
    );
    await Future.microtask(() {});

    final collection = mockFirestore.collections['user_profiles'];
    final query = collection!.queries.first;

    // Initial emit
    query.emit([
      {'uid': 'u1', 'username': 'Initial'},
    ]);
    await Future.delayed(const Duration(milliseconds: 10));

    expect(
      container.read(lobbyProfilesProvider).value!['u1']!['username'],
      'Initial',
    );

    // Update emit
    query.emit([
      {'uid': 'u1', 'username': 'Updated'},
    ]);
    await Future.delayed(const Duration(milliseconds: 10));

    expect(
      container.read(lobbyProfilesProvider).value!['u1']!['username'],
      'Updated',
    );

    profileStream.close();
  });
}

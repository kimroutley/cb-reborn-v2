// ignore_for_file: subtype_of_sealed_class

import 'package:cb_comms/src/firebase_bridge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class MockWriteBatch extends Fake implements WriteBatch {
  final List<Map<String, dynamic>> operations = [];

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    operations.add({
      'type': 'set',
      'path': document.path,
      'data': data as Map<String, dynamic>,
      'options': options,
    });
  }

  @override
  Future<void> commit() async {
    // no-op
  }
}

class MockDocumentReference extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final String _path;
  final MockFirestore _firestore;

  MockDocumentReference(this._firestore, this._path);

  @override
  String get path => _path;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _firestore.directSetCalls.add({
      'path': _path,
      'data': data,
      'options': options,
    });
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return MockCollectionReference(_firestore, '$_path/$collectionPath');
  }

  @override
  DocumentReference<R> withConverter<R>(
      {required FromFirestore<R> fromFirestore,
      required ToFirestore<R> toFirestore}) {
    throw UnimplementedError();
  }
}

class MockCollectionReference extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  final MockFirestore _firestore;
  final String _path;

  MockCollectionReference(this._firestore, this._path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return MockDocumentReference(_firestore, '$_path/$path');
  }

  @override
  CollectionReference<R> withConverter<R>(
      {required FromFirestore<R> fromFirestore,
      required ToFirestore<R> toFirestore}) {
    throw UnimplementedError();
  }
}

class MockFirestore extends Fake implements FirebaseFirestore {
  final MockWriteBatch batchInstance = MockWriteBatch();
  final List<Map<String, dynamic>> directSetCalls = [];

  @override
  WriteBatch batch() => batchInstance;

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return MockCollectionReference(this, collectionPath);
  }
}

void main() {
  test('publishState optimizes writes by batching public state update',
      () async {
    final mockFirestore = MockFirestore();
    final bridge =
        FirebaseBridge(joinCode: 'TEST_CODE', firestore: mockFirestore);

    final publicState = {'phase': 'day', 'dayCount': 1};
    final privateState = {
      'player1': {'role': 'medic'},
      'player2': {'role': 'spy'},
    };

    await bridge.publishState(
      publicState: publicState,
      playerPrivateData: privateState,
    );

    // After optimization:
    // 0 direct sets (should be in batch)
    expect(mockFirestore.directSetCalls.length, 0,
        reason: 'Public state should NOT be set directly');

    // 3 batch sets (1 public + 2 private)
    expect(mockFirestore.batchInstance.operations.length, 3,
        reason: 'All updates should be batched');

    // verify public state is in batch
    final publicOp = mockFirestore.batchInstance.operations
        .firstWhere((op) => op['path'] == 'games/TEST_CODE');
    expect(publicOp['data'], publicState);
    expect(publicOp['type'], 'set');
  });
}

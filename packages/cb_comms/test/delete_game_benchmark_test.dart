// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'package:cb_comms/src/firebase_bridge.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// ----------------------------------------------------------------------
// Mock Implementation (Manual)
// ----------------------------------------------------------------------

class MockFirestore extends Fake implements FirebaseFirestore {
  final Map<String, List<DocumentSnapshot<Map<String, dynamic>>>> _collections = {};

  // Track total commits
  int totalCommits = 0;
  int totalDeletes = 0;

  void seedCollection(String path, int count) {
    final docs = <DocumentSnapshot<Map<String, dynamic>>>[];
    for (int i = 0; i < count; i++) {
      docs.add(MockDocumentSnapshot(this, path)); // Pass 'this'
    }
    _collections[path] = docs;
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return MockCollectionReference(this, collectionPath);
  }

  @override
  DocumentReference<Map<String, dynamic>> doc(String documentPath) {
    return MockDocumentReference(this, documentPath);
  }

  @override
  WriteBatch batch() {
    return TrackedMockWriteBatch(this);
  }
}

class MockCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  final MockFirestore _firestore;
  final String _path;

  MockCollectionReference(this._firestore, this._path);

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final docs = _firestore._collections[_path] ?? [];
    return MockQuerySnapshot(docs);
  }

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return MockDocumentReference(_firestore, '$_path/${path ?? "new_doc"}');
  }
}

class MockDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  final MockFirestore _firestore;
  final String _path;

  MockDocumentReference(this._firestore, this._path);

  @override
  Future<void> delete() async {
    // Single delete
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return MockCollectionReference(_firestore, '$_path/$collectionPath');
  }
}

class MockQuerySnapshot extends Fake implements QuerySnapshot<Map<String, dynamic>> {
  final List<DocumentSnapshot<Map<String, dynamic>>> _docs;

  MockQuerySnapshot(this._docs);

  @override
  List<QueryDocumentSnapshot<Map<String, dynamic>>> get docs =>
      _docs.map((d) => d as QueryDocumentSnapshot<Map<String, dynamic>>).toList();

  @override
  int get size => _docs.length;
}

class MockDocumentSnapshot extends Fake implements QueryDocumentSnapshot<Map<String, dynamic>> {
  final MockFirestore _firestore;
  final String _path;

  MockDocumentSnapshot(this._firestore, this._path);

  @override
  String get id => 'doc_id';

  @override
  bool get exists => true;

  @override
  Map<String, dynamic> data() => {}; // Non-nullable

  @override
  dynamic get(Object field) => null;

  @override
  DocumentReference<Map<String, dynamic>> get reference =>
      MockDocumentReference(_firestore, _path);
}

class TrackedMockWriteBatch extends Fake implements WriteBatch {
  final MockFirestore _firestore;
  int _operationCount = 0;

  TrackedMockWriteBatch(this._firestore);

  @override
  void delete(DocumentReference document) {
    _operationCount++;
    _firestore.totalDeletes++;
  }

  @override
  void set<T>(DocumentReference<T> document, T data, [SetOptions? options]) {
    _operationCount++;
  }

  @override
  void update(DocumentReference document, Map<String, dynamic> data) {
    _operationCount++;
  }

  @override
  Future<void> commit() async {
    if (_operationCount > 500) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Batch write exceeds the limit of 500 operations (mocked: $_operationCount).',
      );
    }
    _firestore.totalCommits++;
    _operationCount = 0;
  }
}

// ----------------------------------------------------------------------
// Tests
// ----------------------------------------------------------------------

void main() {
  test('deleteGame succeeds when total docs > 500 by chunking batches', () async {
    final firestore = MockFirestore();

    // Seed data: 200 + 200 + 200 = 600 docs
    firestore.seedCollection('games/test_code/joins', 200);
    firestore.seedCollection('games/test_code/actions', 200);
    firestore.seedCollection('games/test_code/private_state', 200);

    final bridge = FirebaseBridge(joinCode: 'test_code', firestore: firestore);

    await bridge.deleteGame();

    // With 600 items and limit 500:
    // The optimized implementation should process in chunks of 500.
    // Batch 1: 500 items -> commit()
    // Batch 2: 100 items -> commit()
    // Total commits: 2

    expect(firestore.totalCommits, 2, reason: "Should commit twice for 600 items (500 + 100)");
  });
}

import 'dart:async';

import 'package:cb_comms/cb_comms.dart'; // Ensure exported
import 'package:cb_comms/src/game_session_manager.dart'; // Direct import for internal access if needed
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mocks
class MockConnectivityPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements ConnectivityPlatform {
  List<ConnectivityResult> _connectivity = [ConnectivityResult.wifi];
  final _controller = StreamController<List<ConnectivityResult>>.broadcast();

  void setConnectivity(List<ConnectivityResult> connectivity) {
    _connectivity = connectivity;
    _controller.add(connectivity);
  }

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return _connectivity;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _controller.stream;
}

class FakeFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _data = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return FakeCollectionReference(this, collectionPath);
  }

  // Helper for tests
  void setDoc(String path, Map<String, dynamic> data) {
    _data[path] = data;
  }

  Map<String, dynamic>? getDoc(String path) {
    return _data[path];
  }
}

class FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  final FakeFirestore _firestore;
  final String _path;

  FakeCollectionReference(this._firestore, this._path);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return FakeDocumentReference(_firestore, '$_path/$path');
  }
}

class FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  final FakeFirestore _firestore;
  final String _path;

  FakeDocumentReference(this._firestore, this._path);

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    final data = _firestore.getDoc(_path);
    return FakeDocumentSnapshot(_path, data);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _firestore.setDoc(_path, data);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
     return FakeCollectionReference(_firestore, '$_path/$collectionPath');
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) {
    // Return a stream that emits current state. Ideally we would update stream on set(), but for now just one emission is enough for initialization.
    final data = _firestore.getDoc(_path);
    return Stream.value(FakeDocumentSnapshot(_path, data));
  }
}

class FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final String _path;
  final Map<String, dynamic>? _data;

  FakeDocumentSnapshot(this._path, this._data);

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic get(Object field) => _data?[field];
}

class FakeFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => FakeUser(uid: 'test_user_id');
}

class FakeUser extends Fake implements User {
  @override
  final String uid;

  FakeUser({required this.uid});
}

class MockFirebaseBridge extends Fake implements FirebaseBridge {
  final List<Map<String, dynamic>> sentActions = [];
  bool shouldThrow = false;

  @override
  Future<void> sendAction({required String stepId, required String playerId, String? targetId}) async {
    if (shouldThrow) {
      throw Exception("Network Error");
    }
    sentActions.add({
      'stepId': stepId,
      'playerId': playerId,
      'targetId': targetId,
    });
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> subscribeToGame() {
    // Return empty stream or valid snapshot stream
    return Stream.value(FakeDocumentSnapshot('games/test_game', {}));
  }

  @override
  DocumentReference<Map<String, dynamic>> playerPrivateDoc(String playerId) {
      // Return a fake doc reference that does nothing on set
      return FakeDocumentReference(FakeFirestore(), 'games/test_game/private_state/$playerId');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GameSessionManager manager;
  late MockConnectivityPlatform mockConnectivity;
  late FakeFirestore fakeFirestore;
  late FakeFirebaseAuth fakeAuth;
  late MockFirebaseBridge mockBridge;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockConnectivity = MockConnectivityPlatform();
    ConnectivityPlatform.instance = mockConnectivity;

    fakeFirestore = FakeFirestore();
    fakeAuth = FakeFirebaseAuth();
    mockBridge = MockFirebaseBridge();

    // Seed initial session data
    fakeFirestore.setDoc('sessions/test_game', {'hostId': 'host_id', 'status': 'lobby'});

    manager = GameSessionManager(
      firestore: fakeFirestore,
      auth: fakeAuth,
      bridgeFactory: (code, store) => mockBridge,
    );
  });

  tearDown(() {
    manager.disconnect();
  });

  test('sendAction sends immediately when online', () async {
    await manager.joinSession('test_game', 'Test Player');

    await manager.sendAction(stepId: 'step1', targetId: 'target1');

    expect(mockBridge.sentActions.length, 1);
    expect(mockBridge.sentActions.first['stepId'], 'step1');
    expect(mockBridge.sentActions.first['targetId'], 'target1');
  });

  test('sendAction queues when offline', () async {
    await manager.joinSession('test_game', 'Test Player');

    // Simulate offline
    mockConnectivity.setConnectivity([ConnectivityResult.none]);

    await manager.sendAction(stepId: 'step2', targetId: 'target2');

    // Should NOT be sent to bridge yet
    expect(mockBridge.sentActions.length, 0);

    // Simulate online
    mockConnectivity.setConnectivity([ConnectivityResult.wifi]);

    // Give some time for queue processing
    await Future.delayed(Duration(milliseconds: 100));

    expect(mockBridge.sentActions.length, 1);
    expect(mockBridge.sentActions.first['stepId'], 'step2');
    expect(mockBridge.sentActions.first['targetId'], 'target2');
  });

  test('sendAction queues when bridge throws error', () async {
      await manager.joinSession('test_game', 'Test Player');
      mockBridge.shouldThrow = true;

      await manager.sendAction(stepId: 'step3', targetId: 'target3');

      // Should not be in sentActions due to error
      expect(mockBridge.sentActions.length, 0);

      // Verify it queues by fixing the error and simulating queue processing
      mockBridge.shouldThrow = false;

      // Trigger queue processing by toggling connectivity
      mockConnectivity.setConnectivity([ConnectivityResult.none]); // offline
      mockConnectivity.setConnectivity([ConnectivityResult.wifi]); // back online

      await Future.delayed(Duration(milliseconds: 100));

      expect(mockBridge.sentActions.length, 1);
      expect(mockBridge.sentActions.first['stepId'], 'step3');
  });

  test('sendAction does nothing when bridge is null (not joined)', () async {
      // Not joined yet
      await manager.sendAction(stepId: 'step4', targetId: 'target4');

      // Should not crash, and should not send anything
      expect(mockBridge.sentActions.length, 0);
  });

}

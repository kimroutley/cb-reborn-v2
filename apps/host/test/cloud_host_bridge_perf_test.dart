import 'package:cb_comms/cb_comms.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cb_host/cloud_host_bridge.dart';

// Dummy Firestore to satisfy the constructor requirement.
class _DummyFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockFirebaseBridge extends FirebaseBridge {
  int publishCount = 0;

  MockFirebaseBridge() : super(joinCode: 'TEST', firestore: _DummyFirestore());

  @override
  Future<void> publishState({
    required Map<String, dynamic> publicState,
    required Map<String, Map<String, dynamic>> playerPrivateData,
  }) async {
    publishCount++;
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> subscribeToJoinRequests() {
    return const Stream.empty();
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> subscribeToActions() {
    return const Stream.empty();
  }
}

void main() {
  test('CloudHostBridge baseline performance test', () async {
    final container = ProviderContainer(
      overrides: [
        cloudHostBridgeProvider.overrideWith((ref) {
          final bridge = CloudHostBridge(ref);

          // Replicate the listeners defined in the original provider to simulate the environment.
          ref.listen(gameProvider, (prev, next) {
            if (bridge.isRunning) {
              bridge.publishState();
            }
          });

          ref.listen(sessionProvider, (prev, next) {
            if (bridge.isRunning) {
              bridge.publishState();
            }
          });

          ref.onDispose(() {
            bridge.stop(updateLinkState: false);
          });

          return bridge;
        }),
      ],
    );
    addTearDown(container.dispose);

    final bridge = container.read(cloudHostBridgeProvider);
    final mockFirebase = MockFirebaseBridge();
    bridge.debugFirebase = mockFirebase;

    await bridge.start();

    // Initial publish happens in start()
    expect(mockFirebase.publishCount, 1,
        reason: 'Should publish once on start');

    // Trigger an irrelevant change: emitSystemToFeed updates feedEvents but not public state
    container
        .read(gameProvider.notifier)
        .emitSystemToFeed('Test System Message');

    // Wait for microtasks (Riverpod updates)
    await Future.microtask(() {});

    // OPTIMIZED BEHAVIOR: It should NOT publish.
    expect(mockFirebase.publishCount, 1,
        reason: 'Should NOT publish on feed update (optimized)');

    // Trigger a relevant change: add players (updates players list)
    container.read(gameProvider.notifier).addPlayer('P1');
    container.read(gameProvider.notifier).addPlayer('P2');
    container.read(gameProvider.notifier).addPlayer('P3');
    container.read(gameProvider.notifier).addPlayer('P4');

    // Wait for updates
    await Future.microtask(() {});

    // 1 (start) + 0 (feed) + 4 (adds) = 5
    expect(mockFirebase.publishCount, 5,
        reason: 'Should publish on each player add');

    // Start game -> advancePhase -> publish
    container.read(gameProvider.notifier).startGame();
    await Future.microtask(() {});

    // 5 + 1 (startGame) = 6
    expect(mockFirebase.publishCount, 6, reason: 'Should publish on startGame');
  });
}

import 'package:cb_comms/cb_comms.dart';
import 'package:cb_player/player_bridge.dart';
import 'package:cb_player/player_stats.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock PlayerClient
class MockPlayerClient extends PlayerClient {
  MockPlayerClient({super.onMessage, super.onConnectionChanged});

  final List<GameMessage> sentMessages = [];
  bool _isConnected = false;

  @override
  PlayerConnectionState get state => _isConnected
      ? PlayerConnectionState.connected
      : PlayerConnectionState.disconnected;

  @override
  Future<void> connect(String url) async {
    _isConnected = true;
    // Simulate async connection
    await Future.delayed(Duration.zero);
    onConnectionChanged?.call(PlayerConnectionState.connected);
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    onConnectionChanged?.call(PlayerConnectionState.disconnected);
  }

  @override
  void send(GameMessage message) {
    sentMessages.add(message);
  }

  // Override these to ensure they use our `send` method even if base implementation changes
  @override
  void joinWithCode(String code, {String? playerName, String? uid}) {
    send(
      GameMessage.playerJoin(joinCode: code, playerName: playerName, uid: uid),
    );
  }

  @override
  void claimPlayer(String playerId) {
    send(GameMessage.playerClaim(playerId: playerId));
  }

  @override
  void vote({required String voterId, required String targetId}) {
    send(GameMessage.playerVote(voterId: voterId, targetId: targetId));
  }

  @override
  void leave(String playerId) {
    send(GameMessage.playerLeave(playerId: playerId));
  }

  void simulateMessage(GameMessage message) {
    onMessage?.call(message);
  }
}

// Mock PlayerStatsNotifier
class MockPlayerStatsNotifier extends PlayerStatsNotifier {
  @override
  PlayerStats build() {
    return const PlayerStats(playerId: 'mock');
  }
}

void main() {
  late MockPlayerClient mockClient;
  late ProviderContainer container;

  setUp(() {
    // Reset the factory before each test
    mockClient = MockPlayerClient();
    PlayerBridge.mockClientFactory = ({onMessage, onConnectionChanged}) {
      // We must attach the callbacks to our reused mock instance
      // But MockPlayerClient constructor takes them.
      // Since the factory creates a NEW client, we need a way to return OUR mock.
      // But we also need to update the callbacks on our mock because
      // PlayerBridge passes new closures.

      // Since PlayerClient stores callbacks in final fields (in base class),
      // we might need to recreate the mock or update it.
      // Wait, PlayerClient fields `onMessage` and `onConnectionChanged` are final?
      // Let's check.
      // "final void Function(GameMessage message)? onMessage;"
      // Yes. So we must create a new mock or use a wrapper.

      // Better approach: Create a new mock in the factory,
      // but expose it so the test can access it.

      final client = MockPlayerClient(
        onMessage: onMessage,
        onConnectionChanged: onConnectionChanged,
      );
      mockClient = client; // Capture the latest client created
      return client;
    };

    container = ProviderContainer(
      overrides: [
        playerStatsProvider.overrideWith(() => MockPlayerStatsNotifier()),
        // We can use the real RoomEffectsNotifier as it has no external deps
      ],
    );
  });

  tearDown(() {
    PlayerBridge.mockClientFactory = null;
    container.dispose();
  });

  group('StepSnapshot.isVote', () {
    test('is true for unscoped day vote id', () {
      const step = StepSnapshot(
        id: 'day_vote',
        title: 'Vote',
        readAloudText: 'Vote now',
      );

      expect(step.isVote, isTrue);
    });

    test('is true for scoped day vote id', () {
      const step = StepSnapshot(
        id: 'day_vote_3',
        title: 'Vote',
        readAloudText: 'Vote now',
      );

      expect(step.isVote, isTrue);
    });

    test('is false for unrelated id', () {
      const step = StepSnapshot(
        id: 'dealer_act_alice_3',
        title: 'Dealer Action',
        readAloudText: 'Choose target',
      );

      expect(step.isVote, isFalse);
    });
  });

  test('Initial state is disconnected', () {
    final bridge = container.read(playerBridgeProvider);
    expect(bridge.isConnected, isFalse);
    expect(bridge.phase, 'lobby');
  });

  test('Connect updates state', () async {
    final notifier = container.read(playerBridgeProvider.notifier);

    await notifier.connect('ws://test');

    expect(container.read(playerBridgeProvider).isConnected, isTrue);
    expect(mockClient._isConnected, isTrue);
  });

  test('Disconnect updates state', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');
    expect(container.read(playerBridgeProvider).isConnected, isTrue);

    await notifier.disconnect();

    // State is reset to initial
    expect(container.read(playerBridgeProvider).isConnected, isFalse);
    expect(mockClient._isConnected, isFalse);
  });

  test('Join sends correct message', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    notifier.joinWithCode('CODE123');

    expect(mockClient.sentMessages, isNotEmpty);
    final msg = mockClient.sentMessages.last;
    expect(msg.type, 'player_join');
    expect(msg.payload['joinCode'], 'CODE123');
  });

  test('joinGame includes playerName in join payload', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    await notifier.joinGame('CODE123', 'Alice');

    expect(mockClient.sentMessages, isNotEmpty);
    final msg = mockClient.sentMessages.last;
    expect(msg.type, 'player_join');
    expect(msg.payload['joinCode'], 'CODE123');
    expect(msg.payload['playerName'], 'Alice');
  });

  test('Claim sends correct message', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    await notifier.claimPlayer('player1');

    expect(mockClient.sentMessages, isNotEmpty);
    final msg = mockClient.sentMessages.last;
    expect(msg.type, 'player_claim');
    expect(msg.payload['playerId'], 'player1');
  });

  test('Vote sends correct message', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    await notifier.vote(voterId: 'p1', targetId: 'p2');

    expect(mockClient.sentMessages, isNotEmpty);
    final msg = mockClient.sentMessages.last;
    expect(msg.type, 'player_vote');
    expect(msg.payload['voterId'], 'p1');
    expect(msg.payload['targetId'], 'p2');
  });

  test('Send Action sends correct message', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    await notifier.sendAction(
      stepId: 'step1',
      targetId: 'target1',
      voterId: 'voter1',
    );

    expect(mockClient.sentMessages, isNotEmpty);
    final msg = mockClient.sentMessages.last;
    expect(msg.type, 'player_action');
    expect(msg.payload['stepId'], 'step1');
    expect(msg.payload['targetId'], 'target1');
    expect(msg.payload['voterId'], 'voter1');
  });

  test('Handles state_sync message', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    final stateSyncMsg = GameMessage.stateSync(
      phase: 'night',
      dayCount: 1,
      players: [
        {'id': 'p1', 'name': 'Alice', 'roleId': 'villager'},
      ],
      currentStep: {'id': 'step1', 'title': 'Night'},
      eyesOpen: false,
    );

    mockClient.simulateMessage(stateSyncMsg);

    final state = container.read(playerBridgeProvider);
    expect(state.phase, 'night');
    expect(state.dayCount, 1);
    expect(state.players.length, 1);
    expect(state.players.first.name, 'Alice');
    expect(state.currentStep?.id, 'step1');
    expect(state.eyesOpen, isFalse);
  });

  test('Handles join_response accepted', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    mockClient.simulateMessage(GameMessage.joinCodeResponse(accepted: true));

    final state = container.read(playerBridgeProvider);
    expect(state.joinAccepted, isTrue);
    expect(state.joinError, isNull);
  });

  test(
    'state_sync lobby empty players does not reset joinAccepted after accepted join_response',
    () async {
      final notifier = container.read(playerBridgeProvider.notifier);
      await notifier.connect('ws://test');

      mockClient.simulateMessage(GameMessage.joinCodeResponse(accepted: true));
      expect(container.read(playerBridgeProvider).joinAccepted, isTrue);

      mockClient.simulateMessage(
        GameMessage.stateSync(
          phase: 'lobby',
          dayCount: 0,
          players: const [],
          claimedPlayerIds: const [],
          roleConfirmedPlayerIds: const [],
        ),
      );

      expect(container.read(playerBridgeProvider).joinAccepted, isTrue);
    },
  );

  test('Handles join_response rejected', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    mockClient.simulateMessage(
      GameMessage.joinCodeResponse(accepted: false, error: 'Invalid Code'),
    );

    final state = container.read(playerBridgeProvider);
    expect(state.joinAccepted, isFalse);
    expect(state.joinError, 'Invalid Code');
  });

  test('Handles claim_response success', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    // First populate players so we can claim one
    mockClient.simulateMessage(
      GameMessage.stateSync(
        phase: 'lobby',
        dayCount: 0,
        players: [
          {'id': 'p1', 'name': 'Alice', 'roleId': 'villager'},
        ],
      ),
    );

    mockClient.simulateMessage(
      GameMessage.claimResponse(success: true, playerId: 'p1'),
    );

    final state = container.read(playerBridgeProvider);
    expect(state.claimedPlayerIds, contains('p1'));
    expect(state.myPlayerId, 'p1');
    expect(state.myPlayerSnapshot?.name, 'Alice');
    expect(state.claimError, isNull);
  });

  test('Handles claim_response failure', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    mockClient.simulateMessage(GameMessage.claimResponse(success: false));

    final state = container.read(playerBridgeProvider);
    expect(state.claimError, 'Could not claim player');
  });

  test('Handles player_kicked (self)', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    // Setup: claim a player
    mockClient.simulateMessage(
      GameMessage.stateSync(
        phase: 'lobby',
        dayCount: 0,
        players: [
          {'id': 'p1', 'name': 'Alice', 'roleId': 'villager'},
        ],
      ),
    );
    mockClient.simulateMessage(
      GameMessage.claimResponse(success: true, playerId: 'p1'),
    );

    expect(container.read(playerBridgeProvider).myPlayerId, 'p1');

    // Kick self
    mockClient.simulateMessage(GameMessage.playerKicked(playerId: 'p1'));

    final state = container.read(playerBridgeProvider);
    expect(state.myPlayerId, isNull);
    expect(state.claimedPlayerIds, isEmpty);
    expect(state.kickedMessage, isNotNull);
  });

  test('Reconnection sends player_reconnect if previously claimed', () async {
    final notifier = container.read(playerBridgeProvider.notifier);
    await notifier.connect('ws://test');

    // Claim a player
    mockClient.simulateMessage(
      GameMessage.stateSync(
        phase: 'lobby',
        dayCount: 0,
        players: [
          {'id': 'p1', 'name': 'Alice', 'roleId': 'villager'},
        ],
      ),
    );
    mockClient.simulateMessage(
      GameMessage.claimResponse(success: true, playerId: 'p1'),
    );

    // Simulate disconnection
    // Since we can't easily trigger the client's internal reconnect logic from outside
    // without more complex mocking, we will manually trigger the callback on the bridge.
    // The bridge passes a callback to the client. We need to invoke that callback.

    // However, our MockPlayerClient doesn't expose the callbacks once passed to constructor
    // unless we saved them.

    // In our factory setup:
    // final client = MockPlayerClient(onMessage: onMessage, onConnectionChanged: onConnectionChanged);
    // So the mock instance HAS the callbacks.

    // Simulate disconnect
    mockClient.onConnectionChanged?.call(PlayerConnectionState.reconnecting);

    // Simulate reconnect
    mockClient.onConnectionChanged?.call(PlayerConnectionState.connected);

    // Check if reconnect message was sent
    final reconnectMsgs = mockClient.sentMessages.where(
      (m) => m.type == 'player_reconnect',
    );
    expect(reconnectMsgs, isNotEmpty);
    expect(reconnectMsgs.last.payload['claimedPlayerIds'], contains('p1'));
  });
}

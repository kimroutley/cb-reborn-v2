import 'dart:io';

import 'package:cb_comms/cb_comms.dart';
import 'package:cb_host/host_bridge.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Mock WebSocket
class MockWebSocket extends Fake implements WebSocket {
  @override
  void add(dynamic data) {}
}

// Mock HostServer
class MockHostServer implements HostServer {
  // Callbacks
  @override
  void Function(WebSocket client)? onConnect;
  @override
  void Function(WebSocket client)? onDisconnect;
  @override
  void Function(GameMessage message, WebSocket sender)? onMessage;

  // State
  bool _running = false;
  final List<WebSocket> _clients = [];
  final Map<WebSocket, String> _socketToPlayer = {};

  // For verifying calls
  final List<GameMessage> broadcastedMessages = [];
  final Map<WebSocket, List<GameMessage>> sentMessages = {};

  bool get isRunning => _running;

  @override
  int get port => 8080;

  @override
  int get clientCount => _clients.length;

  @override
  List<WebSocket> get clients => List.unmodifiable(_clients);

  @override
  Map<WebSocket, String> get socketMap => Map.unmodifiable(_socketToPlayer);

  @override
  Future<List<String>> getLocalIps() async => ['192.168.1.100'];

  @override
  Future<void> start() async {
    _running = true;
  }

  @override
  Future<void> stop() async {
    _running = false;
  }

  @override
  void broadcast(GameMessage message) {
    broadcastedMessages.add(message);
  }

  @override
  void sendTo(WebSocket client, GameMessage message) {
    sentMessages.putIfAbsent(client, () => []).add(message);
  }

  @override
  void registerPlayer(WebSocket socket, String playerId) {
    _socketToPlayer[socket] = playerId;
  }

  @override
  String? playerIdForSocket(WebSocket socket) {
    return _socketToPlayer[socket];
  }

  @override
  Set<String> get connectedPlayerIds => _socketToPlayer.values.toSet();

  @override
  void pingAll() {}

  // Helpers for testing
  void simulateConnect(WebSocket socket) {
    _clients.add(socket);
    onConnect?.call(socket);
  }

  void simulateDisconnect(WebSocket socket) {
    _clients.remove(socket);
    _socketToPlayer.remove(socket);
    onDisconnect?.call(socket);
  }

  void simulateMessage(GameMessage message, WebSocket sender) {
    onMessage?.call(message, sender);
  }
}

void main() {
  group('HostBridge', () {
    late ProviderContainer container;
    late MockHostServer mockServer;
    late HostBridge bridge;

    setUp(() {
      mockServer = MockHostServer();
      container = ProviderContainer(
        overrides: [
          hostServerProvider.overrideWithValue(mockServer),
        ],
      );
      // We read the provider to instantiate the bridge
      bridge = container.read(hostBridgeProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is correct', () {
      expect(bridge.isRunning, isFalse);
      expect(bridge.clientCount, 0);
      expect(bridge.port, 8080);
    });

    test('start and stop work', () async {
      await bridge.start();
      expect(bridge.isRunning, isTrue);
      expect(mockServer.isRunning, isTrue);

      await bridge.stop();
      expect(bridge.isRunning, isFalse);
      expect(mockServer.isRunning, isFalse);
    });

    test('broadcast calls server broadcast', () async {
      await bridge.start();
      final msg = GameMessage.ping();
      bridge.broadcast(msg);
      expect(mockServer.broadcastedMessages, contains(msg));
    });

    test('handles player_join correctly', () async {
      await bridge.start();
      final socket = MockWebSocket();
      mockServer.simulateConnect(socket);

      // Reset captured messages
      mockServer.sentMessages.clear();
      mockServer.broadcastedMessages.clear();

      // Get correct join code
      final joinCode = container.read(sessionProvider).joinCode;

      final msg = GameMessage.playerJoin(joinCode: joinCode);
      mockServer.simulateMessage(msg, socket);

      // Verify response sent
      expect(mockServer.sentMessages[socket], isNotEmpty);
      final response = mockServer.sentMessages[socket]!
          .firstWhere((m) => m.type == 'join_response');
      expect(response.payload['accepted'], isTrue);

      // Verify state broadcasted to all (via _broadcastState which uses sendTo for each client)
      // Since _broadcastState iterates over clients and calls sendTo, we should see a state_sync message
      final stateSync = mockServer.sentMessages[socket]!
          .firstWhere((m) => m.type == 'state_sync');
      expect(stateSync, isNotNull);
    });

    test(
        'player_join with playerName adds roster entry once and repeated join with same uid does not duplicate',
        () async {
      await bridge.start();
      final socket = MockWebSocket();
      mockServer.simulateConnect(socket);

      final joinCode = container.read(sessionProvider).joinCode;

      mockServer.simulateMessage(
        GameMessage.playerJoin(
          joinCode: joinCode,
          playerName: 'Alice',
          uid: 'uid-123',
        ),
        socket,
      );

      var game = container.read(gameProvider);
      expect(game.players.where((p) => p.authUid == 'uid-123').length, 1);

      mockServer.simulateMessage(
        GameMessage.playerJoin(
          joinCode: joinCode,
          playerName: 'Alice Again',
          uid: 'uid-123',
        ),
        socket,
      );

      game = container.read(gameProvider);
      expect(game.players.where((p) => p.authUid == 'uid-123').length, 1);
    });

    test('handles player_claim correctly', () async {
      await bridge.start();
      final socket = MockWebSocket();
      mockServer.simulateConnect(socket);

      final msg = GameMessage.playerClaim(playerId: 'player1');
      mockServer.simulateMessage(msg, socket);

      // Verify response sent
      expect(mockServer.sentMessages[socket], isNotEmpty);
      final response = mockServer.sentMessages[socket]!
          .firstWhere((m) => m.type == 'claim_response');
      expect(response.payload['success'], isTrue);
      expect(response.payload['playerId'], 'player1');

      // Verify session updated
      final session = container.read(sessionProvider);
      expect(session.claimedPlayerIds, contains('player1'));

      // Verify player registered in server
      expect(mockServer.socketMap[socket], 'player1');
    });

    test('handles player_vote correctly', () async {
      await bridge.start();

      final gameNotifier = container.read(gameProvider.notifier);
      expect(gameNotifier.loadTestGameSandbox(), isTrue);

      // Deterministically advance to first day vote step.
      while (container.read(gameProvider).phase.name == 'setup') {
        gameNotifier.advancePhase();
      }
      while (container.read(gameProvider).phase.name == 'night') {
        gameNotifier.advancePhase();
      }

      expect(container.read(gameProvider).phase.name, 'day');

      var currentStepId = container.read(gameProvider).currentStep?.id;
      while (currentStepId != null &&
          !currentStepId.startsWith('day_vote') &&
          container.read(gameProvider).phase.name == 'day') {
        gameNotifier.advancePhase();
        currentStepId = container.read(gameProvider).currentStep?.id;
      }

      expect(currentStepId, isNotNull);
      expect(currentStepId!.startsWith('day_vote'), isTrue);

      final players = container
          .read(gameProvider)
          .players
          .where((p) => p.isAlive)
          .toList();
      final alice = players.first;
      final bob = players.firstWhere((p) => p.id != alice.id);

      final socket = MockWebSocket();
      mockServer.simulateConnect(socket);

      // Simulate vote
      final msg = GameMessage.playerVote(voterId: alice.id, targetId: bob.id);
      mockServer.simulateMessage(msg, socket);

      // Verify game state updated
      final game = container.read(gameProvider);
      expect(game.dayVotesByVoter[alice.id], bob.id);
      expect(game.dayVoteTally[bob.id], 1);
    });

    test('handles ghost_chat correctly', () async {
      await bridge.start();

      // Setup players
      final gameNotifier = container.read(gameProvider.notifier);
      gameNotifier.addPlayer('Alice');
      gameNotifier.addPlayer('Bob');

      // Kill Alice so she can chat as ghost
      final players = container.read(gameProvider).players;
      final alice = players.firstWhere((p) => p.name == 'Alice');
      gameNotifier.forceKillPlayer(alice.id);

      final socket = MockWebSocket();
      mockServer.simulateConnect(socket);
      mockServer.registerPlayer(socket, alice.id); // Alice is on this socket

      final msg = GameMessage.ghostChat(playerId: alice.id, message: 'Boo!');
      mockServer.simulateMessage(msg, socket);

      // Verify message added to private messages
      final game = container.read(gameProvider);
      expect(game.privateMessages[alice.id], contains(contains('Boo!')));

      // Verify message broadcasted to dead players (which is just Alice in this case)
      expect(mockServer.sentMessages[socket], isNotEmpty);
      final chatMsg = mockServer.sentMessages[socket]!
          .firstWhere((m) => m.type == 'ghost_chat');
      expect(chatMsg.payload['message'], 'Boo!');
    });
  });
}

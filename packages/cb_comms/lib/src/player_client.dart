import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'game_message.dart';
import 'firebase_bridge.dart'; // Import BridgeError if defined there, or move to common

/// Represents a WebSocket specific error.
class SocketError extends BridgeError {
  SocketError({required super.message, super.code, super.originalError});
}

/// WebSocket client running on the Player device.
///
/// Connects to `ws://<host-ip>:<port>` and receives state updates.
/// Automatically reconnects on disconnection (resilient lobby).
class PlayerClient {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  String? _url;
  bool _intentionalClose = false;

  // Stream for broadcasting errors to the UI
  final _errorController = StreamController<BridgeError>.broadcast();
  Stream<BridgeError> get errors => _errorController.stream;

  /// Called when a message arrives from the host.
  final void Function(GameMessage message)? onMessage;

  /// Called when connection state changes.
  final void Function(PlayerConnectionState state)? onConnectionChanged;

  PlayerClient({this.onMessage, this.onConnectionChanged});

  void dispose() {
    _errorController.close();
    disconnect();
  }

  /// Current connection state.
  PlayerConnectionState _state = PlayerConnectionState.disconnected;
  PlayerConnectionState get state => _state;

  void _setState(PlayerConnectionState newState) {
    if (_state == newState) return;
    _state = newState;
    onConnectionChanged?.call(newState);
  }

  /// Connect to the Host server.
  Future<void> connect(String url) async {
    _url = url;
    _intentionalClose = false;
    _setState(PlayerConnectionState.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      await _channel!.ready;
      _setState(PlayerConnectionState.connected);

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final message = GameMessage.fromJson(data as String);

            // Auto-respond to ping
            if (message.type == 'ping') {
              send(GameMessage.pong());
              return;
            }

            onMessage?.call(message);
          } catch (e) {
            debugPrint('[PlayerClient] Bad message: $e');
          }
        },
        onDone: () {
          debugPrint('[PlayerClient] Disconnected (onDone)');
          _setState(PlayerConnectionState.disconnected);
          if (!_intentionalClose) {
            _errorController.add(SocketError(
              message: 'Connection lost. Reconnecting...',
              code: 'socket_closed',
            ));
            _scheduleReconnect();
          }
        },
        onError: (error) {
          debugPrint('[PlayerClient] Error: $error');
          _setState(PlayerConnectionState.disconnected);
          if (!_intentionalClose) {
            _errorController.add(SocketError(
              message: 'Connection error.',
              code: 'socket_error',
              originalError: error,
            ));
            _scheduleReconnect();
          }
        },
      );

      // Start heartbeat
      _startHeartbeat();
    } catch (e) {
      debugPrint('[PlayerClient] Connection failed: $e');
      _setState(PlayerConnectionState.disconnected);
      if (!_intentionalClose) {
        _scheduleReconnect();
      }
    }
  }

  /// Send a message to the host.
  void send(GameMessage message) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(message.toJson());
    } catch (e) {
      debugPrint('[PlayerClient] Send failed: $e');
    }
  }

  /// Send join request.
  void joinWithCode(String code, {String? playerName, String? uid}) {
    send(GameMessage.playerJoin(
      joinCode: code,
      playerName: playerName,
      uid: uid,
    ));
  }

  /// Claim a player name.
  void claimPlayer(String playerId) {
    send(GameMessage.playerClaim(playerId: playerId));
  }

  /// Cast a vote.
  void vote({required String voterId, required String targetId}) {
    send(GameMessage.playerVote(voterId: voterId, targetId: targetId));
  }

  /// Leave the game.
  void leave(String playerId) {
    send(GameMessage.playerLeave(playerId: playerId));
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      if (_url != null && !_intentionalClose) {
        debugPrint('[PlayerClient] Attempting reconnect...');
        _setState(PlayerConnectionState.reconnecting);
        connect(_url!);
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_state == PlayerConnectionState.connected) {
        send(GameMessage.pong());
      }
    });
  }

  /// Disconnect cleanly.
  Future<void> disconnect() async {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _setState(PlayerConnectionState.disconnected);
  }
}

enum PlayerConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'game_message.dart';

/// WebSocket server running on the Host device.
///
/// Players connect via `ws://<host-ip>:<port>`.
/// The Host app creates one instance and broadcasts state changes.
class HostServer {
  HttpServer? _server;
  final List<WebSocket> _clients = [];
  final int port;
  Timer? _heartbeatTimer;

  /// Map of WebSocket → playerId for tracking reconnections.
  final Map<WebSocket, String> _socketToPlayer = {};

  /// Called when a message arrives from any player.
  void Function(GameMessage message, WebSocket sender)? onMessage;

  /// Called when a player connects.
  void Function(WebSocket client)? onConnect;

  /// Called when a player disconnects.
  void Function(WebSocket client)? onDisconnect;

  /// List of all connected WebSockets.
  List<WebSocket> get clients => List.unmodifiable(_clients);

  /// Association of socket to player ID.
  Map<WebSocket, String> get socketMap => Map.unmodifiable(_socketToPlayer);

  HostServer({
    this.port = 8080,
    this.onMessage,
    this.onConnect,
    this.onDisconnect,
  });

  /// The local IP addresses the server is bound to.
  Future<List<String>> getLocalIps() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );
    return interfaces.expand((i) => i.addresses).map((a) => a.address).toList();
  }

  /// Start listening for player connections.
  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    debugPrint('[HostServer] Listening on port $port');

    // Start periodic heartbeat every 30 seconds
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      pingAll();
    });

    _server!.listen(
      (HttpRequest request) async {
        try {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            try {
              final socket = await WebSocketTransformer.upgrade(request);
              _handleConnection(socket);
            } catch (e) {
              debugPrint('[HostServer] WebSocket upgrade failed: $e');
              try {
                request.response
                  ..statusCode = HttpStatus.internalServerError
                  ..write('WebSocket upgrade failed');
                await request.response.close();
              } catch (_) {
                // Response might be closed already
              }
            }
          } else {
            // Simple health check endpoint
            request.response
              ..statusCode = HttpStatus.ok
              ..headers.contentType = ContentType.text
              ..write('Club Blackout Host Server');
            await request.response.close();
          }
        } catch (e) {
          debugPrint('[HostServer] Request handling error: $e');
          try {
            request.response
              ..statusCode = HttpStatus.internalServerError
              ..write('Internal Server Error');
            await request.response.close();
          } catch (_) {
            // Response might be closed already
          }
        }
      },
      onError: (error) {
        debugPrint('[HostServer] Server error: $error');
      },
      onDone: () {
        debugPrint('[HostServer] Server stream closed');
      },
    );
  }

  void _handleConnection(WebSocket socket) {
    _clients.add(socket);
    debugPrint('[HostServer] Player connected (${_clients.length} total)');
    onConnect?.call(socket);

    socket.listen(
      (data) {
        try {
          final message = GameMessage.fromJson(data as String);

          // Auto-respond to pong — no action needed
          if (message.type == 'pong') return;

          onMessage?.call(message, socket);
        } catch (e) {
          debugPrint('[HostServer] Bad message: $e');
        }
      },
      onDone: () {
        _clients.remove(socket);
        _socketToPlayer.remove(socket);
        debugPrint(
            '[HostServer] Player disconnected (${_clients.length} total)');
        onDisconnect?.call(socket);
      },
      onError: (error) {
        _clients.remove(socket);
        _socketToPlayer.remove(socket);
        debugPrint('[HostServer] Connection error: $error');
        onDisconnect?.call(socket);
      },
    );
  }

  /// Broadcast a message to all connected players.
  void broadcast(GameMessage message) {
    final json = message.toJson();
    for (final client in _clients) {
      try {
        client.add(json);
      } catch (e) {
        debugPrint('[HostServer] Failed to send to client: $e');
      }
    }
  }

  /// Send a message to a specific client.
  void sendTo(WebSocket client, GameMessage message) {
    try {
      client.add(message.toJson());
    } catch (e) {
      debugPrint('[HostServer] Failed to send: $e');
    }
  }

  /// Associate a socket with a player ID (for reconnection tracking).
  void registerPlayer(WebSocket socket, String playerId) {
    _socketToPlayer[socket] = playerId;
  }

  /// Get the player ID associated with a socket.
  String? playerIdForSocket(WebSocket socket) {
    return _socketToPlayer[socket];
  }

  /// Get list of player IDs with active connections.
  Set<String> get connectedPlayerIds => _socketToPlayer.values.toSet();

  /// Send a heartbeat ping to all clients.
  void pingAll() {
    broadcast(GameMessage.ping());
  }

  /// Number of connected clients.
  int get clientCount => _clients.length;

  /// Stop the server and close all connections.
  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    final clientsToClose = List<WebSocket>.from(_clients);
    for (final client in clientsToClose) {
      await client.close();
    }
    _clients.clear();
    _socketToPlayer.clear();
    await _server?.close(force: true);
    _server = null;
    debugPrint('[HostServer] Server stopped');
  }
}

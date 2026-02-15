import 'package:cb_comms/cb_comms.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bridges the Host's Riverpod state to connected Player devices via WebSocket.
///
/// Listens to [gameProvider] and [sessionProvider], broadcasting state_sync
/// messages whenever the game state changes. Handles inbound messages from
/// players (join, claim, vote, action, leave).
/// Provider for the HostServer instance.
final hostServerProvider = Provider<HostServer>((ref) {
  return HostServer(port: 8080);
});

class HostBridge {
  final HostServer _server;
  final Ref _ref;

  HostBridge(this._ref, {required HostServer server}) : _server = server;

  bool _running = false;
  bool get isRunning => _running;

  /// Number of currently connected WebSocket clients.
  int get clientCount => _server.clientCount;

  /// Active WebSocket server port.
  int get port => _server.port;

  /// Start the WebSocket server and begin listening.
  Future<void> start() async {
    if (kIsWeb) {
      debugPrint(
          '[HostBridge] Local WebSocket server is not supported on web; skipping start.');
      _running = false;
      return;
    }

    if (_running) return;

    _server.onMessage = (msg, sender) => _handleMessage(msg, sender);
    _server.onConnect = (_) {
      debugPrint('[HostBridge] Player connected');
      // Send full state to newly connected player
      _broadcastState();
    };
    _server.onDisconnect = (socket) {
      final playerId = _server.playerIdForSocket(socket);
      debugPrint(
          '[HostBridge] Player disconnected${playerId != null ? " ($playerId)" : ""}');
    };

    await _server.start();
    _running = true;
    debugPrint('[HostBridge] Server started on port ${_server.port}');
  }

  /// Stop the server.
  Future<void> stop() async {
    if (kIsWeb) {
      _running = false;
      return;
    }

    await _server.stop();
    _running = false;
  }

  /// Call this whenever game state or session state changes.
  /// Typically hooked up via ref.listen in the widget tree.
  void broadcastCurrentState() => _broadcastState();

  /// Get local IPs for QR code / display.
  Future<List<String>> getLocalIps() {
    if (kIsWeb) {
      return Future.value(const []);
    }
    return _server.getLocalIps();
  }

  /// Broadcasts a generic message to all connected clients.
  void broadcast(GameMessage message) {
    if (!_running) return;

    if (message.type == 'effect') {
      final effectType = message.payload['effectType'] as String?;
      final payload = message.payload['payload'] as Map<String, dynamic>?;
      if (effectType != null) {
        _ref
            .read(roomEffectsProvider.notifier)
            .triggerEffect(effectType, payload);
      }
    }

    if (message.type == 'sound') {
      final soundId = message.payload['soundId'] as String?;
      final volume = message.payload['volume'] as double?;
      if (soundId != null) {
        SoundService.playSfx(soundId, volume: volume);
      }
    }

    _server.broadcast(message);
  }

  // ─── OUTBOUND: Host → Players ──────────────────

  void _broadcastState() {
    final game = _ref.read(gameProvider);
    final session = _ref.read(sessionProvider);
    final step = game.currentStep;
    final isEndGame = game.phase == GamePhase.endGame;

    for (final client in _server.clients) {
      final recipientId = _server.socketMap[client];

      final playerMaps = game.players.map((p) {
        final isSelf = p.id == recipientId;
        final shouldSeeAll = isEndGame || isSelf;

        if (shouldSeeAll) {
          return {
            'id': p.id,
            'name': p.name,
            'roleId': p.role.id,
            'roleName': p.role.name,
            'roleDescription': p.role.description,
            'roleColorHex': p.role.colorHex,
            'alliance': p.alliance.name,
            'isAlive': p.isAlive,
            'deathDay': p.deathDay,
            'silencedDay': p.silencedDay,
            'medicChoice': p.medicChoice,
            'lives': p.lives,
            'drinksOwed': p.drinksOwed,
            'currentBetTargetId': p.currentBetTargetId,
            'penalties': p.penalties,
            'hasRumour': p.hasRumour,
            'clingerPartnerId': p.clingerPartnerId,
            'hasReviveToken': p.hasReviveToken,
            'secondWindPendingConversion': p.secondWindPendingConversion,
            'creepTargetId': p.creepTargetId,
            'whoreDeflectionUsed': p.whoreDeflectionUsed,
            'tabooNames': p.tabooNames,
          };
        } else {
          // Filtered view for other players
          return {
            'id': p.id,
            'name': p.name,
            'isAlive': p.isAlive,
            'deathDay': p.deathDay,
            'hasRumour': p.hasRumour,
            // Hide everything else
            'roleId': 'hidden',
            'roleName': 'Unknown',
            'roleDescription': '',
            'roleColorHex': '#888888',
            'alliance': 'unknown',
          };
        }
      }).toList();

      final msg = GameMessage.stateSync(
        phase: game.phase.name,
        dayCount: game.dayCount,
        players: playerMaps,
        currentStep: step != null
            ? {
                'id': step.id,
                'title': step.title,
                'readAloudText': step.readAloudText,
                'instructionText': step.instructionText,
                'actionType': step.actionType.name,
                'roleId': step.roleId,
                'options': step.options,
                'timerSeconds': step.timerSeconds,
                'isOptional': step.isOptional,
              }
            : null,
        winnerId: game.winner?.name,
        endGameReport:
            game.endGameReport.isNotEmpty ? game.endGameReport : null,
        voteTally: game.dayVoteTally.isNotEmpty ? game.dayVoteTally : null,
        votesByVoter:
            game.dayVotesByVoter.isNotEmpty ? game.dayVotesByVoter : null,
        nightReport:
            game.lastNightReport.isNotEmpty ? game.lastNightReport : null,
        dayReport: game.lastDayReport.isNotEmpty ? game.lastDayReport : null,
        privateMessages:
            game.privateMessages.isNotEmpty ? game.privateMessages : null,
        bulletinBoard: game.bulletinBoard.map((e) => e.toJson()).toList(),
        eyesOpen: game.eyesOpen,
        claimedPlayerIds: session.claimedPlayerIds,
        gameHistory: game.gameHistory.isNotEmpty ? game.gameHistory : null,
        deadPoolBets: game.deadPoolBets.isNotEmpty ? game.deadPoolBets : null,
        hostName: session.hostName,
      );

      _server.sendTo(client, msg);
    }
  }

  // ─── INBOUND: Player → Host ────────────────────

  void _handleMessage(GameMessage msg, dynamic sender) {
    switch (msg.type) {
      case 'player_join':
        _handleJoin(msg, sender);
        break;
      case 'player_claim':
        _handleClaim(msg, sender);
        break;
      case 'player_vote':
        _handleVote(msg);
        break;
      case 'player_action':
        _handleAction(msg);
        break;
      case 'player_leave':
        _handleLeave(msg);
        break;
      case 'player_bet':
        _handleBet(msg);
        break;
      case 'ghost_chat':
        _handleGhostChat(msg, sender);
        break;
      case 'player_reconnect':
        _handleReconnect(msg, sender);
        break;
      case 'pong':
        // heartbeat ack — no action needed
        break;
      default:
        debugPrint('[HostBridge] Unknown message type: ${msg.type}');
    }
  }

  void _handleJoin(GameMessage msg, dynamic sender) {
    final code = msg.payload['joinCode'] as String? ?? '';
    final session = _ref.read(sessionProvider);

    if (code == session.joinCode) {
      _server.sendTo(sender, GameMessage.joinCodeResponse(accepted: true));
      _broadcastState();
    } else {
      _server.sendTo(
          sender,
          GameMessage.joinCodeResponse(
            accepted: false,
            error: 'Invalid join code',
          ));
    }
  }

  void _handleClaim(GameMessage msg, dynamic sender) {
    final playerId = msg.payload['playerId'] as String? ?? '';
    final sessionCtrl = _ref.read(sessionProvider.notifier);
    final success = sessionCtrl.claimPlayer(playerId);

    _server.sendTo(
        sender,
        GameMessage.claimResponse(
          success: success,
          playerId: success ? playerId : null,
        ));

    if (success) {
      // Register socket-to-player mapping for reconnection tracking
      _server.registerPlayer(sender, playerId);
      debugPrint('[HostBridge] Player claimed: $playerId');
    }
    _broadcastState();
  }

  void _handleVote(GameMessage msg) {
    final voterId = msg.payload['voterId'] as String? ?? '';
    final targetId = msg.payload['targetId'] as String? ?? '';

    _ref.read(gameProvider.notifier).handleInteraction(
          stepId: 'day_vote',
          targetId: targetId,
          voterId: voterId,
        );
    _broadcastState();
  }

  void _handleAction(GameMessage msg) {
    final stepId = msg.payload['stepId'] as String? ?? '';
    final targetId = msg.payload['targetId'] as String? ?? '';
    final voterId = msg.payload['voterId'] as String?;

    _ref.read(gameProvider.notifier).handleInteraction(
          stepId: stepId,
          targetId: targetId,
          voterId: voterId,
        );
    _broadcastState();
  }

  void _handleLeave(GameMessage msg) {
    final playerId = msg.payload['playerId'] as String? ?? '';
    _ref.read(sessionProvider.notifier).releasePlayer(playerId);
    _broadcastState();
  }

  void _handleBet(GameMessage msg) {
    final playerId = msg.payload['playerId'] as String? ?? '';
    final targetPlayerId = msg.payload['targetPlayerId'] as String? ?? '';

    if (playerId.isEmpty || targetPlayerId.isEmpty) {
      return;
    }

    _ref.read(gameProvider.notifier).placeDeadPoolBet(
          playerId: playerId,
          targetPlayerId: targetPlayerId,
        );
    _broadcastState();
  }

  void _handleGhostChat(GameMessage msg, dynamic sender) {
    final playerId = msg.payload['playerId'] as String? ?? '';
    final playerName = msg.payload['playerName'] as String?;
    final message = msg.payload['message'] as String? ?? '';

    if (playerId.isEmpty || message.trim().isEmpty) {
      return;
    }

    final game = _ref.read(gameProvider);
    final senderMatches = game.players.where((p) => p.id == playerId);
    if (senderMatches.isEmpty) {
      return;
    }
    final senderPlayer = senderMatches.first;
    if (senderPlayer.isAlive) {
      return;
    }

    final sanitizedMessage = message.trim();

    _ref.read(gameProvider.notifier).addGhostChatMessage(
          senderPlayerId: playerId,
          senderPlayerName: playerName ?? senderPlayer.name,
          message: sanitizedMessage,
        );

    // Specialized dead-only channel: only sockets mapped to dead players receive this.
    for (final client in _server.clients) {
      final recipientId = _server.playerIdForSocket(client);
      if (recipientId == null) {
        continue;
      }
      final recipientMatches = game.players.where((p) => p.id == recipientId);
      if (recipientMatches.isEmpty) {
        continue;
      }
      final recipient = recipientMatches.first;
      if (recipient.isAlive) {
        continue;
      }
      _server.sendTo(
        client,
        GameMessage.ghostChat(
          playerId: playerId,
          playerName: playerName ?? senderPlayer.name,
          message: sanitizedMessage,
        ),
      );
    }
  }

  void _handleReconnect(GameMessage msg, dynamic sender) {
    final claimedIds = (msg.payload['claimedPlayerIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final session = _ref.read(sessionProvider);

    // Re-register socket-to-player mappings for IDs that are still claimed
    for (final id in claimedIds) {
      if (session.claimedPlayerIds.contains(id)) {
        _server.registerPlayer(sender, id);
        debugPrint('[HostBridge] Reconnect: re-registered $id');
      }
    }

    // Auto-accept the join (they were already in) and send full state
    _server.sendTo(sender, GameMessage.joinCodeResponse(accepted: true));
    _broadcastState();
  }
}

/// Riverpod provider for the HostBridge.
/// Usage in host app:
///   final bridge = ref.read(hostBridgeProvider);
///   bridge.start();
final hostBridgeProvider = Provider<HostBridge>((ref) {
  final server = ref.watch(hostServerProvider);
  final bridge = HostBridge(ref, server: server);

  // Auto-broadcast on game state changes
  ref.listen(gameProvider, (prev, next) {
    if (bridge.isRunning) {
      bridge.broadcastCurrentState();
    }
  });

  // Auto-broadcast on session state changes
  ref.listen(sessionProvider, (prev, next) {
    if (bridge.isRunning) {
      bridge.broadcastCurrentState();
    }
  });

  // Clean up on dispose
  ref.onDispose(() {
    bridge.stop();
  });

  return bridge;
});

/// Provides the local IP addresses of the host device.
/// Caches the result to avoid repeated calls to network interfaces.
final localIpsProvider = FutureProvider<List<String>>((ref) {
  return ref.read(hostBridgeProvider).getLocalIps();
});

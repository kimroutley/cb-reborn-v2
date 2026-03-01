import 'dart:async';

import 'package:cb_comms/cb_comms.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

enum CloudLinkPhase {
  offline,
  requiresAuth,
  initializing,
  publishing,
  verifying,
  verified,
  degraded,
}

@immutable
class CloudLinkState {
  const CloudLinkState({
    required this.phase,
    this.message,
  });

  final CloudLinkPhase phase;
  final String? message;

  bool get isVerified => phase == CloudLinkPhase.verified;

  CloudLinkState copyWith({
    CloudLinkPhase? phase,
    String? message,
  }) {
    return CloudLinkState(
      phase: phase ?? this.phase,
      message: message,
    );
  }
}

class CloudLinkStateNotifier extends Notifier<CloudLinkState> {
  @override
  CloudLinkState build() {
    return const CloudLinkState(
      phase: CloudLinkPhase.offline,
      message: 'Cloud link offline. Sign in and establish link.',
    );
  }

  void update(CloudLinkState next) {
    state = next;
  }
}

final cloudLinkStateProvider =
    NotifierProvider<CloudLinkStateNotifier, CloudLinkState>(
  CloudLinkStateNotifier.new,
);

/// Cloud-mode host bridge using Firebase Firestore.
///
/// Replaces [HostBridge] when [SyncMode.cloud] is selected.
/// Publishes game state to Firestore (per-player filtered),
/// and listens for player actions + join requests.
class CloudHostBridge {
  final Ref _ref;
  FirebaseBridge? _firebase;
  @visibleForTesting
  FirebaseBridge? debugFirebase;
  static const String _debugHostUidFallback = '__debug_host__';
  static const int _baseRetryDelayMs = 200;
  static const String _unknownGhostSenderName = 'Unknown';

  String? _resolvedHostUid;

  int? _lastPublishedHash;
  Future<void> _publishChain = Future<void>.value();

  StreamSubscription? _joinSub;
  StreamSubscription? _actionSub;
  StreamSubscription? _bridgeErrorSub;
  final Set<String> _processedJoins = {};
  final Set<String> _processedActions = {};

  bool _running = false;
  bool get isRunning => _running;

  CloudHostBridge(this._ref);

  void _setLinkState(
    CloudLinkPhase phase, {
    String? message,
  }) {
    _ref.read(cloudLinkStateProvider.notifier).update(
          CloudLinkState(
            phase: phase,
            message: message,
          ),
        );
  }

  String get joinCode => _ref.read(sessionProvider).joinCode;

  @visibleForTesting
  Future<String?> resolveHostUid() async {
    try {
      final current = FirebaseAuth.instance.currentUser?.uid;
      if (current != null && current.isNotEmpty) {
        return current;
      }
    } catch (_) {
      return null;
    }

    try {
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(const Duration(seconds: 8));
      return user?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Start cloud mode — begin publishing to Firestore and listening.
  Future<void> start() async {
    if (_running) {
      _setLinkState(
        CloudLinkPhase.verified,
        message: 'Cloud link already active and verified.',
      );
      return;
    }

    _setLinkState(
      CloudLinkPhase.initializing,
      message: 'Initializing cloud runtime...',
    );

    if (debugFirebase == null) {
      // Ensure Firebase is initialized before touching FirebaseAuth in production.
      await FirebaseBridge.ensureInitialized(
        options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
      );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _setLinkState(
          CloudLinkPhase.requiresAuth,
          message: 'Host sign-in required before establishing cloud link.',
        );
        throw StateError('Host must be signed in before starting cloud link.');
      }
      _resolvedHostUid = currentUser.uid;
    } else {
      final hostUid = await resolveHostUid();
      if (hostUid == null || hostUid.isEmpty) {
        _resolvedHostUid = _debugHostUidFallback;
        debugPrint(
          '[CloudHostBridge] Debug bridge active without Firebase auth; using fallback host uid $_debugHostUidFallback',
        );
      } else {
        _resolvedHostUid = hostUid;
      }
    }

    _firebase = debugFirebase ?? FirebaseBridge(joinCode: joinCode);
    _bridgeErrorSub = _firebase!.errors.listen((error) {
      debugPrint('[CloudHostBridge] Bridge error: ${error.message}');
      _setLinkState(
        CloudLinkPhase.degraded,
        message: error.message,
      );
    });
    _running = true;
    _setLinkState(
      CloudLinkPhase.publishing,
      message: 'Cloud runtime initialized. Publishing state...',
    );

    // Listen for join requests from players
    _joinSub = _firebase!.subscribeToJoinRequests().listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          final docId = change.doc.id;
          if (docId.isEmpty) continue;

          final persistenceKey = 'join:$docId';
          if (_processedJoins.contains(docId)) continue;
          try {
            if (PersistenceService.instance
                .isBridgeIdProcessed(persistenceKey)) {
              _processedJoins.add(docId);
              continue;
            }
          } catch (_) {
            // PersistenceService may not be available (e.g., offline fallback).
            // In-memory deduplication via _processedJoins remains active.
          }
          _processedJoins.add(docId);
          try {
            PersistenceService.instance.markBridgeIdProcessed(persistenceKey);
          } catch (_) {
            // Non-critical: persistence dedup unavailable; in-memory set suffices.
          }

          final data = change.doc.data();
          if (data == null) continue;

          final name = (data['name'] as String?)?.trim();
          final uid = (data['uid'] as String?)?.trim();
          if (name != null && name.isNotEmpty) {
            _ref.read(gameProvider.notifier).addPlayer(
                  name,
                  authUid: uid?.isNotEmpty == true ? uid : null,
                );
            debugPrint('[CloudHostBridge] Player joined: $name ($uid)');
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[CloudHostBridge] Join stream error: $error');
        _running = false;
        _setLinkState(
          CloudLinkPhase.degraded,
          message: 'Join stream error detected. Retry cloud link.',
        );
      },
    );

    // Listen for player actions (votes, night actions)
    _actionSub = _firebase!.subscribeToActions().listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          final docId = change.doc.id;
          if (docId.isEmpty) continue;

          final persistenceKey = 'action:$docId';
          if (_processedActions.contains(docId)) continue;
          try {
            if (PersistenceService.instance
                .isBridgeIdProcessed(persistenceKey)) {
              _processedActions.add(docId);
              continue;
            }
          } catch (_) {
            // PersistenceService may not be available (e.g., offline fallback).
            // In-memory deduplication via _processedActions remains active.
          }
          _processedActions.add(docId);
          try {
            PersistenceService.instance.markBridgeIdProcessed(persistenceKey);
          } catch (_) {
            // Non-critical: persistence dedup unavailable; in-memory set suffices.
          }

          // Enhanced Deduplication & Validation
          final data = change.doc.data();
          if (data == null) continue;

          final type = data['type'] as String?;
          final senderPlayerId = (data['playerId'] as String? ?? '').trim();
          final payload = (data['payload'] as Map?)
                  ?.map((key, value) => MapEntry(key.toString(), value)) ??
              const <String, dynamic>{};

          if (senderPlayerId.isNotEmpty &&
              senderPlayerId != 'unknown' &&
              type != 'chat' &&
              type != 'role_confirm') {
            final isKnown = _ref.read(gameProvider).players.any(
                (p) => p.id == senderPlayerId || p.authUid == senderPlayerId);
            if (!isKnown && type != 'join') {
              debugPrint(
                  '[CloudHostBridge] Action from unknown player $senderPlayerId ignored.');
              continue;
            }
          }

          if (type == 'dead_pool_bet') {
            final playerId = data['playerId'] as String? ?? '';
            final targetPlayerId = (data['targetId'] as String?) ??
                (data['targetPlayerId'] as String?) ??
                (payload['targetPlayerId'] as String?) ??
                '';
            if (playerId.isNotEmpty && targetPlayerId.isNotEmpty) {
              _ref.read(gameProvider.notifier).placeDeadPoolBet(
                    playerId: playerId,
                    targetPlayerId: targetPlayerId,
                  );
              debugPrint(
                  '[CloudHostBridge] Dead-pool bet: $playerId -> $targetPlayerId');
            }
            continue;
          }

          if (type == 'ghost_chat') {
            final playerId = data['playerId'] as String? ?? '';
            final playerName = (data['playerName'] as String?) ??
                (payload['playerName'] as String?);
            final message = (data['message'] as String?) ??
                (payload['message'] as String?) ??
                '';
            if (playerId.isNotEmpty && message.trim().isNotEmpty) {
              _ref.read(gameProvider.notifier).addGhostChatMessage(
                    senderPlayerId: playerId,
                    senderPlayerName: playerName,
                    message: message.trim(),
                  );
              debugPrint('[CloudHostBridge] Ghost chat from $playerId');
            }
            continue;
          }

          if (type == 'chat') {
            final payload = data['payload'] as Map<String, dynamic>? ?? {};
            final senderPlayerId = (data['playerId'] as String? ?? '').trim();
            String? senderName;
            if (senderPlayerId.isNotEmpty) {
              for (final player in _ref.read(gameProvider).players) {
                if (player.id == senderPlayerId) {
                  senderName = player.name;
                  break;
                }
              }
            }
            final payloadTitle = (payload['title'] as String?)?.trim();
            final title = (payloadTitle != null && payloadTitle.isNotEmpty)
              ? payloadTitle
              : (senderName?.isNotEmpty == true ? senderName! : 'Unknown');
            final content = payload['content'] as String? ?? '';
            final roleId = payload['roleId'] as String?;

            if (content.isNotEmpty) {
              _ref.read(gameProvider.notifier).postBulletin(
                    title: title,
                    content: content,
                    roleId: roleId,
                    type: 'chat',
                  );
              debugPrint('[CloudHostBridge] Chat from $roleId: $content');
            }
            continue;
          }

          if (type == 'role_confirm') {
            final playerId = (data['playerId'] as String? ?? '').trim();
            if (playerId.isNotEmpty) {
              _ref.read(sessionProvider.notifier).confirmRole(playerId);
              debugPrint('[CloudHostBridge] Role confirmed: $playerId');
              // Post a tally to group chat so all players see confirmation progress
              _postRoleConfirmationTally(playerId);
            }
            continue;
          }

          final stepId = data['stepId'] as String? ?? '';
          final targetId = data['targetId'] as String?;
          final playerId = data['playerId'] as String?;

          if (stepId.isNotEmpty) {
            _ref.read(gameProvider.notifier).handleInteraction(
                  stepId: stepId,
                  targetId: targetId ?? '',
                  voterId: playerId,
                );
            debugPrint('[CloudHostBridge] Action: $stepId from $playerId');
          }
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[CloudHostBridge] Action stream error: $error');
        _running = false;
        _setLinkState(
          CloudLinkPhase.degraded,
          message: 'Action stream error detected. Retry cloud link.',
        );
      },
    );

    // Publish initial state
    try {
      await publishState();
      if (debugFirebase == null) {
        _setLinkState(
          CloudLinkPhase.verifying,
          message: 'Publish complete. Verifying end-to-end uplink...',
        );

        final verified = await _verifyEndToEnd();
        if (!verified) {
          _running = false;
          _setLinkState(
            CloudLinkPhase.degraded,
            message: 'Cloud link verification failed. Retry required.',
          );
          throw StateError('Cloud link verification failed.');
        }
      }

      _setLinkState(
        CloudLinkPhase.verified,
        message: 'Cloud link verified end-to-end.',
      );
    } catch (e) {
      debugPrint('[CloudHostBridge] Initial publish failed: $e');
      _setLinkState(
        CloudLinkPhase.degraded,
        message: 'Cloud link failed to start. Retry required.',
      );
      await stop();
      rethrow;
    }
    debugPrint('[CloudHostBridge] Started for game $joinCode');
  }

  Future<bool> _verifyEndToEnd() async {
    if (_firebase == null) {
      return false;
    }

    final hostUid = _resolvedHostUid ?? await resolveHostUid();
    if (hostUid == null || hostUid.isEmpty) {
      return false;
    }
    _resolvedHostUid = hostUid;

    try {
      await _firebase!.subscribeToGame().firstWhere((snapshot) {
        final data = snapshot.data();
        if (data == null) {
          return false;
        }
        final hostId = data['hostId'] as String?;
        final updatedAt = data['updatedAt'];
        return hostId == hostUid && updatedAt != null;
      }).timeout(const Duration(seconds: 8));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Stop cloud mode and clean up subscriptions.
  Future<void> stop({bool updateLinkState = true}) async {
    await _joinSub?.cancel();
    await _actionSub?.cancel();
    await _bridgeErrorSub?.cancel();
    _joinSub = null;
    _actionSub = null;
    _bridgeErrorSub = null;
    _processedJoins.clear();
    _processedActions.clear();
    _resolvedHostUid = null;
    _running = false;
    if (updateLinkState) {
      _setLinkState(
        CloudLinkPhase.offline,
        message: 'Cloud link offline. Sign in and establish link.',
      );
    }
    debugPrint('[CloudHostBridge] Stopped');
  }

  /// Post a role-confirmation tally to the group chat when a player confirms.
  void _postRoleConfirmationTally(String playerId) {
    final game = _ref.read(gameProvider);
    if (game.phase != GamePhase.setup) return;
    final session = _ref.read(sessionProvider);
    final currentPlayerIds = game.players.map((p) => p.id).toSet();
    final totalWithRole = game.players
        .where((p) => p.role.id != 'unassigned')
        .length;
    if (totalWithRole == 0) return;
    final confirmedCount = session.roleConfirmedPlayerIds
        .where(currentPlayerIds.contains)
        .length;
    String playerName;
    try {
      playerName =
          game.players.firstWhere((p) => p.id == playerId).name;
    } catch (_) {
      playerName = 'A player';
    }
    _ref.read(gameProvider.notifier).postBulletin(
      title: 'ROLE CONFIRMATION',
      content:
          '$playerName has confirmed their role. ($confirmedCount/$totalWithRole confirmed)',
      type: 'info',
    );
  }

  /// Publish current game state to Firestore.
  ///
  /// Public doc: game phase, day, filtered player list
  /// Private docs: per-player role/alliance data
  Future<void> publishState() async {
    if (_firebase == null || !_running) return;

    _publishChain = _publishChain
        .catchError((_) {})
        .then((_) => _publishStateInternal());
    await _publishChain;
  }

  Future<void> _publishStateInternal() async {
    if (_firebase == null || !_running) {
      return;
    }

    final game = _ref.read(gameProvider);
    final session = _ref.read(sessionProvider);
    final currentPlayerIds = game.players.map((p) => p.id).toSet();
    final roleConfirmedPlayerIds = session.roleConfirmedPlayerIds
        .where(currentPlayerIds.contains)
        .toList();

    final currentHash = _computeStateHash(game, session);
    if (currentHash == _lastPublishedHash) {
      return;
    }

    final hostUid = _resolvedHostUid ?? await resolveHostUid();
    if (hostUid == null || hostUid.isEmpty) {
      debugPrint(
          '[CloudHostBridge] Skipping publish: host user is not authenticated yet.');
      _setLinkState(
        CloudLinkPhase.degraded,
        message: 'Publish blocked: host authentication unavailable.',
      );
      throw StateError('Host authentication unavailable for publish.');
    }
    _resolvedHostUid = hostUid;

    final step = game.currentStep;
    final isEndGame = game.phase == GamePhase.endGame;
    final stateRevision = DateTime.now().microsecondsSinceEpoch;

    // Build public player list (filtered — no secret role data)
    final publicPlayers = game.players
        .map((p) => {
              'id': p.id,
              'name': p.name,
              'authUid': p.authUid,
              'isAlive': p.isAlive,
              'deathDay': p.deathDay,
              'hasRumour': p.hasRumour,
              'drinksOwed': p.drinksOwed,
              'currentBetTargetId': p.currentBetTargetId,
              'penalties': p.penalties,
              // Hide role info in public doc
              'roleId': isEndGame ? p.role.id : 'hidden',
              'roleName': isEndGame ? p.role.name : 'Unknown',
              'roleDescription': isEndGame ? p.role.description : '',
              'roleColorHex': isEndGame ? p.role.colorHex : '#888888',
              'alliance': isEndGame ? p.alliance.name : 'unknown',
            })
        .toList();

    final publicState = <String, dynamic>{
      'phase': game.phase.name,
      'hostId': hostUid,
      'dayCount': game.dayCount,
      'players': publicPlayers,
      'currentStep': step != null
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
      'winner': game.winner?.name,
      'endGameReport':
          game.endGameReport.isNotEmpty ? game.endGameReport : null,
      'voteTally': game.dayVoteTally.isNotEmpty ? game.dayVoteTally : null,
      'votesByVoter':
          game.dayVotesByVoter.isNotEmpty ? game.dayVotesByVoter : null,
      'nightReport':
          game.lastNightReport.isNotEmpty ? game.lastNightReport : null,
      'dayReport': game.lastDayReport.isNotEmpty ? game.lastDayReport : null,
      'claimedPlayerIds': session.claimedPlayerIds,
      'roleConfirmedPlayerIds': roleConfirmedPlayerIds,
      'gameHistory': game.gameHistory.isNotEmpty ? game.gameHistory : null,
      'deadPoolBets': game.deadPoolBets.isNotEmpty ? game.deadPoolBets : null,
      // Public bulletin only (mirrored to player app group chat); see docs/operations/group-chat-sync-and-visibility.md
      'bulletinBoard': game.bulletinBoard.isNotEmpty
          ? game.bulletinBoard
              .where((e) => !e.isHostOnly)
              .map((e) => e.toJson())
              .toList()
          : null,
      'rematchOffered': game.rematchOffered ? true : null,
      'stateRevision': stateRevision,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    // Build per-player private data (their own role, alliance, secret fields)
    final playerPrivateData = <String, Map<String, dynamic>>{};
    for (final p in game.players) {
      final rawPrivateMessages = game.privateMessages[p.id] ?? const <String>[];
      final ghostMessages =
          rawPrivateMessages.where((m) => m.startsWith('[GHOST] ')).map((m) {
        final withoutPrefix = m.replaceFirst('[GHOST] ', '');
        final colonIdx = withoutPrefix.indexOf(': ');
        if (colonIdx == -1) {
          return <String, dynamic>{
            'sender': _unknownGhostSenderName,
            'message': withoutPrefix
          };
        }
        return <String, dynamic>{
          'sender': withoutPrefix.substring(0, colonIdx),
          'message': withoutPrefix.substring(colonIdx + 2),
        };
      }).toList();
      playerPrivateData[p.id] = {
        'uid': p.authUid,
        'roleId': p.role.id,
        'roleName': p.role.name,
        'roleDescription': p.role.description,
        'roleColorHex': p.role.colorHex,
        'alliance': p.alliance.name,
        'silencedDay': p.silencedDay,
        'medicChoice': p.medicChoice,
        'lives': p.lives,
        'clingerPartnerId': p.clingerPartnerId,
        'hasReviveToken': p.hasReviveToken,
        'secondWindPendingConversion': p.secondWindPendingConversion,
        'creepTargetId': p.creepTargetId,
        'whoreDeflectionUsed': p.whoreDeflectionUsed,
        'tabooNames': p.tabooNames,
        'privateMessages': rawPrivateMessages,
        'ghost_messages': ghostMessages,
      };
    }

    int attempt = 0;
    const maxRetries = 3;
    while (true) {
      try {
        await _firebase!.publishState(
          publicState: publicState,
          playerPrivateData: playerPrivateData,
          stateRevision: stateRevision,
        );
        _lastPublishedHash = currentHash;
        return;
      } on StaleStateRevisionException {
        debugPrint(
          '[CloudHostBridge] Stale publish dropped (revision $stateRevision).',
        );
        return;
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          _setLinkState(
            CloudLinkPhase.degraded,
            message: 'Publish failed after retries. Check cloud connectivity.',
          );
          rethrow;
        }
        final delay =
            Duration(milliseconds: _baseRetryDelayMs * (1 << attempt));
        await Future.delayed(delay);
        debugPrint(
            '[CloudHostBridge] publishState retry $attempt after error: $e');
      }
    }
  }

  int _computeStateHash(GameState game, SessionState session) {
    return Object.hash(
      game.phase,
      game.dayCount,
      game.winner,
      game.players,
      game.currentStep,
      game.scriptIndex,
      game.dayVoteTally,
      game.dayVotesByVoter,
      game.lastNightReport,
      game.lastDayReport,
      game.endGameReport,
      game.gameHistory,
      game.deadPoolBets,
      game.privateMessages,
      game.bulletinBoard,
      session.claimedPlayerIds,
    );
  }

  /// Clean up the Firestore game document.
  Future<void> deleteGame() async {
    await _firebase?.deleteGame();
  }
}

/// Riverpod provider for [CloudHostBridge].
final cloudHostBridgeProvider = Provider<CloudHostBridge>((ref) {
  final bridge = CloudHostBridge(ref);

  // Auto-publish on game state changes
  ref.listen(gameProvider, (prev, next) {
    if (bridge.isRunning) {
      unawaited(
        bridge.publishState().catchError((error) {
          debugPrint('[CloudHostBridge] publishState failed: $error');
        }),
      );
    }
  });

  // Auto-publish on session state changes
  ref.listen(sessionProvider, (prev, next) {
    if (bridge.isRunning) {
      unawaited(
        bridge.publishState().catchError((error) {
          debugPrint('[CloudHostBridge] publishState failed: $error');
        }),
      );
    }
  });

  ref.onDispose(() {
    bridge.stop(updateLinkState: false);
  });

  return bridge;
});

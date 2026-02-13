import 'dart:async';

import 'package:cb_comms/cb_comms.dart';
import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

/// Cloud-mode host bridge using Firebase Firestore.
///
/// Replaces [HostBridge] when [SyncMode.cloud] is selected.
/// Publishes game state to Firestore (per-player filtered),
/// and listens for player actions + join requests.
class CloudHostBridge {
  final Ref _ref;
  FirebaseBridge? _firebase;

  StreamSubscription? _joinSub;
  StreamSubscription? _actionSub;
  final Set<String> _processedJoins = {};
  final Set<String> _processedActions = {};

  bool _running = false;
  bool get isRunning => _running;

  CloudHostBridge(this._ref);

  String get joinCode => _ref.read(sessionProvider).joinCode;

  Future<String?> _resolveHostUid() async {
    final current = FirebaseAuth.instance.currentUser?.uid;
    if (current != null && current.isNotEmpty) {
      return current;
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
    if (_running) return;

    // Ensure Firebase is initialized for cloud mode
    await FirebaseBridge.ensureInitialized(
      options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
    );

    _firebase = FirebaseBridge(joinCode: joinCode);
    _running = true;

    // Listen for join requests from players
    _joinSub = _firebase!.subscribeToJoinRequests().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.doc.id.isEmpty || _processedJoins.contains(change.doc.id)) {
          continue;
        }
        _processedJoins.add(change.doc.id);

        final data = change.doc.data();
        if (data == null) continue;

        final name = data['name'] as String?;
        final uid = data['uid'] as String?;
        if (name != null && name.isNotEmpty) {
          _ref.read(gameProvider.notifier).addPlayer(name, authUid: uid);
          debugPrint('[CloudHostBridge] Player joined: $name ($uid)');
        }
      }
    });

    // Listen for player actions (votes, night actions)
    _actionSub = _firebase!.subscribeToActions().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.doc.id.isEmpty ||
            _processedActions.contains(change.doc.id)) {
          continue;
        }
        _processedActions.add(change.doc.id);

        final data = change.doc.data();
        if (data == null) continue;

        final type = data['type'] as String?;

        if (type == 'dead_pool_bet') {
          final playerId = data['playerId'] as String? ?? '';
          final targetPlayerId = data['targetPlayerId'] as String? ?? '';
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
          final playerName = data['playerName'] as String?;
          final message = data['message'] as String? ?? '';
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
    });

    // Publish initial state
    await publishState();
    debugPrint('[CloudHostBridge] Started for game $joinCode');
  }

  /// Stop cloud mode and clean up subscriptions.
  Future<void> stop() async {
    await _joinSub?.cancel();
    await _actionSub?.cancel();
    _joinSub = null;
    _actionSub = null;
    _processedJoins.clear();
    _processedActions.clear();
    _running = false;
    debugPrint('[CloudHostBridge] Stopped');
  }

  /// Publish current game state to Firestore.
  ///
  /// Public doc: game phase, day, filtered player list
  /// Private docs: per-player role/alliance data
  Future<void> publishState() async {
    if (_firebase == null || !_running) return;

    final hostUid = await _resolveHostUid();
    if (hostUid == null || hostUid.isEmpty) {
      debugPrint('[CloudHostBridge] Skipping publish: host user is not authenticated yet.');
      return;
    }

    final game = _ref.read(gameProvider);
    final session = _ref.read(sessionProvider);
    final step = game.currentStep;
    final isEndGame = game.phase == GamePhase.endGame;

    // Build public player list (filtered — no secret role data)
    final publicPlayers = game.players
        .map((p) => {
              'id': p.id,
              'name': p.name,
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
      'gameHistory': game.gameHistory.isNotEmpty ? game.gameHistory : null,
      'deadPoolBets': game.deadPoolBets.isNotEmpty ? game.deadPoolBets : null,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    // Build per-player private data (their own role, alliance, secret fields)
    final playerPrivateData = <String, Map<String, dynamic>>{};
    for (final p in game.players) {
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
        'privateMessages': game.privateMessages[p.id] ?? [],
      };
    }

    await _firebase!.publishState(
      publicState: publicState,
      playerPrivateData: playerPrivateData,
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
      bridge.publishState();
    }
  });

  // Auto-publish on session state changes
  ref.listen(sessionProvider, (prev, next) {
    if (bridge.isRunning) {
      bridge.publishState();
    }
  });

  ref.onDispose(() {
    bridge.stop();
  });

  return bridge;
});

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Represents a communication error that occurred within the bridge.
class BridgeError {
  final String message;
  final String? code;
  final dynamic originalError;

  BridgeError({required this.message, this.code, this.originalError});

  @override
  String toString() => 'BridgeError: $message (${code ?? "no code"})';
}

class StaleStateRevisionException implements Exception {
  final int incomingRevision;
  final int existingRevision;

  StaleStateRevisionException({
    required this.incomingRevision,
    required this.existingRevision,
  });

  @override
  String toString() =>
      'StaleStateRevisionException(incoming: $incomingRevision, existing: $existingRevision)';
}

/// Firebase Firestore-based sync for Cloud mode.
///
/// - Host writes GameState to `games/{joinCode}` and per-player private state
/// - Players listen to the public game doc + their own private doc
class FirebaseBridge {
  final FirebaseFirestore _firestore;
  final String joinCode;

  // Stream for broadcasting errors to the UI
  final _errorController = StreamController<BridgeError>.broadcast();
  Stream<BridgeError> get errors => _errorController.stream;

  FirebaseBridge({
    required this.joinCode,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  void dispose() {
    _errorController.close();
  }

  static bool _isInitialized = false;

  /// Ensures Firebase is initialized and anonymously signed in.
  static Future<void> ensureInitialized({FirebaseOptions? options}) async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options)
            .timeout(const Duration(seconds: 8));
      }

      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously().timeout(const Duration(seconds: 8));
      }

      _isInitialized = true;
      debugPrint('[FirebaseBridge] Firebase initialized successfully');
    } catch (e) {
      debugPrint('[FirebaseBridge] Initialization failed: $e');
      rethrow;
    }
  }

  /// Reference to the game document.
  DocumentReference<Map<String, dynamic>> get gameDoc =>
      _firestore.collection('games').doc(joinCode);

  /// Reference to a specific player's private state subcollection.
  DocumentReference<Map<String, dynamic>> playerPrivateDoc(String playerId) =>
      gameDoc.collection('private_state').doc(playerId);

  /// Host: Publish game state to Firestore.
  ///
  /// - `publicState`: All public game data (phase, dayCount, players list with filtered data)
  /// - `playerPrivateData`: Map of playerId → their secret role/alliance data
  Future<void> publishState({
    required Map<String, dynamic> publicState,
    required Map<String, Map<String, dynamic>> playerPrivateData,
    required int stateRevision,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final gameSnapshot = await transaction.get(gameDoc);
        final currentRevision =
            (gameSnapshot.data()?['stateRevision'] as num?)?.toInt() ?? -1;

        if (stateRevision <= currentRevision) {
          throw StaleStateRevisionException(
            incomingRevision: stateRevision,
            existingRevision: currentRevision,
          );
        }

        transaction.set(
          gameDoc,
          <String, dynamic>{
            ...publicState,
            'stateRevision': stateRevision,
          },
          SetOptions(merge: true),
        );

        for (final entry in playerPrivateData.entries) {
          final playerId = entry.key;
          final privateData = entry.value;
          transaction.set(
            playerPrivateDoc(playerId),
            privateData,
            SetOptions(merge: true),
          );
        }
      });
      debugPrint('[FirebaseBridge] Published state for $joinCode');
    } on StaleStateRevisionException {
      rethrow;
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to publish: $e');
      rethrow;
    }
  }

  /// Player: Subscribe to public game state.
  Stream<DocumentSnapshot<Map<String, dynamic>>> subscribeToGame() {
    return gameDoc.snapshots();
  }

  /// Player: Subscribe to their own private state.
  Stream<DocumentSnapshot<Map<String, dynamic>>> subscribeToPrivateState(
    String playerId,
  ) {
    return playerPrivateDoc(playerId).snapshots();
  }

  /// Reference to a player's push subscription doc (for Web Push targeting).
  DocumentReference<Map<String, dynamic>> pushSubscriptionDoc(
          String playerId) =>
      gameDoc.collection('push_subscriptions').doc(playerId);

  /// Player: Store Web Push subscription so the backend can send notifications.
  Future<void> setPushSubscription(
    String playerId,
    Map<String, dynamic> subscription,
  ) async {
    try {
      await pushSubscriptionDoc(playerId).set(subscription);
      debugPrint('[FirebaseBridge] Set push subscription for $playerId');
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to set push subscription: $e');
      rethrow;
    }
  }

  /// Player: Send a join request (creates a claim in `joins` subcollection).
  Future<void> sendJoinRequest(String playerName) async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously().timeout(const Duration(seconds: 8));
      }
      final uid = auth.currentUser?.uid;
      await gameDoc.collection('joins').add({
        'name': playerName,
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to send join request: $e');
      _errorController.add(BridgeError(
        message: 'Could not join game. Please check your connection.',
        code: 'join_failed',
        originalError: e,
      ));
      rethrow;
    }
  }

  Future<void> _sendActionEnvelope({
    required String type,
    required String stepId,
    required String playerId,
    String? targetId,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await gameDoc.collection('actions').add({
        'type': type,
        'stepId': stepId,
        'playerId': playerId,
        'targetId': targetId,
        'payload': payload ?? <String, dynamic>{},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to send $type: $e');
      _errorController.add(BridgeError(
        message: 'Action failed to reach host. Retrying may help.',
        code: 'action_failed',
        originalError: e,
      ));
      rethrow;
    }
  }

  /// Player: Send an action (vote/night action).
  Future<void> sendAction({
    required String stepId,
    required String playerId,
    String? targetId,
  }) async {
    try {
      await _sendActionEnvelope(
        type: 'interaction',
        stepId: stepId,
        playerId: playerId,
        targetId: targetId,
      );
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to send action: $e');
      rethrow;
    }
  }

  /// Player: Send a dead-pool bet action.
  Future<void> sendDeadPoolBet({
    required String playerId,
    required String targetPlayerId,
  }) async {
    try {
      await _sendActionEnvelope(
        type: 'dead_pool_bet',
        stepId: 'dead_pool_bet',
        playerId: playerId,
        targetId: targetPlayerId,
        payload: <String, dynamic>{
          'targetPlayerId': targetPlayerId,
        },
      );
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to send dead-pool bet: $e');
      rethrow;
    }
  }

  /// Player: Send a ghost chat message.
  Future<void> sendGhostChat({
    required String playerId,
    required String message,
    String? playerName,
  }) async {
    try {
      await _sendActionEnvelope(
        type: 'ghost_chat',
        stepId: 'ghost_chat',
        playerId: playerId,
        payload: <String, dynamic>{
          'playerName': playerName,
          'message': message,
        },
      );
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to send ghost chat: $e');
      rethrow;
    }
  }

  /// Player: Send role confirmation acknowledgment.
  Future<void> sendRoleConfirm({required String playerId}) async {
    try {
      await _sendActionEnvelope(
        type: 'role_confirm',
        stepId: 'role_confirm',
        playerId: playerId,
      );
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to send role confirm: $e');
      rethrow;
    }
  }

  /// Player: Send a public chat message.
  Future<void> sendChat({
    required String playerId,
    required String title,
    required String message,
    String? roleId,
  }) async {
    try {
      if (playerId.trim().isEmpty) {
        throw ArgumentError('playerId must not be empty for chat actions');
      }
      await gameDoc.collection('actions').add({
        'type': 'chat',
        'stepId': 'chat',
        'playerId': playerId,
        'payload': {
          'title': title,
          'content': message,
          'roleId': roleId,
        },
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to send chat: $e');
      _errorController.add(BridgeError(
        message: 'Chat message failed to send.',
        code: 'chat_failed',
        originalError: e,
      ));
      rethrow;
    }
  }

  /// Host: Listen to join requests.
  Stream<QuerySnapshot<Map<String, dynamic>>> subscribeToJoinRequests() {
    return gameDoc
        .collection('joins')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Host: Listen to player actions.
  Stream<QuerySnapshot<Map<String, dynamic>>> subscribeToActions() {
    return gameDoc
        .collection('actions')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// Host: Delete the game from Firestore (cleanup on end).
  Future<void> deleteGame() async {
    try {
      // Fetch all subcollections concurrently to reduce latency.
      // We also include push_subscriptions which was missing before.
      final snapshots = await Future.wait([
        gameDoc.collection('joins').get(),
        gameDoc.collection('actions').get(),
        gameDoc.collection('private_state').get(),
        gameDoc.collection('push_subscriptions').get(),
      ]);

      // Flatten all docs to delete
      final allDocs = snapshots.expand((s) => s.docs).toList();

      // Process deletions in chunks of 500 (Firestore limit)
      for (var i = 0; i < allDocs.length; i += 500) {
        final batch = _firestore.batch();
        final end = (i + 500 < allDocs.length) ? i + 500 : allDocs.length;
        final chunk = allDocs.sublist(i, end);

        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        try {
          await batch.commit();
        } catch (batchError) {
          debugPrint(
              '[FirebaseBridge] Warning: Batch deletion partial failure: $batchError');
          // We continue to next batch even if one fails
        }
      }

      await gameDoc.delete();
      debugPrint('[FirebaseBridge] Deleted game $joinCode');
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to delete game: $e');
      _errorController.add(BridgeError(
        message: 'Cleanup failed. Game data may persist in cloud.',
        code: 'cleanup_failed',
        originalError: e,
      ));
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase Firestore-based sync for Cloud mode.
///
/// - Host writes GameState to `games/{joinCode}` and per-player private state
/// - Players listen to the public game doc + their own private doc
class FirebaseBridge {
  final FirebaseFirestore _firestore;
  final String joinCode;

  FirebaseBridge({
    required this.joinCode,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static bool _isInitialized = false;

  /// Ensures Firebase is initialized and anonymously signed in.
  static Future<void> ensureInitialized({FirebaseOptions? options}) async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }

      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
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
  }) async {
    try {
      // Write public game state
      await gameDoc.set(publicState, SetOptions(merge: true));

      // Write each player's private state
      final batch = _firestore.batch();
      for (final entry in playerPrivateData.entries) {
        final playerId = entry.key;
        final privateData = entry.value;
        batch.set(
          playerPrivateDoc(playerId),
          privateData,
          SetOptions(merge: true),
        );
      }
      await batch.commit();
      debugPrint('[FirebaseBridge] Published state for $joinCode');
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to publish: $e');
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

  /// Player: Send a join request (creates a claim in `joins` subcollection).
  Future<void> sendJoinRequest(String playerName) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      await gameDoc.collection('joins').add({
        'name': playerName,
        'uid': uid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to send join request: $e');
    }
  }

  /// Player: Send an action (vote/night action).
  Future<void> sendAction({
    required String stepId,
    required String playerId,
    String? targetId,
  }) async {
    try {
      await gameDoc.collection('actions').add({
        'stepId': stepId,
        'playerId': playerId,
        'targetId': targetId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to send action: $e');
    }
  }

  /// Player: Send a dead-pool bet action.
  Future<void> sendDeadPoolBet({
    required String playerId,
    required String targetPlayerId,
  }) async {
    try {
      await gameDoc.collection('actions').add({
        'type': 'dead_pool_bet',
        'playerId': playerId,
        'targetPlayerId': targetPlayerId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to send dead-pool bet: $e');
    }
  }

  /// Player: Send a ghost chat message.
  Future<void> sendGhostChat({
    required String playerId,
    required String message,
    String? playerName,
  }) async {
    try {
      await gameDoc.collection('actions').add({
        'type': 'ghost_chat',
        'playerId': playerId,
        'playerName': playerName,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to send ghost chat: $e');
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
      // Fetch all subcollections concurrently to reduce latency
      final snapshots = await Future.wait([
        gameDoc.collection('joins').get(),
        gameDoc.collection('actions').get(),
        gameDoc.collection('private_state').get(),
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
        await batch.commit();
      }

      await gameDoc.delete();
      debugPrint('[FirebaseBridge] Deleted game $joinCode');
    } catch (e) {
      debugPrint('[FirebaseBridge] Failed to delete game: $e');
    }
  }
}

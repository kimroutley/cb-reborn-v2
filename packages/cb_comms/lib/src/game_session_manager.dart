import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bridge.dart';
import 'offline_queue.dart';

/// Manages the lifecycle of a game session, including connection health (heartbeat),
/// action queuing (robustness), and automatic reconnection.
class GameSessionManager {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseBridge Function(String, FirebaseFirestore) _bridgeFactory;

  GameSessionManager({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseBridge Function(String, FirebaseFirestore)? bridgeFactory,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _bridgeFactory = bridgeFactory ??
            ((joinCode, firestore) =>
                FirebaseBridge(joinCode: joinCode, firestore: firestore));

  String? _currentJoinCode;
  String? _currentPlayerId;
  FirebaseBridge? _bridge;
  Timer? _heartbeatTimer;
  StreamSubscription? _connectionSub;

  final OfflineQueue _queue = OfflineQueue();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isProcessingQueue = false;

  // Connection State
  final _isConnectedController = StreamController<bool>.broadcast();
  Stream<bool> get isConnected => _isConnectedController.stream;

  /// Creates a new game session as a Host.
  Future<String> createSession(String joinCode, String hostName) async {
    // Auth check
    final user = _auth.currentUser;
    if (user == null) throw Exception("Must be signed in to host");

    await _firestore.collection('sessions').doc(joinCode).set({
      'hostId': user.uid,
      'hostName': hostName,
      'status': 'lobby',
      'createdAt': FieldValue.serverTimestamp(),
      'players': [],
    });

    _currentJoinCode = joinCode;
    return joinCode;
  }

  /// Joins an existing session.
  Future<void> joinSession(String joinCode, String playerName) async {
    // Ensure we have a user ID
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    _currentPlayerId = _auth.currentUser!.uid;

    final sessionRef = _firestore.collection('sessions').doc(joinCode);
    final snapshot = await sessionRef.get();

    if (!snapshot.exists) {
      throw Exception('Session not found');
    }

    _currentJoinCode = joinCode;

    // Initialize Offline Queue
    await _queue.init();
    if (_queue.joinCode != null && _queue.joinCode != joinCode) {
      // Different game session -> clear queue
      await _queue.clear();
    }

    // Initialize bridge
    _bridge = _bridgeFactory(joinCode, _firestore);

    // Start listening to the game doc to verify connection
    _connectionSub = _bridge!.subscribeToGame().listen(
      (snapshot) {
        if (snapshot.exists) {
          _isConnectedController.add(true);
        } else {
          _isConnectedController.add(false); // Game deleted or invalid code
        }
      },
      onError: (e) {
        debugPrint('[GameSessionManager] Connection error: $e');
        _isConnectedController.add(false);
      },
    );

    _startHeartbeat();
    _startConnectivityListener();
    _processQueue(); // Try sending any pending actions

    debugPrint('[GameSessionManager] Connected to $joinCode as $_currentPlayerId');
  }

  /// Cleanly disconnect and stop timers.
  Future<void> disconnect() async {
    _heartbeatTimer?.cancel();
    await _connectionSub?.cancel();
    await _connectivitySub?.cancel();
    _bridge = null;
    _currentJoinCode = null;
    _currentPlayerId = null;
    _isConnectedController.add(false);
    debugPrint('[GameSessionManager] Disconnected');
  }

  void _startConnectivityListener() {
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        debugPrint('[GameSessionManager] Online. Processing queue...');
        _processQueue();
      }
    });
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    if (_queue.queue.isEmpty) return;

    _isProcessingQueue = true;

    try {
      // Double check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.any((r) => r != ConnectivityResult.none)) {
        return;
      }

      debugPrint('[GameSessionManager] Processing ${_queue.queue.length} queued actions...');

      while (_queue.queue.isNotEmpty) {
        final action = _queue.queue.first;
        try {
          if (_bridge == null) {
            // If we are not connected to a bridge, we can't send.
            // Wait for reconnection.
            break;
          }

          await _bridge!.sendAction(
            stepId: action['stepId'],
            playerId: action['playerId'],
            targetId: action['targetId'],
          );

          await _queue.removeFirst();
          debugPrint('[GameSessionManager] Queued action sent successfully.');
        } catch (e) {
          debugPrint('[GameSessionManager] Failed to send queued action: $e');
          // Stop processing on error (preserve order)
          break;
        }
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Sends a "Heartbeat" timestamp to the player's document every 30s.
  /// This allows the Host to detect offline/crashed players.
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_bridge != null && _currentPlayerId != null) {
        _bridge!.playerPrivateDoc(_currentPlayerId!).set(
          {'lastHeartbeat': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        ).catchError((e) {
          debugPrint('[GameSessionManager] Heartbeat failed: $e');
        });
      }
    });
  }

  /// Robustly sends an action.
  Future<void> sendAction({
    required String stepId,
    required String targetId,
  }) async {
    if (_bridge == null || _currentPlayerId == null) {
      debugPrint('[GameSessionManager] Not connected. Attempting to queue action.');
      if (_currentJoinCode != null && _currentPlayerId != null) {
        await _queueAction(stepId, targetId);
      } else {
        debugPrint('[GameSessionManager] Cannot queue action: Missing session info.');
      }
      return;
    }

    try {
      // Check for immediate connectivity issue
      final connectivity = await Connectivity().checkConnectivity();
      if (!connectivity.any((r) => r != ConnectivityResult.none)) {
        throw Exception('Device is offline');
      }

      await _bridge!.sendAction(
        stepId: stepId,
        playerId: _currentPlayerId!,
        targetId: targetId,
      );
    } catch (e) {
      debugPrint('[GameSessionManager] Action send failed: $e. Queueing action.');
      await _queueAction(stepId, targetId);
    }
  }

  Future<void> _queueAction(String stepId, String targetId) async {
    if (_currentJoinCode == null || _currentPlayerId == null) return;

    await _queue.add(_currentJoinCode!, {
      'stepId': stepId,
      'playerId': _currentPlayerId,
      'targetId': targetId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}

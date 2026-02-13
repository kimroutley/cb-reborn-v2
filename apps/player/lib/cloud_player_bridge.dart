import 'dart:async';

import 'package:cb_comms/cb_comms_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'player_bridge.dart'; // re-use PlayerGameState, PlayerSnapshot, StepSnapshot, kDayVoteStepId
import 'player_bridge_actions.dart';

/// Cloud-mode player bridge using Firebase Firestore.
///
/// Replaces [PlayerBridge] when [SyncMode.cloud] is selected.
/// Subscribes to Firestore docs for game state instead of WebSocket.
class CloudPlayerBridge extends Notifier<PlayerGameState>
    implements PlayerBridgeActions {
  FirebaseBridge? _firebase;
  StreamSubscription? _gameSub;
  StreamSubscription? _privateSub;
  // Removed String? _claimedPlayerId; as it's now in PlayerGameState.myPlayerId

  @override
  PlayerGameState build() {
    // Return initial state
    return const PlayerGameState();
  }

  /// Join a cloud game by code.
  ///
  /// 1. Sends a join request doc to Firestore.
  /// 2. Subscribes to the public game doc.
  Future<void> joinWithCode(String code) async {
    // Reset connection errors before attempting to connect
    state = state.copyWith(
        joinError: null, myPlayerId: null, myPlayerSnapshot: null);

    try {
      await _gameSub?.cancel();
      await _privateSub?.cancel();
      _gameSub = null;
      _privateSub = null;

      // Ensure Firebase is initialized for cloud mode
      await FirebaseBridge.ensureInitialized(
        options: kIsWeb ? DefaultFirebaseOptions.currentPlatform : null,
      );

      _firebase = FirebaseBridge(joinCode: code);

      // Subscribe to public game state
      _gameSub = _firebase!.subscribeToGame().listen((snapshot) {
        final data = snapshot.data();
        if (data == null) return;
        _applyPublicState(data);
      });

      // Mark as connected and join accepted immediately (host will see the join request)
      state = state.copyWith(
        isConnected: true,
        joinAccepted: true,
        joinError: null,
      );

      debugPrint('[CloudPlayerBridge] Subscribed to game $code');
    } catch (e) {
      debugPrint('[CloudPlayerBridge] Connection or subscription failed: $e');
      state = state.copyWith(
        joinError: 'Failed to join game via cloud',
        isConnected: false,
        joinAccepted: false,
      );
      await disconnect(); // Ensure full disconnect on error
    }
  }

  @override
  Future<void> joinGame(String joinCode, String playerName) async {
    await joinWithCode(joinCode);
    await sendJoinRequest(playerName);
  }

  /// Send a join request (player name → joins subcollection).
  Future<void> sendJoinRequest(String playerName) async {
    if (_firebase == null) return;
    await _firebase!.sendJoinRequest(playerName);
    debugPrint('[CloudPlayerBridge] Join request sent: $playerName');
  }

  /// Claim a player identity and subscribe to their private state.
  @override
  Future<void> claimPlayer(String playerId) async {
    if (_firebase == null) return;

    // Subscribe to private state for this player
    _privateSub?.cancel();
    _privateSub = _firebase!.subscribeToPrivateState(playerId).listen((snap) {
      final data = snap.data();
      if (data == null) return;
      _applyPrivateState(data);
    });

    // Update state to reflect claimed player, will be validated by public state sync
    final claimedPlayer = state.players.firstWhere((p) => p.id == playerId);
    state = state.copyWith(
      claimedPlayerIds: [playerId],
      claimError: null,
      myPlayerId: playerId,
      myPlayerSnapshot: claimedPlayer,
    );

    debugPrint('[CloudPlayerBridge] Claimed player $playerId');
  }

  /// Send a vote action to Firestore.
  @override
  Future<void> vote({required String voterId, required String targetId}) async {
    _firebase?.sendAction(
      stepId: kDayVoteStepId,
      playerId: voterId,
      targetId: targetId,
    );
  }

  /// Send a night action or other step action.
  @override
  Future<void> sendAction({
    required String stepId,
    required String targetId,
    String? voterId,
  }) async {
    _firebase?.sendAction(
      stepId: stepId,
      playerId: voterId ?? state.myPlayerId ?? '',
      targetId: targetId,
    );
  }

  @override
  Future<void> placeDeadPoolBet({
    required String playerId,
    required String targetPlayerId,
  }) async {
    _firebase?.sendDeadPoolBet(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
    );
  }

  @override
  Future<void> sendGhostChat({
    required String playerId,
    required String message,
    String? playerName,
  }) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return;
    }
    _firebase?.sendGhostChat(
      playerId: playerId,
      message: trimmed,
      playerName: playerName,
    );
  }

  /// Leave: just disconnect.
  @override
  Future<void> leave() async {
    await disconnect();
  }

  /// Disconnect and clean up all subscriptions.
  Future<void> disconnect() async {
    await _gameSub?.cancel();
    await _privateSub?.cancel();
    _gameSub = null;
    _privateSub = null;
    _firebase = null;
    state = const PlayerGameState(); // Reset to initial state
    debugPrint('[CloudPlayerBridge] Disconnected');
  }

  // ─── INBOUND ──────────────────────────────────

  void _applyPublicState(Map<String, dynamic> data) {
    final playersRaw = data['players'] as List<dynamic>?;
    final players = playersRaw
            ?.map((e) => PlayerSnapshot.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    final stepData = data['currentStep'] as Map<String, dynamic>?;
    final step = stepData != null ? StepSnapshot.fromMap(stepData) : null;

    final tallyRaw = data['voteTally'] as Map<String, dynamic>?;
    final tally = tallyRaw?.map((k, v) => MapEntry(k, v as int)) ?? {};

    final votesByVoterRaw = data['votesByVoter'] as Map<String, dynamic>?;
    final votesByVoter = votesByVoterRaw?.map(
          (k, v) => MapEntry(k, v as String),
        ) ??
        {};

    final privatesRaw = data['privateMessages'] as Map<String, dynamic>?;
    final privates = privatesRaw?.map(
          (k, v) => MapEntry(k, _toStringList(v)),
        ) ??
        {};

    final deadPoolRaw = data['deadPoolBets'] as Map<String, dynamic>?;
    final deadPoolBets = deadPoolRaw?.map(
          (k, v) => MapEntry(k, v.toString()),
        ) ??
        {};

    final phase = data['phase'] as String? ?? 'lobby';

    // Detect returnToLobby: host reset to lobby with no players
    final isNewLobby = phase == 'lobby' && players.isEmpty;

    // Determine myPlayerId and myPlayerSnapshot after receiving new players list
    final String? updatedMyPlayerId =
        state.myPlayerId != null && players.any((p) => p.id == state.myPlayerId)
            ? state.myPlayerId
            : null;
    final PlayerSnapshot? updatedMyPlayerSnapshot = updatedMyPlayerId != null
        ? players.firstWhere((p) => p.id == updatedMyPlayerId)
        : null;

    state = state.copyWith(
      phase: phase,
      dayCount: data['dayCount'] as int? ?? 0,
      players: players,
      currentStep: step,
      winner: data['winner'] as String?,
      endGameReport: _toStringList(data['endGameReport']),
      voteTally: tally,
      votesByVoter: votesByVoter,
      nightReport: _toStringList(data['nightReport']),
      dayReport: _toStringList(data['dayReport']),
      privateMessages: privates,
      claimedPlayerIds:
          isNewLobby ? const [] : _toStringList(data['claimedPlayerIds']),
      gameHistory: _toStringList(data['gameHistory']),
      deadPoolBets: deadPoolBets,
      ghostChatMessages: state.ghostChatMessages,
      isConnected: true,
      joinAccepted: isNewLobby ? false : state.joinAccepted,
      joinError: state.joinError,
      claimError: state.claimError,
      myPlayerId: updatedMyPlayerId, // Set updated ID
      myPlayerSnapshot: updatedMyPlayerSnapshot, // Set updated snapshot
    );
  }

  /// Merge private state (role, alliance, etc.) into the existing
  /// player snapshot for the claimed player.
  void _applyPrivateState(Map<String, dynamic> data) {
    if (state.myPlayerId == null) return;

    final updatedPlayers = state.players.map((p) {
      if (p.id != state.myPlayerId) return p;
      return PlayerSnapshot(
        id: p.id,
        name: p.name,
        roleId: data['roleId'] as String? ?? p.roleId,
        roleName: data['roleName'] as String? ?? p.roleName,
        roleDescription:
            data['roleDescription'] as String? ?? p.roleDescription,
        roleColorHex: data['roleColorHex'] as String? ?? p.roleColorHex,
        alliance: data['alliance'] as String? ?? p.alliance,
        isAlive: p.isAlive,
        deathDay: p.deathDay,
        silencedDay: data['silencedDay'] as int? ?? p.silencedDay,
        medicChoice: data['medicChoice'] as String? ?? p.medicChoice,
        lives: data['lives'] as int? ?? p.lives,
        hasRumour: p.hasRumour,
        clingerPartnerId:
            data['clingerPartnerId'] as String? ?? p.clingerPartnerId,
        hasReviveToken: data['hasReviveToken'] as bool? ?? p.hasReviveToken,
        secondWindPendingConversion:
            data['secondWindPendingConversion'] as bool? ??
                p.secondWindPendingConversion,
        creepTargetId: data['creepTargetId'] as String? ?? p.creepTargetId,
        whoreDeflectionUsed:
            data['whoreDeflectionUsed'] as bool? ?? p.whoreDeflectionUsed,
        tabooNames: _toStringList(data['tabooNames']),
      );
    }).toList();

    // Also merge private messages
    final privateMessages = <String, List<String>>{...state.privateMessages};
    final myMessages = data['privateMessages'];
    if (myMessages != null) {
      privateMessages[state.myPlayerId!] = _toStringList(myMessages);
    }

    final ghostMessages = privateMessages[state.myPlayerId!]
            ?.where((m) => m.startsWith('[GHOST] '))
            .map((m) => m.replaceFirst('[GHOST] ', ''))
            .toList() ??
        const <String>[];

    final updatedMyPlayerSnapshot =
        updatedPlayers.firstWhere((p) => p.id == state.myPlayerId);

    state = state.copyWith(
      players: updatedPlayers,
      privateMessages: privateMessages,
      ghostChatMessages: ghostMessages,
      myPlayerSnapshot: updatedMyPlayerSnapshot,
    );
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}

/// Riverpod provider for [CloudPlayerBridge].
final cloudPlayerBridgeProvider =
    NotifierProvider<CloudPlayerBridge, PlayerGameState>(() {
  return CloudPlayerBridge();
});

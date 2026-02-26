import 'dart:async';

import 'package:cb_comms/cb_comms_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'player_bridge.dart'; // re-use PlayerGameState, PlayerSnapshot, StepSnapshot, kDayVoteStepId
import 'player_bridge_actions.dart';
import 'player_session_cache.dart';
import 'package:cb_models/cb_models.dart';

/// Cloud-mode player bridge using Firebase Firestore.
///
/// Replaces [PlayerBridge] when [SyncMode.cloud] is selected.
/// Subscribes to Firestore docs for game state instead of WebSocket.
class CloudPlayerBridge extends Notifier<PlayerGameState>
    implements PlayerBridgeActions {
  static const Duration _initialSnapshotTimeout = Duration(seconds: 20);

  FirebaseBridge? _firebase;
  StreamSubscription? _gameSub;
  StreamSubscription? _privateSub;
  String? _cachedJoinCode;
  String? _cachedPlayerName;

  @override
  PlayerGameState build() {
    // Return initial state
    return const PlayerGameState();
  }

  void restoreFromCache(PlayerSessionCacheEntry entry) {
    _cachedJoinCode = entry.joinCode;
    _cachedPlayerName = entry.playerName;
    state = PlayerGameState.fromCacheMap(entry.state);
  }

  /// Join a cloud game by code.
  ///
  /// 1. Sends a join request doc to Firestore.
  /// 2. Subscribes to the public game doc.
  Future<void> joinWithCode(String code) async {
    _cachedJoinCode = code.trim().toUpperCase();

    // Reset connection state before attempting to connect.
    state = state.copyWith(
      joinError: null,
      joinAccepted: false,
      isConnected: false,
      myPlayerId: null,
      myPlayerSnapshot: null,
    );

    final firstSnapshotReady = Completer<void>();

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
        if (!firstSnapshotReady.isCompleted) {
          firstSnapshotReady.complete();
        }
      }, onError: (error) {
        if (!firstSnapshotReady.isCompleted) {
          firstSnapshotReady.completeError(error);
        }
      });

      // Wait for the first public game snapshot before declaring the join
      // successful. This prevents false-positive "connected" UI states when
      // cloud data is unavailable or delayed.
      await firstSnapshotReady.future.timeout(
        _initialSnapshotTimeout,
        onTimeout: () => throw TimeoutException(
          'Cloud join timed out. Confirm the host lobby is live, your code is correct, and try again.',
        ),
      );

      state = state.copyWith(isConnected: true, joinAccepted: true);
      _persistSessionCache();

      debugPrint('[CloudPlayerBridge] Subscribed to game $code');
    } on TimeoutException catch (e) {
      await disconnect();
      final message = e.message ?? 'Cloud join timed out. Confirm host lobby is live and retry.';
      state = state.copyWith(
        joinError: message,
        isConnected: false,
        joinAccepted: false,
      );
      _persistSessionCache();
      rethrow;
    } catch (e) {
      debugPrint('[CloudPlayerBridge] Connection or subscription failed: $e');
      await disconnect(); // Ensure full disconnect on error.
      state = state.copyWith(
        joinError: 'Failed to join game via cloud. Please retry.',
        isConnected: false,
        joinAccepted: false,
      );
      _persistSessionCache();
      throw Exception(state.joinError);
    }
  }

  @override
  Future<void> joinGame(String joinCode, String playerName) async {
    final resolvedName =
        playerName.trim().isEmpty ? 'Player' : playerName.trim();
    _cachedPlayerName = resolvedName;
    await joinWithCode(joinCode);
    await sendJoinRequest(resolvedName);
    _persistSessionCache();
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
    _persistSessionCache();

    debugPrint('[CloudPlayerBridge] Claimed player $playerId');
  }

  /// Send a vote action to Firestore.
  @override
  Future<void> vote({required String voterId, required String targetId}) async {
    if (_firebase == null) return;
    await _firebase!.sendAction(
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
    if (_firebase == null) return;
    await _firebase!.sendAction(
      stepId: stepId,
      playerId: voterId ?? state.myPlayerId ?? '',
      targetId: targetId,
    );
  }

  @override
  Future<void> confirmRole({required String playerId}) async {
    if (_firebase == null) return;
    await _firebase!.sendRoleConfirm(playerId: playerId);
  }

  @override
  Future<void> placeDeadPoolBet({
    required String playerId,
    required String targetPlayerId,
  }) async {
    if (_firebase == null) return;
    await _firebase!.sendDeadPoolBet(
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
    if (_firebase == null) return;
    await _firebase!.sendGhostChat(
      playerId: playerId,
      message: trimmed,
      playerName: playerName,
    );
  }

  @override
  Future<void> sendBulletin({
    required String title,
    required String floatContent,
    String? roleId,
  }) async {
    // Write directly to actions collection or dedicated chats?
    // Using a generic action type 'chat' via firebase bridge helper
    if (_firebase == null) return;

    // We assume the host listens for actions with type='chat'
    // or we add a specific method to firebase bridge.
    // For now, let's assume we can use sendAction-like mechanism but labeled as chat.
    // Or we extend FirebaseBridge.

    // Actually, let's rely on FirebaseBridge having a generic 'sendBulletin' or 'sendChat'
    // I will add 'sendChat' to FirebaseBridge in subsequent step.
    await _firebase!.sendChat(
      title: title,
      message: floatContent,
      roleId: roleId,
    );
  }

  /// Leave: just disconnect.
  @override
  Future<void> leave() async {
    await ref.read(playerSessionCacheRepositoryProvider).clear();
    _cachedJoinCode = null;
    _cachedPlayerName = null;
    await disconnect();
  }

  /// Disconnect and clean up all subscriptions.
  Future<void> disconnect() async {
    await _gameSub?.cancel();
    await _privateSub?.cancel();
    _gameSub = null;
    _privateSub = null;
    _firebase = null;
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

    final bulletinRaw = data['bulletinBoard'] as List<dynamic>?;
    final bulletinBoard = bulletinRaw
            ?.map((e) => BulletinEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final phase = data['phase'] as String? ?? 'lobby';

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
      claimedPlayerIds: _toStringList(data['claimedPlayerIds']),
      roleConfirmedPlayerIds: _toStringList(data['roleConfirmedPlayerIds']),
      gameHistory: _toStringList(data['gameHistory']),
      deadPoolBets: deadPoolBets,
      bulletinBoard: bulletinBoard,
      ghostChatMessages: state.ghostChatMessages,
      isConnected: true,
      joinAccepted: true,
      joinError: state.joinError,
      claimError: state.claimError,
      myPlayerId: updatedMyPlayerId,
      myPlayerSnapshot: updatedMyPlayerSnapshot,
      rematchOffered: data['rematchOffered'] as bool? ?? false,
    );

    _attemptAutoClaim(state);
    _persistSessionCache();
  }

  void _attemptAutoClaim(PlayerGameState gameState) {
    if (gameState.myPlayerId != null) return;

    // Try authUid matching first (strongest signal).
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final uidMatch = gameState.players.cast<PlayerSnapshot?>().firstWhere(
        (p) => p?.authUid == uid,
        orElse: () => null,
      );
      if (uidMatch != null) {
        claimPlayer(uidMatch.id);
        return;
      }
    }

    // Fallback: match by the player name sent during joinGame.
    final pendingName = _cachedPlayerName?.trim();
    if (pendingName == null || pendingName.isEmpty) return;

    final claimed = gameState.claimedPlayerIds.toSet();
    final nameMatch = gameState.players.cast<PlayerSnapshot?>().firstWhere(
      (p) =>
          p != null &&
          !claimed.contains(p.id) &&
          p.name.trim().toLowerCase() == pendingName.toLowerCase(),
      orElse: () => null,
    );

    if (nameMatch != null) {
      claimPlayer(nameMatch.id);
    }
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
        blockedVoteTargets: _toStringList(data['blockedVoteTargets']),
      );
    }).toList();

    // Also merge private messages
    final privateMessages = <String, List<String>>{...state.privateMessages};
    final myMessages = data['privateMessages'];
    if (myMessages != null) {
      privateMessages[state.myPlayerId!] = _toStringList(myMessages);
    }

    // Prefer structured ghost_messages field; fall back to parsing privateMessages.
    final ghostMessagesRaw = data['ghost_messages'] as List<dynamic>?;
    final List<String> ghostMessages;
    if (ghostMessagesRaw != null) {
      ghostMessages = ghostMessagesRaw
          .map((m) => (m as Map<String, dynamic>)['message'] as String? ?? '')
          .where((m) => m.isNotEmpty)
          .toList();
    } else {
      ghostMessages = (privateMessages[state.myPlayerId!] ?? const <String>[])
          .where((m) => m.startsWith('[GHOST] '))
          .map((m) => m.replaceFirst('[GHOST] ', ''))
          .toList();
    }

    final updatedMyPlayerSnapshot =
        updatedPlayers.firstWhere((p) => p.id == state.myPlayerId);

    state = state.copyWith(
      players: updatedPlayers,
      privateMessages: privateMessages,
      ghostChatMessages: ghostMessages,
      myPlayerSnapshot: updatedMyPlayerSnapshot,
    );
    _persistSessionCache();
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  void _persistSessionCache() {
    final joinCode = _cachedJoinCode;
    if (joinCode == null || joinCode.isEmpty) {
      return;
    }

    final entry = PlayerSessionCacheEntry(
      joinCode: joinCode,
      mode: CachedSyncMode.cloud,
      playerName: _cachedPlayerName,
      savedAt: DateTime.now(),
      state: state.toCacheMap(),
    );
    unawaited(
      ref.read(playerSessionCacheRepositoryProvider).saveSession(entry),
    );
  }
}

/// Riverpod provider for [CloudPlayerBridge].
final cloudPlayerBridgeProvider =
    NotifierProvider<CloudPlayerBridge, PlayerGameState>(() {
  return CloudPlayerBridge();
});

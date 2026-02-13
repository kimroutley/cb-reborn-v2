import 'package:cb_comms/cb_comms.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cb_theme/cb_theme.dart';

import 'player_bridge_actions.dart';
import 'room_effects_provider.dart';
import 'player_stats.dart';

/// Constant for the 'day_vote' step ID.
const String kDayVoteStepId = 'day_vote';

const Object _undefined = Object();

/// Lightweight local state mirrored from Host via WebSocket.
///
/// The player app does NOT run its own GameProvider — it receives
/// [GameMessage.stateSync] from the host and parses it into this state.
class PlayerGameState {
  final String phase;
  final int dayCount;
  final List<PlayerSnapshot> players;
  final StepSnapshot? currentStep;
  final List<BulletinEntry> bulletinBoard;
  final bool eyesOpen;
  final String? winner;
  final List<String> endGameReport;
  final Map<String, int> voteTally;
  final Map<String, String> votesByVoter;
  final List<String> nightReport;
  final List<String> dayReport;
  final Map<String, List<String>> privateMessages;
  final List<String> claimedPlayerIds;
  final List<String> gameHistory;
  final Map<String, String> deadPoolBets;
  final List<String> ghostChatMessages;
  final bool isConnected;
  final String? joinError;
  final bool joinAccepted;
  final String? claimError;
  final String? kickedMessage;
  final String? myPlayerId; // New: ID of the player this client has claimed
  final PlayerSnapshot? myPlayerSnapshot; // New: Snapshot of the claimed player

  // God Mode Effects
  final String? activeEffect;
  final Map<String, dynamic>? activeEffectPayload;

  // New: Host info
  final String? hostName;

  const PlayerGameState({
    this.phase = 'lobby',
    this.dayCount = 0,
    this.players = const [],
    this.currentStep,
    this.bulletinBoard = const [],
    this.eyesOpen = true,
    this.winner,
    this.endGameReport = const [],
    this.voteTally = const {},
    this.votesByVoter = const {},
    this.nightReport = const [],
    this.dayReport = const [],
    this.privateMessages = const {},
    this.claimedPlayerIds = const [],
    this.gameHistory = const [],
    this.deadPoolBets = const {},
    this.ghostChatMessages = const [],
    this.isConnected = false,
    this.joinError,
    this.joinAccepted = false,
    this.claimError,
    this.kickedMessage,
    this.myPlayerId,
    this.myPlayerSnapshot,
    this.activeEffect,
    this.activeEffectPayload,
    this.hostName,
  });

  bool get isLobby => phase == 'lobby';
  bool get isEndGame => phase == 'endGame';
  bool get isPlayerClaimed => myPlayerId != null;

  PlayerGameState copyWith({
    String? phase,
    int? dayCount,
    List<PlayerSnapshot>? players,
    dynamic currentStep = _undefined,
    List<BulletinEntry>? bulletinBoard,
    bool? eyesOpen,
    dynamic winner = _undefined,
    List<String>? endGameReport,
    Map<String, int>? voteTally,
    Map<String, String>? votesByVoter,
    List<String>? nightReport,
    List<String>? dayReport,
    Map<String, List<String>>? privateMessages,
    List<String>? claimedPlayerIds,
    List<String>? gameHistory,
    Map<String, String>? deadPoolBets,
    List<String>? ghostChatMessages,
    bool? isConnected,
    dynamic joinError = _undefined,
    bool? joinAccepted,
    String? claimError,
    String? kickedMessage,
    String? myPlayerId,
    PlayerSnapshot? myPlayerSnapshot,
    String? activeEffect,
    Map<String, dynamic>? activeEffectPayload,
    String? hostName,
    dynamic claimError = _undefined,
    dynamic kickedMessage = _undefined,
    dynamic myPlayerId = _undefined,
    dynamic myPlayerSnapshot = _undefined,
    dynamic activeEffect = _undefined,
    dynamic activeEffectPayload = _undefined,
  }) {
    return PlayerGameState(
      phase: phase ?? this.phase,
      dayCount: dayCount ?? this.dayCount,
      players: players ?? this.players,
      currentStep: currentStep == _undefined
          ? this.currentStep
          : currentStep as StepSnapshot?,
      bulletinBoard: bulletinBoard ?? this.bulletinBoard,
      eyesOpen: eyesOpen ?? this.eyesOpen,
      winner: winner == _undefined ? this.winner : winner as String?,
      endGameReport: endGameReport ?? this.endGameReport,
      voteTally: voteTally ?? this.voteTally,
      votesByVoter: votesByVoter ?? this.votesByVoter,
      nightReport: nightReport ?? this.nightReport,
      dayReport: dayReport ?? this.dayReport,
      privateMessages: privateMessages ?? this.privateMessages,
      claimedPlayerIds: claimedPlayerIds ?? this.claimedPlayerIds,
      gameHistory: gameHistory ?? this.gameHistory,
      deadPoolBets: deadPoolBets ?? this.deadPoolBets,
      ghostChatMessages: ghostChatMessages ?? this.ghostChatMessages,
      isConnected: isConnected ?? this.isConnected,
      joinError: joinError == _undefined ? this.joinError : joinError as String?,
      joinAccepted: joinAccepted ?? this.joinAccepted,
      claimError: claimError ?? this.claimError,
      kickedMessage: kickedMessage ?? this.kickedMessage,
      myPlayerId: myPlayerId ?? this.myPlayerId,
      myPlayerSnapshot: myPlayerSnapshot ?? this.myPlayerSnapshot,
      activeEffect:
          activeEffect, // Note: Always replace with new effect, not merge
      activeEffectPayload: activeEffectPayload,
      hostName: hostName ?? this.hostName,
      claimError:
          claimError == _undefined ? this.claimError : claimError as String?,
      kickedMessage: kickedMessage == _undefined
          ? this.kickedMessage
          : kickedMessage as String?,
      myPlayerId:
          myPlayerId == _undefined ? this.myPlayerId : myPlayerId as String?,
      myPlayerSnapshot: myPlayerSnapshot == _undefined
          ? this.myPlayerSnapshot
          : myPlayerSnapshot as PlayerSnapshot?,
      activeEffect: activeEffect == _undefined
          ? this.activeEffect
          : activeEffect as String?,
      activeEffectPayload: activeEffectPayload == _undefined
          ? this.activeEffectPayload
          : activeEffectPayload as Map<String, dynamic>?,
    );
  }
}

/// Minimal player snapshot received from host.
class PlayerSnapshot {
  final String id;
  final String name;
  final String roleId;
  final String roleName;
  final String roleDescription;
  final String roleColorHex;
  final String alliance;
  final bool isAlive;
  final int? deathDay;
  final int? silencedDay;
  final String? medicChoice;
  final int lives;
  final int drinksOwed;
  final String? currentBetTargetId;
  final List<String> penalties;
  final bool hasRumour;
  final String? clingerPartnerId;
  final bool hasReviveToken;
  final bool secondWindPendingConversion;
  final String? creepTargetId;
  final bool whoreDeflectionUsed;
  final List<String> tabooNames;

  const PlayerSnapshot({
    required this.id,
    required this.name,
    required this.roleId,
    required this.roleName,
    this.roleDescription = '',
    this.roleColorHex = '#888888',
    this.alliance = 'unknown',
    this.isAlive = true,
    this.deathDay,
    this.silencedDay,
    this.medicChoice,
    this.lives = 1,
    this.drinksOwed = 0,
    this.currentBetTargetId,
    this.penalties = const [],
    this.hasRumour = false,
    this.clingerPartnerId,
    this.hasReviveToken = false,
    this.secondWindPendingConversion = false,
    this.creepTargetId,
    this.whoreDeflectionUsed = false,
    this.tabooNames = const [],
  });

  factory PlayerSnapshot.fromMap(Map<String, dynamic> map) {
    return PlayerSnapshot(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      roleId: map['roleId'] as String? ?? '',
      roleName: map['roleName'] as String? ?? '',
      roleDescription: map['roleDescription'] as String? ?? '',
      roleColorHex: map['roleColorHex'] as String? ?? '#888888',
      alliance: map['alliance'] as String? ?? 'unknown',
      isAlive: map['isAlive'] as bool? ?? true,
      deathDay: map['deathDay'] as int?,
      silencedDay: map['silencedDay'] as int?,
      medicChoice: map['medicChoice'] as String?,
      lives: map['lives'] as int? ?? 1,
      drinksOwed: map['drinksOwed'] as int? ?? 0,
      currentBetTargetId: map['currentBetTargetId'] as String?,
      penalties: (map['penalties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hasRumour: map['hasRumour'] as bool? ?? false,
      clingerPartnerId: map['clingerPartnerId'] as String?,
      hasReviveToken: map['hasReviveToken'] as bool? ?? false,
      secondWindPendingConversion:
          map['secondWindPendingConversion'] as bool? ?? false,
      creepTargetId: map['creepTargetId'] as String?,
      whoreDeflectionUsed: map['whoreDeflectionUsed'] as bool? ?? false,
      tabooNames: (map['tabooNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  bool get isClubStaff => alliance == 'clubStaff';
  bool get isPartyAnimal => alliance == 'partyAnimals';
}

/// Step snapshot received from host.
class StepSnapshot {
  final String id;
  final String title;
  final String readAloudText;
  final String instructionText;
  final String actionType;
  final String? roleId;
  final List<String> options;
  final int? timerSeconds;
  final bool isOptional;

  const StepSnapshot({
    required this.id,
    required this.title,
    required this.readAloudText,
    this.instructionText = '',
    this.actionType = 'readAloud',
    this.roleId,
    this.options = const [],
    this.timerSeconds,
    this.isOptional = false,
  });

  factory StepSnapshot.fromMap(Map<String, dynamic> map) {
    return StepSnapshot(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      readAloudText: map['readAloudText'] as String? ?? '',
      instructionText: map['instructionText'] as String? ?? '',
      actionType: map['actionType'] as String? ?? 'readAloud',
      roleId: map['roleId'] as String?,
      options: (map['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timerSeconds: map['timerSeconds'] as int?,
      isOptional: map['isOptional'] as bool? ?? false,
    );
  }

  bool get isVote => id == kDayVoteStepId;
}

/// Bridges the PlayerClient WebSocket to a Riverpod state notifier.
///
/// Usage:
/// ```dart
/// final bridge = ref.read(playerBridgeProvider.notifier);
/// await bridge.connect('ws://192.168.1.5:8080');
/// bridge.joinWithCode('NEON-7731');
/// ```
class PlayerBridge extends Notifier<PlayerGameState>
    implements PlayerBridgeActions {
  /// Testing injection point for PlayerClient
  @visibleForTesting
  static PlayerClient Function({
    void Function(GameMessage)? onMessage,
    void Function(PlayerConnectionState)? onConnectionChanged,
  })? mockClientFactory;

  PlayerClient? _client;
  PlayerConnectionState _connectionState = PlayerConnectionState.disconnected;

  @override
  PlayerGameState build() {
    // Return initial state
    return const PlayerGameState();
  }

  PlayerConnectionState get connectionState => _connectionState;

  /// Connect to the host's WebSocket server.
  Future<void> connect(String url) async {
    // Reset connection errors before attempting to connect
    state = state.copyWith(joinError: null, claimedPlayerIds: []);

    if (_client != null) {
      await _client!.disconnect();
      _client = null;
    }

    final onMessage = _handleMessage;
    final onConnectionChanged = (PlayerConnectionState newState) {
      final prevState = _connectionState;
      _connectionState = newState;
      debugPrint('[PlayerBridge] Connection: ${newState.name}');

      // On reconnection: send reconnect with claimed IDs to restore state
      if (newState == PlayerConnectionState.connected &&
          prevState == PlayerConnectionState.reconnecting &&
          state.myPlayerId != null) {
        debugPrint(
            '[PlayerBridge] Reconnected — sending player_reconnect for ${state.myPlayerId}');
        _client?.send(GameMessage.playerReconnect(
          claimedPlayerIds: [state.myPlayerId!],
        ));
      }

      // Preserve join/claim state across reconnection
      state = state.copyWith(
        isConnected: newState == PlayerConnectionState.connected,
      );
    };

    if (mockClientFactory != null) {
      _client = mockClientFactory!(
        onMessage: onMessage,
        onConnectionChanged: onConnectionChanged,
      );
    } else {
      _client = PlayerClient(
        onMessage: onMessage,
        onConnectionChanged: onConnectionChanged,
      );
    }

    try {
      await _client!.connect(url);
    } catch (e) {
      debugPrint('[PlayerBridge] Connection failed: $e');
      state = state.copyWith(joinError: 'Failed to connect to host');
      await disconnect(); // Ensure client is fully disconnected on error
    }
  }

  /// Disconnect from host.
  Future<void> disconnect() async {
    await _client?.disconnect();
    _client = null;
    state = const PlayerGameState(); // Reset to initial state
  }

  // ─── OUTBOUND ─────────────────────────────────

  void joinWithCode(String code) => _client?.joinWithCode(code);

  @override
  Future<void> joinGame(String joinCode, String playerName) async {
    joinWithCode(joinCode);
  }

  @override
  Future<void> claimPlayer(String playerId) async {
    _client?.claimPlayer(playerId);
  }

  @override
  Future<void> vote({required String voterId, required String targetId}) async {
    _client?.vote(voterId: voterId, targetId: targetId);
  }

  @override
  Future<void> sendAction({
    required String stepId,
    required String targetId,
    String? voterId,
  }) async {
    _client?.send(GameMessage.playerAction(
      stepId: stepId,
      targetId: targetId,
      voterId: voterId,
    ));
  }

  @override
  Future<void> placeDeadPoolBet({
    required String playerId,
    required String targetPlayerId,
  }) async {
    _client?.send(GameMessage.playerBet(
      playerId: playerId,
      targetPlayerId: targetPlayerId,
    ));
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
    _client?.send(GameMessage.ghostChat(
      playerId: playerId,
      message: trimmed,
      playerName: playerName,
    ));
  }

  @override
  Future<void> leave() async {
    final playerId = state.myPlayerId;
    if (playerId != null) {
      _client?.leave(playerId);
    }
    await disconnect();
  }

  // ─── INBOUND ──────────────────────────────────

  void _handleMessage(GameMessage msg) {
    switch (msg.type) {
      case 'state_sync':
        _applyStateSync(msg.payload);
        break;
      case 'step_update':
        _applyStepUpdate(msg.payload);
        break;
      case 'player_kicked':
        final kickedId = msg.payload['playerId'] as String?;
        debugPrint('[PlayerBridge] Kicked: $kickedId');
        // If we are the kicked player, reset claim state
        if (kickedId != null && kickedId == state.myPlayerId) {
          state = state.copyWith(
            claimedPlayerIds: [], // Clear all claimed IDs if our ID is removed
            myPlayerId: null,
            myPlayerSnapshot: null,
            joinAccepted: false,
            claimError: null,
            kickedMessage: 'You were removed from the game',
          );
        }
        break;
      case 'join_response':
        final accepted = msg.payload['accepted'] as bool? ?? false;
        final error = msg.payload['error'] as String?;
        debugPrint('[PlayerBridge] Join ${accepted ? "accepted" : "rejected"}');
        if (accepted) {
          state = state.copyWith(
            joinAccepted: true,
            joinError: null,
          );
        } else {
          state = state.copyWith(
            joinAccepted: false,
            joinError: error ?? 'Join rejected',
          );
        }
        break;
      case 'claim_response':
        final success = msg.payload['success'] as bool? ?? false;
        final playerId = msg.payload['playerId'] as String?;
        debugPrint('[PlayerBridge] Claim ${success ? "ok" : "failed"}');
        if (success && playerId != null) {
          final claimedPlayer =
              state.players.firstWhere((p) => p.id == playerId);
          state = state.copyWith(
            claimedPlayerIds: [...state.claimedPlayerIds, playerId],
            claimError: null,
            myPlayerId: playerId,
            myPlayerSnapshot: claimedPlayer,
          );
        } else {
          state = state.copyWith(
            claimError: 'Could not claim player',
          );
        }
        break;
      case 'effect':
        final effectType = msg.payload['effectType'] as String;
        final effectPayload = msg.payload['payload'] as Map<String, dynamic>?;
        ref
            .read(roomEffectsProvider.notifier)
            .triggerEffect(effectType, effectPayload);
        break;
      case 'sound':
        final soundId = msg.payload['soundId'] as String;
        final volume = msg.payload['volume'] as double?;
        SoundService.playSfx(soundId, volume: volume);
        break;
      case 'ghost_chat':
        final playerName = msg.payload['playerName'] as String? ?? 'Ghost';
        final message = msg.payload['message'] as String? ?? '';
        if (message.isNotEmpty) {
          state = state.copyWith(
            ghostChatMessages: [
              ...state.ghostChatMessages,
              '$playerName: $message'
            ],
          );
        }
        break;
      default:
        debugPrint('[PlayerBridge] Unknown: ${msg.type}');
    }
  }

  void _applyStateSync(Map<String, dynamic> payload) {
    final prevPhase = state.phase;
    final players = (payload['players'] as List<dynamic>?)
            ?.map((e) => PlayerSnapshot.fromMap(e as Map<String, dynamic>))
            .toList() ??
        [];

    final stepData = payload['currentStep'] as Map<String, dynamic>?;
    final step = stepData != null ? StepSnapshot.fromMap(stepData) : null;

    final bulletinRaw = payload['bulletinBoard'] as List<dynamic>?;
    final bulletin = bulletinRaw
            ?.map((e) => BulletinEntry.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final eyesOpen = payload['eyesOpen'] as bool? ?? true;

    final tallyRaw = payload['voteTally'] as Map<String, dynamic>?;
    final tally = tallyRaw?.map((k, v) => MapEntry(k, v as int)) ?? {};

    final votesByVoterRaw = payload['votesByVoter'] as Map<String, dynamic>?;
    final votesByVoter = votesByVoterRaw?.map(
          (k, v) => MapEntry(k, v as String),
        ) ??
        {};

    final privatesRaw = payload['privateMessages'] as Map<String, dynamic>?;
    final privates = privatesRaw?.map(
          (k, v) => MapEntry(k, _toStringList(v)),
        ) ??
        {};

    final deadPoolRaw = payload['deadPoolBets'] as Map<String, dynamic>?;
    final deadPoolBets = deadPoolRaw?.map(
          (k, v) => MapEntry(k, v.toString()),
        ) ??
        {};

    final phase = payload['phase'] as String? ?? 'lobby';

    // Detect returnToLobby: host reset to lobby with no players
    // → clear local join/claim state so player can re-join the next game
    final isNewLobby = phase == 'lobby' && players.isEmpty;

    // Determine myPlayerId and myPlayerSnapshot after receiving new players list
    final String? updatedMyPlayerId =
        state.myPlayerId != null && players.any((p) => p.id == state.myPlayerId)
            ? state.myPlayerId
            : null;
    final PlayerSnapshot? updatedMyPlayerSnapshot = updatedMyPlayerId != null
        ? players.firstWhere((p) => p.id == updatedMyPlayerId)
        : null;

    final nextState = PlayerGameState(
      phase: phase,
      dayCount: payload['dayCount'] as int? ?? 0,
      players: players,
      currentStep: step,
      bulletinBoard: bulletin,
      eyesOpen: eyesOpen,
      winner: payload['winner'] as String?,
      endGameReport: _toStringList(payload['endGameReport']),
      voteTally: tally,
      votesByVoter: votesByVoter,
      nightReport: _toStringList(payload['nightReport']),
      dayReport: _toStringList(payload['dayReport']),
      privateMessages: privates,
      claimedPlayerIds:
          isNewLobby ? const [] : _toStringList(payload['claimedPlayerIds']),
      gameHistory: _toStringList(payload['gameHistory']),
      deadPoolBets: deadPoolBets,
      ghostChatMessages: [
        ...(state.ghostChatMessages),
        ...(_toStringList(privates[updatedMyPlayerId])
            .where((m) => m.startsWith('[GHOST] '))
            .map((m) => m.replaceFirst('[GHOST] ', ''))),
      ].toSet().toList(),
      isConnected: state.isConnected,
      joinAccepted: isNewLobby ? false : state.joinAccepted,
      joinError: state.joinError,
      claimError: state.claimError,
      myPlayerId: updatedMyPlayerId, // Set updated ID
      myPlayerSnapshot: updatedMyPlayerSnapshot, // Set updated snapshot
      hostName: payload['hostName'] as String?,
    );

    state = nextState;

    // Refresh active player stats view once when the game ends.
    if (prevPhase != 'endGame' && nextState.isEndGame) {
      final meId = nextState.myPlayerId;
      if (meId != null) {
        ref.read(playerStatsProvider.notifier).setActivePlayerId(meId);
      }
    }
  }

  void _applyStepUpdate(Map<String, dynamic> payload) {
    final step = StepSnapshot(
      id: payload['stepId'] as String? ?? '',
      title: payload['title'] as String? ?? '',
      readAloudText: payload['readAloudText'] as String? ?? '',
      instructionText: payload['instructionText'] as String? ?? '',
      actionType: payload['actionType'] as String? ?? 'readAloud',
      roleId: payload['roleId'] as String?,
      options: _toStringList(payload['options']),
      timerSeconds: payload['timerSeconds'] as int?,
      isOptional: payload['isOptional'] as bool? ?? false,
    );

    state = state.copyWith(
      phase: payload['phase'] as String? ?? state.phase,
      currentStep: step,
    );
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }
}

/// Riverpod provider for [PlayerBridge].
final playerBridgeProvider =
    NotifierProvider<PlayerBridge, PlayerGameState>(() {
  return PlayerBridge();
});

import 'package:cb_models/cb_models.dart';
import '../game_resolution_logic.dart';

class GameAdminController {
  static GameState forceKillPlayer(GameState state, String id, {String reason = 'host_kick'}) {
    final p = state.players.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Player not found'),
    );
    if (!p.isAlive) return state;

    final updatedPlayers = state.players
        .map(
          (p) => p.id == id
              ? p.copyWith(
                  isAlive: false,
                  deathReason: reason,
                  deathDay: state.dayCount,
                )
              : p,
        )
        .toList();

    var newState = state.copyWith(
      players: updatedPlayers,
      gameHistory: [...state.gameHistory, '${p.name} was removed by the host.'],
      eventLog: [
        ...state.eventLog,
        GameEvent.death(playerId: id, reason: reason, day: state.dayCount),
      ],
    );

    newState = GameResolutionLogic.handleDeathTriggers(newState, id);

    final win = GameResolutionLogic.checkWinCondition(newState.players);
    if (win != null) {
      newState = GameResolutionLogic.applyWinResult(newState, win);
    }

    return newState;
  }

  static GameState revivePlayer(GameState state, String id) {
    final p = state.players.firstWhere((p) => p.id == id);
    if (p.isAlive) return state;
    return state.copyWith(
      players: state.players
          .map(
            (p) => p.id == id
                ? p.copyWith(isAlive: true, deathReason: null, deathDay: null)
                : p,
          )
          .toList(),
      gameHistory: [...state.gameHistory, '[HOST] Revived ${p.name}'],
    );
  }

  static GameState togglePlayerMute(GameState state, String id, bool muted) {
    return state.copyWith(
      players: state.players
          .map((p) => p.id == id ? p.copyWith(isMuted: muted) : p)
          .toList(),
      gameHistory: [
        ...state.gameHistory,
        '[HOST] ${muted ? "Muted" : "Unmuted"} ${state.players.firstWhere((p) => p.id == id).name}',
      ],
    );
  }

  static GameState setSinBin(GameState state, String id, bool binned) {
    return state.copyWith(
      players: state.players
          .map((p) => p.id == id ? p.copyWith(isSinBinned: binned) : p)
          .toList(),
      gameHistory: [
        ...state.gameHistory,
        '[HOST] ${binned ? "Sin binned" : "Released"} ${state.players.firstWhere((p) => p.id == id).name}',
      ],
    );
  }

  static GameState setShadowBan(GameState state, String id, bool banned) {
    return state.copyWith(
      players: state.players
          .map((p) => p.id == id ? p.copyWith(isShadowBanned: banned) : p)
          .toList(),
      gameHistory: [
        ...state.gameHistory,
        '[HOST] ${banned ? "Shadow banned" : "Unbanned"} ${state.players.firstWhere((p) => p.id == id).name}',
      ],
    );
  }

  static GameState kickPlayer(GameState state, String id, String reason) {
    var newState = forceKillPlayer(state, id, reason: reason);
    return newState.copyWith(
      gameHistory: [
        ...newState.gameHistory,
        '[HOST] Kicked player - Reason: $reason',
      ],
    );
  }

  static GameState grantHostShield(GameState state, String playerId, int days) {
    return state.copyWith(
      players: state.players
          .map(
            (p) => p.id == playerId
                ? p.copyWith(
                    hasHostShield: true,
                    hostShieldExpiresDay: state.dayCount + days,
                  )
                : p,
          )
          .toList(),
      gameHistory: [
        ...state.gameHistory,
        '[HOST] Granted $days-day shield to ${state.players.firstWhere((p) => p.id == playerId).name}',
      ],
    );
  }

  static GameState toggleEyes(GameState state, bool open) {
    return state.copyWith(
      eyesOpen: open,
      gameHistory: [
        ...state.gameHistory,
        'DIRECTOR: EYES ${open ? "OPEN" : "CLOSED"} COMMAND',
      ],
    );
  }

  static GameState sendDirectorCommand(GameState state, String command) {
    final msg = 'STIM: $command';
    final entry = BulletinEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'SYSTEM',
      content: msg,
      type: 'system',
      timestamp: DateTime.now(),
    );

    final feedEvent = FeedEvent(
        id: '${DateTime.now().millisecondsSinceEpoch}_sys',
        type: FeedEventType.system,
        title: '',
        content: msg,
        timestamp: DateTime.now(),
      );

    return state.copyWith(
      bulletinBoard: [...state.bulletinBoard, entry],
      gameHistory: [...state.gameHistory, '[DIRECTOR] Triggered $command'],
      feedEvents: [...state.feedEvents, feedEvent],
    );
  }
}

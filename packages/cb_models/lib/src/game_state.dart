import 'package:freezed_annotation/freezed_annotation.dart';

import 'bulletin_entry.dart';
import 'enums.dart';
import 'feed_event.dart';
import 'game_event.dart';
import 'player.dart';
import 'script/script_step.dart';

part 'game_state.freezed.dart';
part 'game_state.g.dart';

@freezed
abstract class GameState with _$GameState {
  const factory GameState({
    @Default([]) List<Player> players,
    @Default(GamePhase.lobby) GamePhase phase,
    @Default(1) int dayCount,

    // Scripting Engine
    @Default([]) List<ScriptStep> scriptQueue,
    @Default(0) int scriptIndex,

    // Interaction log for the current phase (stepId -> targetId)
    @Default({}) Map<String, String> actionLog,

    // Summary of last night results for the Host UI
    @Default([]) List<String> lastNightReport,
    // Teasing player-facing bulletins from last night
    @Default([]) List<String> lastNightTeasers,

    // Day vote tally and summary
    @Default({}) Map<String, int> dayVoteTally,
    @Default({}) Map<String, String> dayVotesByVoter,
    @Default([]) List<String> lastDayReport,

    // Win condition
    Team? winner,
    @Default([]) List<String> endGameReport,

    // Per-player private messages (playerId -> messages)
    // Used for role-specific feedback (Bouncer result, Bartender alignment, etc.)
    @Default({}) Map<String, List<String>> privateMessages,

    // Persistent game history (timeline entries across entire game)
    @Default([]) List<String> gameHistory,

    // Structured event log (persistent across game)
    @Default([]) List<GameEvent> eventLog,

    // The live bulletin board (Group Chat history)
    @Default([]) List<BulletinEntry> bulletinBoard,

    // Chat-style feed events for the Host ScriptView
    @Default([]) List<FeedEvent> feedEvents,

    // Host configuration
    @Default(300) int discussionTimerSeconds,
    @Default(SyncMode.local) SyncMode syncMode,
    @Default(GameStyle.chaos) GameStyle gameStyle,
    @Default(false) bool tieBreaksRandomly,
    @Default(true) bool eyesOpen,

    // ── GHOST LOUNGE & DEAD POOL ──
    @Default({}) Map<String, String> deadPoolBets, // playerId -> targetPlayerId
    @Default(0) int globalDrinkDebt,
  }) = _GameState;

  const GameState._();

  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);

  ScriptStep? get currentStep =>
      (scriptIndex < scriptQueue.length) ? scriptQueue[scriptIndex] : null;
}

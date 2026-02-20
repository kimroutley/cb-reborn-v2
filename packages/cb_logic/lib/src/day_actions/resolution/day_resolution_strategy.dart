import 'dead_pool_handler.dart';
import 'day_resolution_handler.dart';
import 'drama_queen_handler.dart';
import 'predator_retaliation_handler.dart';
import 'tea_spiller_handler.dart';
import 'package:cb_models/cb_models.dart';

/// Executes day-resolution handlers in deterministic order.
///
/// Order matters because handlers may depend on player mutations from earlier
/// handlers in the same pass.
///
/// Current default chain:
/// 1. [DeadPoolHandler]            (settles ghost bets after exile)
/// 2. [TeaSpillerHandler]          (informational reveal)
/// 3. [DramaQueenHandler]          (mutates roles/alliances)
/// 4. [PredatorRetaliationHandler] (may kill an additional voter)
///
/// Extension guidance:
/// - Place informational handlers before mutating handlers when possible.
/// - Place mutation handlers before death-trigger handlers if retaliation
///   should account for latest role state.
/// - Keep ordering changes covered by tests in
///   `test/day_resolution_strategy_test.dart`.
class DayResolutionStrategy {
  DayResolutionStrategy({List<DayResolutionHandler>? handlers})
      : handlers = handlers ??
            const [
              DeadPoolHandler(),
              TeaSpillerHandler(),
              DramaQueenHandler(),
              PredatorRetaliationHandler(),
            ];

  final List<DayResolutionHandler> handlers;

  DayResolutionResult execute(DayResolutionContext context) {
    var currentContext = context;
    final allLines = <String>[];
    final allEvents = <GameEvent>[];
    final allDeathTriggerVictimIds = <String>[];
    final allPrivateMessages = <String, List<String>>{};

    // Always include the exile victim (if any) as a death-trigger source.
    final exiledPlayerId = context.exiledPlayerId;
    if (exiledPlayerId != null && exiledPlayerId.isNotEmpty) {
      allDeathTriggerVictimIds.add(exiledPlayerId);
    }

    var shouldClearDeadPoolBets = false;

    for (final handler in handlers) {
      final result = handler.handle(currentContext);
      allLines.addAll(result.lines);
      allEvents.addAll(result.events);
      allDeathTriggerVictimIds.addAll(result.deathTriggerVictimIds);
      for (final entry in result.privateMessages.entries) {
        allPrivateMessages.putIfAbsent(entry.key, () => []).addAll(entry.value);
      }
      if (result.clearDeadPoolBets) {
        shouldClearDeadPoolBets = true;
      }
      currentContext = currentContext.copyWith(players: result.players);
    }

    return DayResolutionResult(
      players: currentContext.players,
      lines: allLines,
      events: allEvents,
      deathTriggerVictimIds: allDeathTriggerVictimIds.toSet().toList(),
      clearDeadPoolBets: shouldClearDeadPoolBets,
      privateMessages: allPrivateMessages,
    );
  }
}

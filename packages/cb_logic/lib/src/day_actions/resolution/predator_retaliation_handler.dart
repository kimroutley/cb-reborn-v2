import 'day_resolution_handler.dart';
import 'predator_retaliation.dart';

class PredatorRetaliationHandler implements DayResolutionHandler {
  const PredatorRetaliationHandler();

  @override
  DayResolutionResult handle(DayResolutionContext context) {
    final resolution = resolvePredatorRetaliation(
      players: context.players,
      votesByVoter: context.votesByVoter,
      dayCount: context.dayCount,
      retaliationChoices: context.predatorRetaliationChoices,
    );

    return DayResolutionResult(
      players: resolution.players,
      lines: resolution.lines,
      events: resolution.events,
      deathTriggerVictimIds: resolution.victimIds,
    );
  }
}

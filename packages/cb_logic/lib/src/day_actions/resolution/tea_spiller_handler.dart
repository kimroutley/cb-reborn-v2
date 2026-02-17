import 'day_resolution_handler.dart';
import 'tea_spiller_reveal.dart';

class TeaSpillerHandler implements DayResolutionHandler {
  const TeaSpillerHandler();

  @override
  DayResolutionResult handle(DayResolutionContext context) {
    final lines = resolveTeaSpillerReveals(
      players: context.players,
      votesByVoter: context.votesByVoter,
      teaSpillerRevealChoices: context.teaSpillerRevealChoices,
    );

    return DayResolutionResult(players: context.players, lines: lines);
  }
}

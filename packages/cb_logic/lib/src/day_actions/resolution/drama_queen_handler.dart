import 'day_resolution_handler.dart';
import 'drama_queen_swap.dart';

class DramaQueenHandler implements DayResolutionHandler {
  const DramaQueenHandler();

  @override
  DayResolutionResult handle(DayResolutionContext context) {
    final resolution = resolveDramaQueenSwaps(
      players: context.players,
      votesByVoter: context.votesByVoter,
      dramaQueenSwapChoices: context.dramaQueenSwapChoices,
    );

    return DayResolutionResult(
      players: resolution.players,
      lines: resolution.lines,
      privateMessages: resolution.privateMessages,
    );
  }
}

import 'package:cb_models/cb_models.dart';

class DayResolutionContext {
  const DayResolutionContext({
    required this.players,
    required this.votesByVoter,
    required this.dayCount,
    this.exiledPlayerId,
    this.predatorRetaliationChoices = const {},
    this.teaSpillerRevealChoices = const {},
    this.dramaQueenSwapChoices = const {},
  });

  final List<Player> players;
  final Map<String, String> votesByVoter;
  final int dayCount;
  final String? exiledPlayerId;
  final Map<String, String> predatorRetaliationChoices;
  final Map<String, String> teaSpillerRevealChoices;
  final Map<String, String> dramaQueenSwapChoices;

  DayResolutionContext copyWith({
    List<Player>? players,
    Map<String, String>? votesByVoter,
    int? dayCount,
    String? exiledPlayerId,
    Map<String, String>? predatorRetaliationChoices,
    Map<String, String>? teaSpillerRevealChoices,
    Map<String, String>? dramaQueenSwapChoices,
  }) {
    return DayResolutionContext(
      players: players ?? this.players,
      votesByVoter: votesByVoter ?? this.votesByVoter,
      dayCount: dayCount ?? this.dayCount,
      exiledPlayerId: exiledPlayerId ?? this.exiledPlayerId,
      predatorRetaliationChoices:
          predatorRetaliationChoices ?? this.predatorRetaliationChoices,
      teaSpillerRevealChoices:
          teaSpillerRevealChoices ?? this.teaSpillerRevealChoices,
      dramaQueenSwapChoices:
          dramaQueenSwapChoices ?? this.dramaQueenSwapChoices,
    );
  }
}

class DayResolutionResult {
  const DayResolutionResult({
    required this.players,
    this.lines = const [],
    this.events = const [],
    this.deathTriggerVictimIds = const [],
    this.clearDeadPoolBets = false,
    this.privateMessages = const {},
  });

  final List<Player> players;
  final List<String> lines;
  final List<GameEvent> events;
  final List<String> deathTriggerVictimIds;
  final bool clearDeadPoolBets;
  final Map<String, List<String>> privateMessages;
}

abstract class DayResolutionHandler {
  DayResolutionResult handle(DayResolutionContext context);
}

import 'package:cb_models/cb_models.dart';

class DayResolutionContext {
  const DayResolutionContext({
    required this.players,
    required this.votesByVoter,
    required this.dayCount,
    this.exiledPlayerId,
  });

  final List<Player> players;
  final Map<String, String> votesByVoter;
  final int dayCount;
  final String? exiledPlayerId;

  DayResolutionContext copyWith({
    List<Player>? players,
    Map<String, String>? votesByVoter,
    int? dayCount,
    String? exiledPlayerId,
  }) {
    return DayResolutionContext(
      players: players ?? this.players,
      votesByVoter: votesByVoter ?? this.votesByVoter,
      dayCount: dayCount ?? this.dayCount,
      exiledPlayerId: exiledPlayerId ?? this.exiledPlayerId,
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
  });

  final List<Player> players;
  final List<String> lines;
  final List<GameEvent> events;
  final List<String> deathTriggerVictimIds;
  final bool clearDeadPoolBets;
}

abstract class DayResolutionHandler {
  DayResolutionResult handle(DayResolutionContext context);
}

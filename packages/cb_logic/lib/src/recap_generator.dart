import 'dart:math';
import 'package:cb_models/cb_models.dart';

/// Data class for storing generated recap statistics.
class SessionRecap {
  final String sessionName;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int totalGames;
  final Duration totalDuration;
  final int uniquePlayers;

  // Awards
  final PlayerAward? mvp;
  final PlayerAward? mainCharacter;
  final PlayerAward? ghost;
  final PlayerAward? dealerOfDeath;

  // Highlights
  final String? spiciestMoment;
  final List<GameSummary> gameSummaries;

  // Team stats
  final int clubStaffWins;
  final int partyAnimalsWins;

  const SessionRecap({
    required this.sessionName,
    required this.startedAt,
    this.endedAt,
    required this.totalGames,
    required this.totalDuration,
    required this.uniquePlayers,
    this.mvp,
    this.mainCharacter,
    this.ghost,
    this.dealerOfDeath,
    this.spiciestMoment,
    required this.gameSummaries,
    required this.clubStaffWins,
    required this.partyAnimalsWins,
  });
}

/// Award for a specific player.
class PlayerAward {
  final String playerName;
  final String description;
  final int value; // numeric stat associated with award

  const PlayerAward({
    required this.playerName,
    required this.description,
    required this.value,
  });
}

/// Summary of a single game.
class GameSummary {
  final String gameId;
  final DateTime startedAt;
  final Team winner;
  final int playerCount;
  final int dayCount;

  const GameSummary({
    required this.gameId,
    required this.startedAt,
    required this.winner,
    required this.playerCount,
    required this.dayCount,
  });
}

/// Utility for generating Games Night session recaps.
class RecapGenerator {
  RecapGenerator._();

  static final _voteRegex = RegExp(r'[Vv]oted? for (.+?)(?:[\.,\s]|$)');
  static final _killRegex = RegExp(r'(.+?) (was killed|died|eliminated)');
  static final _dayRegex = RegExp(r'DAY (\d+)');
  static final _dealerKillRegex = RegExp(r'Dealer (.+?) killed');

  /// Generate a complete recap from a session and its game records.
  static SessionRecap generateRecap(
    GamesNightRecord session,
    List<GameRecord> games,
  ) {
    final totalDuration = session.endedAt != null
        ? session.endedAt!.difference(session.startedAt)
        : DateTime.now().difference(session.startedAt);

    // Calculate team wins
    final staffWins = games.where((g) => g.winner == Team.clubStaff).length;
    final paWins = games.where((g) => g.winner == Team.partyAnimals).length;

    // Generate awards
    final mvpAward = _calculateMVP(session, games);
    final mainCharAward = _calculateMainCharacter(session, games);
    final ghostAward = _calculateGhost(session, games);
    final dealerAward = _calculateDealerOfDeath(session, games);

    // Find spiciest moment
    final spiciestMoment = _findSpiciestMoment(games);

    // Create game summaries
    final summaries = games
        .map(
          (g) => GameSummary(
            gameId: g.id,
            startedAt: g.startedAt,
            winner: g.winner,
            playerCount: g.playerCount,
            dayCount: g.dayCount,
          ),
        )
        .toList();

    return SessionRecap(
      sessionName: session.sessionName,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      totalGames: games.length,
      totalDuration: totalDuration,
      uniquePlayers: session.playerNames.length,
      mvp: mvpAward,
      mainCharacter: mainCharAward,
      ghost: ghostAward,
      dealerOfDeath: dealerAward,
      spiciestMoment: spiciestMoment,
      gameSummaries: summaries,
      clubStaffWins: staffWins,
      partyAnimalsWins: paWins,
    );
  }

  /// Calculate MVP: player with highest win rate, weighted by games played.
  static PlayerAward? _calculateMVP(
    GamesNightRecord session,
    List<GameRecord> games,
  ) {
    if (games.isEmpty) return null;

    final playerWins = <String, int>{};
    final playerGames = session.playerGamesCount;

    // Count wins for each player
    for (final game in games) {
      for (final player in game.roster) {
        if (player.alliance == game.winner) {
          playerWins[player.name] = (playerWins[player.name] ?? 0) + 1;
        }
      }
    }

    // Calculate MVP score: (wins / games) * sqrt(min(games, 3))
    // This rewards consistency while giving slight bonus to participation
    String? mvpName;
    double bestScore = 0;

    for (final entry in playerGames.entries) {
      final name = entry.key;
      final gamesPlayed = entry.value;
      final wins = playerWins[name] ?? 0;

      if (gamesPlayed == 0) continue;

      final winRate = wins / gamesPlayed;
      final participationWeight = sqrt(min(gamesPlayed, 3).toDouble());
      final score = winRate * participationWeight;

      if (score > bestScore) {
        bestScore = score;
        mvpName = name;
      }
    }

    if (mvpName == null) return null;

    final wins = playerWins[mvpName] ?? 0;
    final gamesPlayed = playerGames[mvpName] ?? 1;
    final winRate = ((wins / gamesPlayed) * 100).round();

    return PlayerAward(
      playerName: mvpName,
      description: 'Win Rate: $winRate% ($wins/$gamesPlayed games)',
      value: winRate,
    );
  }

  /// Calculate Main Character: player who was targeted the most.
  static PlayerAward? _calculateMainCharacter(
    GamesNightRecord session,
    List<GameRecord> games,
  ) {
    if (games.isEmpty) return null;

    final playerTargets = <String, int>{};

    for (final game in games) {
      if (game.eventLog.isNotEmpty) {
        for (final event in game.eventLog) {
          if (event is GameEventVote) {
            final name = _nameFromId(game, event.targetId);
            if (name != null) {
              playerTargets[name] = (playerTargets[name] ?? 0) + 1;
            }
          } else if (event is GameEventDeath) {
            final name = _nameFromId(game, event.playerId);
            if (name != null) {
              playerTargets[name] = (playerTargets[name] ?? 0) + 1;
            }
          }
        }
      } else {
        // Fallback for old records
        for (final event in game.history) {
          // Count votes (mentions in voting lines)
          if (event.contains('voted for') || event.contains('Vote for')) {
            final voteMatch = _voteRegex.firstMatch(event);
            if (voteMatch != null) {
              final target = voteMatch.group(1)!.trim();
              playerTargets[target] = (playerTargets[target] ?? 0) + 1;
            }
          }
          // Count kills (mentions in death lines)
          if (event.contains('killed') || event.contains('died')) {
            final killMatch = _killRegex.firstMatch(event);
            if (killMatch != null) {
              final target = killMatch.group(1)!.trim();
              playerTargets[target] = (playerTargets[target] ?? 0) + 1;
            }
          }
        }
      }
    }

    if (playerTargets.isEmpty) return null;

    final entries = playerTargets.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = entries.first;

    return PlayerAward(
      playerName: top.key,
      description: 'Targeted ${top.value} times',
      value: top.value,
    );
  }

  /// Calculate Ghost: player who survived the longest on average.
  static PlayerAward? _calculateGhost(
    GamesNightRecord session,
    List<GameRecord> games,
  ) {
    if (games.isEmpty) return null;

    final playerSurvivalDays = <String, List<int>>{};

    for (final game in games) {
      for (final player in game.roster) {
        if (player.alive) {
          // Survived the whole game
          playerSurvivalDays
              .putIfAbsent(player.name, () => [])
              .add(game.dayCount);
        } else {
          int deathDay = 1;
          if (game.eventLog.isNotEmpty) {
            // Use structured events
            final deathEvent = game.eventLog
                .whereType<GameEventDeath>()
                .firstWhere(
                  (e) => e.playerId == player.id,
                  orElse: () => const GameEventDeath(
                    playerId: '',
                    reason: '',
                    day: 1,
                  ), // fallback
                );
            if (deathEvent.playerId.isNotEmpty) {
              deathDay = deathEvent.day;
            }
          } else {
            // Find when they died in history (Fallback)
            for (final event in game.history) {
              if (event.startsWith('─── DAY ')) {
                final dayMatch = _dayRegex.firstMatch(event);
                if (dayMatch != null) {
                  deathDay = int.parse(dayMatch.group(1)!);
                }
              }
              if (event.contains(player.name) &&
                  (event.contains('died') || event.contains('killed'))) {
                break;
              }
            }
          }
          playerSurvivalDays.putIfAbsent(player.name, () => []).add(deathDay);
        }
      }
    }

    if (playerSurvivalDays.isEmpty) return null;

    // Calculate average survival
    String? ghostName;
    double bestAvg = 0;

    for (final entry in playerSurvivalDays.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        ghostName = entry.key;
      }
    }

    if (ghostName == null) return null;

    return PlayerAward(
      playerName: ghostName,
      description: 'Avg survival: ${bestAvg.toStringAsFixed(1)} days',
      value: bestAvg.round(),
    );
  }

  /// Calculate Dealer of Death: player with most successful kills as Dealer.
  static PlayerAward? _calculateDealerOfDeath(
    GamesNightRecord session,
    List<GameRecord> games,
  ) {
    if (games.isEmpty) return null;

    final dealerKills = <String, int>{};

    for (final game in games) {
      if (game.eventLog.isNotEmpty) {
        for (final event in game.eventLog) {
          if (event is GameEventKill) {
            final name = _nameFromId(game, event.killerId);
            if (name != null) {
              dealerKills[name] = (dealerKills[name] ?? 0) + 1;
            }
          }
        }
      } else {
        // Fallback
        for (final event in game.history) {
          // Look for dealer kill events
          if (event.contains('Dealer') && event.contains('killed')) {
            final match = _dealerKillRegex.firstMatch(event);
            if (match != null) {
              final dealerName = match.group(1)!.trim();
              dealerKills[dealerName] = (dealerKills[dealerName] ?? 0) + 1;
            }
          }
        }
      }
    }

    if (dealerKills.isEmpty) return null;

    final entries = dealerKills.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = entries.first;

    return PlayerAward(
      playerName: top.key,
      description: '${top.value} successful kills',
      value: top.value,
    );
  }

  /// Find the spiciest moment from game histories.
  static String? _findSpiciestMoment(List<GameRecord> games) {
    if (games.isEmpty) return null;

    final allEvents = <String>[];

    for (final game in games) {
      // Look for spicy events (marked with emojis or specific keywords)
      for (final event in game.history) {
        if (event.contains('🌶️') ||
            event.contains('SPICY') ||
            event.contains('dramatic') ||
            event.contains('betrayal') ||
            event.contains('shocking')) {
          allEvents.add(event);
        }
      }
    }

    // If no explicitly spicy events, pick shortest game or closest vote
    if (allEvents.isEmpty && games.isNotEmpty) {
      final shortestGame = games.reduce(
        (a, b) => a.dayCount < b.dayCount ? a : b,
      );

      return 'Game ended in just ${shortestGame.dayCount} days!';
    }

    if (allEvents.isEmpty) return null;

    // Randomly pick one
    final random = Random();
    return allEvents[random.nextInt(allEvents.length)];
  }

  static String? _nameFromId(GameRecord game, String id) {
    for (final p in game.roster) {
      if (p.id == id) return p.name;
    }
    return null;
  }
}

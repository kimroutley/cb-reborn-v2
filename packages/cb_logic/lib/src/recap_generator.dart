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

  // Special "roast" awards
  final List<SpecialAward> specialAwards;

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
    this.specialAwards = const [],
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
  final int value;

  const PlayerAward({
    required this.playerName,
    required this.description,
    required this.value,
  });
}

/// Ironic / sarcastic end-of-session award with a roast line.
class SpecialAward {
  final String id;
  final String title;
  final String playerName;
  final String roastLine;
  final String stat;
  final int value;

  const SpecialAward({
    required this.id,
    required this.title,
    required this.playerName,
    required this.roastLine,
    required this.stat,
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

    // Generate special roast awards
    final specials = _calculateSpecialAwards(session, games);

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
      specialAwards: specials,
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
                      playerId: '', reason: '', day: 1), // fallback
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

  // ---------------------------------------------------------------------------
  // Special Awards
  // ---------------------------------------------------------------------------

  static List<SpecialAward> _calculateSpecialAwards(
    GamesNightRecord session,
    List<GameRecord> games,
  ) {
    if (games.isEmpty) return const [];

    final awards = <SpecialAward>[];

    final a1 = _cannonFodder(games);
    if (a1 != null) awards.add(a1);

    final a2 = _theNPC(games);
    if (a2 != null) awards.add(a2);

    final a3 = _friendlyFireChampion(games);
    if (a3 != null) awards.add(a3);

    final a4 = _professionalVictim(games);
    if (a4 != null) awards.add(a4);

    final a5 = _theCockroach(games);
    if (a5 != null) awards.add(a5);

    final a6 = _absolutelyClueless(session, games);
    if (a6 != null) awards.add(a6);

    final a7 = _theTourist(session);
    if (a7 != null) awards.add(a7);

    final a8 = _designatedScapegoat(games);
    if (a8 != null) awards.add(a8);

    final a9 = _theJudas(games);
    if (a9 != null) awards.add(a9);

    final a10 = _participationTrophy(session, games);
    if (a10 != null) awards.add(a10);

    return awards;
  }

  /// Died on Day/Night 1 the most times.
  static SpecialAward? _cannonFodder(List<GameRecord> games) {
    final earlyDeaths = <String, int>{};

    for (final game in games) {
      for (final event in game.eventLog.whereType<GameEventDeath>()) {
        if (event.day <= 1) {
          final name = _nameFromId(game, event.playerId);
          if (name != null) {
            earlyDeaths[name] = (earlyDeaths[name] ?? 0) + 1;
          }
        }
      }
    }

    if (earlyDeaths.isEmpty) return null;

    final sorted = earlyDeaths.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    if (top.value < 1) return null;

    return SpecialAward(
      id: 'cannon_fodder',
      title: 'Cannon Fodder',
      playerName: top.key,
      roastLine: "The club's unofficial welcome mat.",
      stat: 'Died on Day 1 ${top.value}x',
      value: top.value,
    );
  }

  /// Received the fewest votes across all games (least relevant player).
  static SpecialAward? _theNPC(List<GameRecord> games) {
    final allPlayers = <String>{};
    final votesReceived = <String, int>{};

    for (final game in games) {
      for (final p in game.roster) {
        allPlayers.add(p.name);
      }
      for (final event in game.eventLog.whereType<GameEventVote>()) {
        final name = _nameFromId(game, event.targetId);
        if (name != null) {
          votesReceived[name] = (votesReceived[name] ?? 0) + 1;
        }
      }
    }

    if (allPlayers.length < 3) return null;

    // Players with zero votes are the ultimate NPCs
    String? npcName;
    int lowestVotes = 999999;
    for (final name in allPlayers) {
      final v = votesReceived[name] ?? 0;
      if (v < lowestVotes) {
        lowestVotes = v;
        npcName = name;
      }
    }

    if (npcName == null) return null;

    return SpecialAward(
      id: 'the_npc',
      title: 'The NPC',
      playerName: npcName,
      roastLine: 'Background character energy. Were you even playing?',
      stat: lowestVotes == 0
          ? 'Received zero votes all session'
          : 'Received only $lowestVotes vote${lowestVotes == 1 ? '' : 's'}',
      value: lowestVotes,
    );
  }

  /// Most votes cast against own teammates.
  static SpecialAward? _friendlyFireChampion(List<GameRecord> games) {
    final betrayals = <String, int>{};

    for (final game in games) {
      final playerAlliance = <String, Team>{};
      for (final p in game.roster) {
        playerAlliance[p.id] = p.alliance;
      }

      for (final event in game.eventLog.whereType<GameEventVote>()) {
        final voterTeam = playerAlliance[event.voterId];
        final targetTeam = playerAlliance[event.targetId];
        if (voterTeam != null &&
            targetTeam != null &&
            voterTeam == targetTeam) {
          final voterName = _nameFromId(game, event.voterId);
          if (voterName != null) {
            betrayals[voterName] = (betrayals[voterName] ?? 0) + 1;
          }
        }
      }
    }

    if (betrayals.isEmpty) return null;

    final sorted = betrayals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;

    return SpecialAward(
      id: 'friendly_fire_champion',
      title: 'Friendly Fire Champion',
      playerName: top.key,
      roastLine: 'With allies like you, who needs the Dealer?',
      stat: '${top.value} vote${top.value == 1 ? '' : 's'} against own team',
      value: top.value,
    );
  }

  /// Died the most times across all games in the session.
  static SpecialAward? _professionalVictim(List<GameRecord> games) {
    final deathCount = <String, int>{};

    for (final game in games) {
      for (final p in game.roster) {
        if (!p.alive) {
          deathCount[p.name] = (deathCount[p.name] ?? 0) + 1;
        }
      }
    }

    if (deathCount.isEmpty) return null;

    final sorted = deathCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    if (top.value < 2) return null;

    return SpecialAward(
      id: 'professional_victim',
      title: 'Professional Victim',
      playerName: top.key,
      roastLine: 'You die more often than a video game tutorial character.',
      stat: 'Died ${top.value} times',
      value: top.value,
    );
  }

  /// Survived to end-game the most but team still lost.
  static SpecialAward? _theCockroach(List<GameRecord> games) {
    final uselessSurvivals = <String, int>{};

    for (final game in games) {
      for (final p in game.roster) {
        if (p.alive && p.alliance != game.winner) {
          uselessSurvivals[p.name] = (uselessSurvivals[p.name] ?? 0) + 1;
        }
      }
    }

    if (uselessSurvivals.isEmpty) return null;

    final sorted = uselessSurvivals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;

    return SpecialAward(
      id: 'the_cockroach',
      title: 'The Cockroach',
      playerName: top.key,
      roastLine: 'Unkillable. Unstoppable. Utterly useless.',
      stat: 'Survived ${top.value} game${top.value == 1 ? '' : 's'} but still lost',
      value: top.value,
    );
  }

  /// Worst win rate (minimum 2 games played).
  static SpecialAward? _absolutelyClueless(
    GamesNightRecord session,
    List<GameRecord> games,
  ) {
    final playerWins = <String, int>{};
    final playerGames = <String, int>{};

    for (final game in games) {
      for (final p in game.roster) {
        playerGames[p.name] = (playerGames[p.name] ?? 0) + 1;
        if (p.alliance == game.winner) {
          playerWins[p.name] = (playerWins[p.name] ?? 0) + 1;
        }
      }
    }

    String? worstName;
    double worstRate = 2.0;

    for (final entry in playerGames.entries) {
      if (entry.value < 2) continue;
      final rate = (playerWins[entry.key] ?? 0) / entry.value;
      if (rate < worstRate) {
        worstRate = rate;
        worstName = entry.key;
      }
    }

    if (worstName == null) return null;

    final wins = playerWins[worstName] ?? 0;
    final played = playerGames[worstName] ?? 1;
    final pct = ((wins / played) * 100).round();

    return SpecialAward(
      id: 'absolutely_clueless',
      title: 'Absolutely Clueless',
      playerName: worstName,
      roastLine: 'A Magic 8-Ball would have played better.',
      stat: '$pct% win rate ($wins/$played)',
      value: pct,
    );
  }

  /// Played the fewest games in the session.
  static SpecialAward? _theTourist(GamesNightRecord session) {
    final counts = session.playerGamesCount;
    if (counts.length < 3) return null;

    final sorted = counts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final bottom = sorted.first;
    final top = sorted.last;

    // Only award if there's a meaningful gap
    if (bottom.value >= top.value) return null;

    return SpecialAward(
      id: 'the_tourist',
      title: 'The Tourist',
      playerName: bottom.key,
      roastLine: "Thanks for stopping by. Don't let the door hit you.",
      stat: 'Played ${bottom.value} of ${top.value} games',
      value: bottom.value,
    );
  }

  /// Received the most exile votes total (everyone's favourite target).
  static SpecialAward? _designatedScapegoat(List<GameRecord> games) {
    final votesReceived = <String, int>{};

    for (final game in games) {
      for (final event in game.eventLog.whereType<GameEventVote>()) {
        final name = _nameFromId(game, event.targetId);
        if (name != null) {
          votesReceived[name] = (votesReceived[name] ?? 0) + 1;
        }
      }
    }

    if (votesReceived.isEmpty) return null;

    final sorted = votesReceived.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;

    return SpecialAward(
      id: 'designated_scapegoat',
      title: 'Designated Scapegoat',
      playerName: top.key,
      roastLine: "If there's a bus, you're under it.",
      stat: '${top.value} exile vote${top.value == 1 ? '' : 's'} received',
      value: top.value,
    );
  }

  /// Won the most games as a Party Animal (evil team).
  static SpecialAward? _theJudas(List<GameRecord> games) {
    final evilWins = <String, int>{};

    for (final game in games) {
      for (final p in game.roster) {
        if (p.alliance == Team.partyAnimals && game.winner == Team.partyAnimals) {
          evilWins[p.name] = (evilWins[p.name] ?? 0) + 1;
        }
      }
    }

    if (evilWins.isEmpty) return null;

    final sorted = evilWins.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;
    if (top.value < 1) return null;

    return SpecialAward(
      id: 'the_judas',
      title: 'The Judas',
      playerName: top.key,
      roastLine: 'Sleep with one eye open around this one.',
      stat: '${top.value} evil win${top.value == 1 ? '' : 's'}',
      value: top.value,
    );
  }

  /// Played every game (or near-every) and won the fewest.
  static SpecialAward? _participationTrophy(
    GamesNightRecord session,
    List<GameRecord> games,
  ) {
    if (games.length < 2) return null;

    final counts = session.playerGamesCount;
    final maxPlayed = counts.values.fold<int>(0, max);

    // Only consider players who played at least 80% of games
    final threshold = (maxPlayed * 0.8).ceil();

    final playerWins = <String, int>{};
    for (final game in games) {
      for (final p in game.roster) {
        if (p.alliance == game.winner) {
          playerWins[p.name] = (playerWins[p.name] ?? 0) + 1;
        }
      }
    }

    String? loserName;
    int fewestWins = 999999;

    for (final entry in counts.entries) {
      if (entry.value < threshold) continue;
      final wins = playerWins[entry.key] ?? 0;
      if (wins < fewestWins) {
        fewestWins = wins;
        loserName = entry.key;
      }
    }

    if (loserName == null) return null;

    final played = counts[loserName] ?? 0;

    return SpecialAward(
      id: 'participation_trophy',
      title: 'Participation Trophy',
      playerName: loserName,
      roastLine: "You were there. That's... that's it. That's the award.",
      stat: '$fewestWins win${fewestWins == 1 ? '' : 's'} in $played games',
      value: fewestWins,
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

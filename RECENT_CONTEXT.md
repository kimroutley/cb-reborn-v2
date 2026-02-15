# Recent Context Changes
## File: packages/cb_theme/lib/src/colors.dart
```dart
import 'package:flutter/material.dart';

class CBColors {
  // Convenience token: prefer this over `Colors.transparent` in app code so
  // all styling still routes through `cb_theme`.
  static const Color transparent = Color(0x00000000);

  // --- Radiant Neon Palette ---
  static const Color radiantPink = Color(0xFFF72585);
  static const Color radiantTurquoise = Color(0xFF4CC9F0);

  // --- NEON M3 PALETTE (Radiant Neon) ---
  static const Color neonBlue = radiantTurquoise; // Primary – vibrant cyan
  static const Color neonPink = radiantPink; // Secondary – vibrant magenta-pink
  static const Color neonPurple =
      radiantPink; // Strict palette: map tertiary to pink

  // --- ROLE-INSPIRED ACCENT COLORS ---
  static const Color whoreTeal = Color(0xFF35C9DF);
  static const Color seasonedMint = Color(0xFF78DFF2);
  static const Color secondWindCerise = Color(0xFFF43A97);

  // Additional role-based accent colors
  static const Color dealerMagenta = radiantPink; // Dealer
  static const Color allyCatYellow = radiantTurquoise; // Ally Cat
  static const Color creepPurple = Color(0xFFE13CB2); // Creep

  static const Color darkGrey = Color(0xFF191C1D); // Surface
  static const Color voidBlack = Color(0xFF0E1112); // Background

  // --- SEMANTIC MAPPINGS ---
  static const Color background = voidBlack;
  static const Color surface = darkGrey;
  static const Color onSurface = Color(0xFFF0F0F0);
  static const Color primary = radiantTurquoise;
  static const Color secondary = radiantPink;
  static const Color coolGrey = Color(0xFF495867);

  // Status & Accents
  static const Color yellow = radiantPink;

  // Match the Radiant Neon spec: saturated, readable on dark surfaces.
  static const Color error = Color(0xFFFF4FA8);
  static const Color success = radiantTurquoise; // "matrixGreen"
  static const Color warning = Color(0xFF2FE3D6); // "alertOrange"

  static const Color red = error;
  static const Color green = success;
  static const Color orange = warning;

  // Special Effects (Glows)
  static final Color cyanGlow = neonBlue.withValues(alpha: 0.5);
  static final Color magentaGlow = neonPink.withValues(alpha: 0.4);

  // Extended Color Palette (role-inspired colors for UI variety)
  static const Color neonGreen = Color(0xFF78DFF2); // Turquoise variant
  static const Color purpleHaze = Color(0xFFE13CB2); // Pink-magenta variant
  static const Color ultraViolet = radiantPink; // Pink variant
  static const Color bloodOrange = Color(0xFFF24FAE); // Warm pink accent
  static const Color brightYellow = radiantTurquoise; // Turquoise variant

  // ── GLOW FACTORIES (Ported from Legacy) ──

  /// Multi-layer text/icon shadows for neon glow effect.
  /// [intensity] scales blur radius (default 1.0).
  static List<Shadow> textGlow(Color color, {double intensity = 1.0}) => [
        Shadow(color: color, blurRadius: 8 * intensity),
        Shadow(color: color.withValues(alpha: 0.8), blurRadius: 16 * intensity),
        Shadow(color: color.withValues(alpha: 0.5), blurRadius: 24 * intensity),
      ];

  /// Alias – icons use the same triple-shadow stack.
  static List<Shadow> iconGlow(Color color, {double intensity = 1.0}) =>
      textGlow(color, intensity: intensity);

  /// Multi-layer box shadow for rectangular/rounded containers.
  static List<BoxShadow> boxGlow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.6 * intensity),
          blurRadius: 12,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.4 * intensity),
          blurRadius: 24,
          spreadRadius: 4,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.2 * intensity),
          blurRadius: 32,
          spreadRadius: 0,
        ),
      ];

  /// Multi-layer circular glow (no spread to avoid square halo).
  static List<BoxShadow> circleGlow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.6 * intensity),
          blurRadius: 10,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.35 * intensity),
          blurRadius: 20,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.18 * intensity),
          blurRadius: 32,
          spreadRadius: 0,
        ),
      ];

  /// Glassmorphism decoration factory – frosted-glass panel.
  static BoxDecoration glassmorphism({
    Color? color,
    double opacity = 0.1,
    Color borderColor = const Color(0x3DF0F0F0),
    double borderWidth = 1,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: (color ?? onSurface).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: voidBlack.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // --- COMPATIBILITY MAPPINGS (Aliased to Neon Palette) ---
  static const Color offBlack = Color(0xFF1D2021);
  static const Color darkMetal = Color(0xFF282A2B);
  static const Color dead = Color(0xFF4A8190);

  // --- TEXT COLOR MAPPINGS ---
  static const Color textDim = coolGrey;
  static const Color textBright = onSurface;

  // --- THE SHIMMER PALETTE (Biorefraction/Prismatic Horror) ---
  static const Color deepSwamp = Color(0xFF0a1412);
  static const Color magentaShift = radiantPink;
  static const Color cyanRefract = radiantTurquoise;

  static const LinearGradient oilSlickGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1a1a1a), // Base dark
      Color(0xFFF72585), // Radiant pink
      Color(0xFF4CC9F0), // Radiant turquoise
      Color(0xFFF72585), // Radiant pink
      Color(0xFF1a1a1a), // Back to dark
    ],
    stops: [0.0, 0.4, 0.5, 0.6, 1.0],
  );

  static const Color electricCyan = neonBlue;
  static const Color hotPink = neonPink;
  static const Color cyan = neonBlue;
  static const Color magenta = neonPink;
  static const Color purple = neonPurple;
  static const Color matrixGreen = success;
  static const Color alertOrange = warning;

  @Deprecated('Use [fromHex] instead')
  static Color roleColorFromHex(String hexString) => fromHex(hexString);

  static List<Color> roleShimmerStops(Color base) {
    final hsl = HSLColor.fromColor(base);

    Color tone(double hueShift, double saturationDelta, double lightnessDelta) {
      final hue = (hsl.hue + hueShift) % 360;
      final sat = (hsl.saturation + saturationDelta).clamp(0.35, 1.0);
      final light = (hsl.lightness + lightnessDelta).clamp(0.24, 0.76);
      return hsl
          .withHue(hue < 0 ? hue + 360 : hue)
          .withSaturation(sat)
          .withLightness(light)
          .toColor();
    }

    return [
      tone(-18, 0.06, -0.10),
      tone(0, 0.08, 0.04),
      tone(22, 0.06, 0.12),
      tone(-10, 0.04, -0.04),
    ];
  }

  static Color roleShimmerColor(Color base, double t) {
    final stops = roleShimmerStops(base);
    final a = Color.lerp(stops[0], stops[2], t) ?? base;
    final b = Color.lerp(stops[1], stops[3], t) ?? base;
    return Color.lerp(a, b, 0.5) ?? base;
  }

  /// Converts a hex color string (e.g. `#FF00FF`, `FF00FF` or `#F0F`) to a [Color].
  /// Falls back to [electricCyan] on invalid input.
  static Color fromHex(String hexString) {
    try {
      var hex = hexString.trim().replaceAll('#', '');

      if (hex.length == 3) {
        hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
      }

      if (hex.length == 6) {
        hex = 'FF$hex';
      }

      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }

      return electricCyan;
    } catch (_) {
      return electricCyan;
    }
  }
}
```

## File: packages/cb_logic/lib/src/game_resolution_logic.dart
```dart
import 'dart:math';
import 'package:cb_models/cb_models.dart';
import 'night_actions/night_actions.dart';

class NightResolution {
  final List<Player> players;
  final List<String> report;
  final List<String> teasers;
  final Map<String, List<String>> privateMessages;
  final List<GameEvent> events;

  const NightResolution({
    required this.players,
    required this.report,
    required this.teasers,
    required this.privateMessages,
    this.events = const [],
  });
}

class DayResolution {
  final List<Player> players;
  final List<String> report;
  final List<GameEvent> events;

  const DayResolution({
    required this.players,
    required this.report,
    this.events = const [],
  });
}

class WinResult {
  final Team winner;
  final List<String> report;
  const WinResult({required this.winner, required this.report});
}

class GameResolutionLogic {
  static List<Player> assignRoles(List<Player> players) {
    final rng = Random();
    final count = players.length;
    final staffCount = (count / 4).ceil();

    final shuffledPlayers = [...players]..shuffle(rng);
    var assigned = <Player>[];

    // 1. Assign Dealer(s)
    for (var i = 0; i < staffCount; i++) {
      final p = shuffledPlayers.removeAt(0);
      assigned.add(p.copyWith(
        role: roleCatalogMap[RoleIds.dealer]!,
        alliance: Team.clubStaff,
      ));
    }

    // 2. Assign Required roles if any
    final requiredRoles =
        roleCatalog.where((r) => r.isRequired && r.id != RoleIds.dealer).toList();
    for (final role in requiredRoles) {
      if (shuffledPlayers.isNotEmpty) {
        final p = shuffledPlayers.removeAt(0);
        assigned.add(p.copyWith(role: role, alliance: role.alliance));
      }
    }

    // 3. Assign remaining roles randomly
    final remainingRoles =
        roleCatalog.where((r) => !r.isRequired && r.id != RoleIds.dealer).toList();
    while (shuffledPlayers.isNotEmpty) {
      final p = shuffledPlayers.removeAt(0);
      final role = remainingRoles[rng.nextInt(remainingRoles.length)];
      assigned.add(p.copyWith(role: role, alliance: role.alliance));
      if (!role.canRepeat) remainingRoles.remove(role);
    }

    // 4. Special Initialization for Seasoned Drinker
    final actualStaffCount =
        assigned.where((p) => p.alliance == Team.clubStaff).length;
    assigned = assigned.map((p) {
      if (p.role.id == RoleIds.seasonedDrinker) {
        return p.copyWith(lives: actualStaffCount);
      }
      return p;
    }).toList();

    return assigned;
  }

  static NightResolution resolveNightActions(
    List<Player> players,
    Map<String, String> log,
    int dayCount,
    Map<String, List<String>> currentPrivateMessages,
  ) {
    final context = NightResolutionContext(
      players: players,
      log: log,
      dayCount: dayCount,
      privateMessages: currentPrivateMessages,
    );

    // 1. Process Pre-emptive actions (Sober, Roofi)
    SoberAction().execute(context);
    RoofiAction().execute(context);

    // 2. Process Investigative (Bouncer)
    BouncerAction().execute(context);

    // 3. Process Murder (Dealer)
    DealerAction().execute(context);

    // 4. Process Protection (Medic)
    MedicAction().execute(context);

    // 5. Apply Deaths
    DeathResolutionStrategy().execute(context);

    // Apply silencing
    for (final id in context.silencedIds) {
      final p = context.getPlayer(id);
      context.updatePlayer(p.copyWith(silencedDay: dayCount));
    }

    return context.toNightResolution();
  }

  static DayResolution resolveDayVote(
    List<Player> players,
    Map<String, int> tally,
    int dayCount,
  ) {
    if (tally.isEmpty) {
      return DayResolution(players: players, report: ['No votes were cast.']);
    }

    final events = <GameEvent>[];

    final sorted = tally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;

    if (top.key == 'abstain') {
      return DayResolution(
          players: players,
          report: ['The club decided to abstain from exiling anyone.']);
    }

    // Check for ties
    if (sorted.length > 1 && sorted[1].value == top.value) {
      return DayResolution(
          players: players,
          report: ['The vote ended in a tie. No one was exiled.']);
    }

    final victim = players.firstWhere((p) => p.id == top.key);
    final updatedPlayers = players
        .map((p) => p.id == top.key
            ? p.copyWith(
                isAlive: false, deathDay: dayCount, deathReason: 'exile')
            : p)
        .toList();

    events.add(GameEvent.death(
      playerId: victim.id,
      reason: 'exile',
      day: dayCount,
    ));

    return DayResolution(
      players: updatedPlayers,
      report: ['${victim.name} was exiled from the club by popular vote.'],
      events: events,
    );
  }

  static WinResult? checkWinCondition(List<Player> players) {
    int staff = 0;
    int pa = 0;

    for (final p in players) {
      if (p.isAlive) {
        if (p.alliance == Team.clubStaff) {
          staff++;
        } else if (p.alliance == Team.partyAnimals) {
          pa++;
        }
      }
    }

    // staff == 0 only if there WERE dealers to begin with
    final hadStaff = players.any((p) => p.alliance == Team.clubStaff);

    if (hadStaff && staff == 0) {
      return WinResult(
          winner: Team.partyAnimals,
          report: ['All Dealers have been eliminated. Party Animals win!']);
    }
    if (staff >= pa && staff > 0) {
      return WinResult(
          winner: Team.clubStaff,
          report: ['The Dealers have taken over the club. Staff win!']);
    }
    return null;
  }
}
```

## File: packages/cb_logic/lib/src/recap_generator.dart
```dart
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
```

## File: packages/cb_models/lib/src/game_event.dart
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'game_event.freezed.dart';
part 'game_event.g.dart';

@freezed
sealed class GameEvent with _$GameEvent {
  const factory GameEvent.dayStart({
    required int day,
  }) = GameEventDayStart;

  const factory GameEvent.vote({
    required String voterId,
    required String targetId,
    required int day,
  }) = GameEventVote;

  const factory GameEvent.death({
    required String playerId,
    required String reason,
    required int day,
  }) = GameEventDeath;

  const factory GameEvent.kill({
    required String killerId,
    required String victimId,
    required int day,
  }) = GameEventKill;

  factory GameEvent.fromJson(Map<String, dynamic> json) => _$GameEventFromJson(json);
}
```

## File: packages/cb_models/lib/src/persistence/game_record.dart
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';
import '../game_event.dart';

part 'game_record.freezed.dart';
part 'game_record.g.dart';

/// A snapshot of a completed game for the history database.
@freezed
abstract class GameRecord with _$GameRecord {
  const factory GameRecord({
    required String id,
    required DateTime startedAt,
    required DateTime endedAt,
    required Team winner,
    required int playerCount,
    @Default(1) int dayCount,

    /// Role IDs that were in play (e.g. ['dealer', 'bouncer', 'whore', ...])
    @Default([]) List<String> rolesInPlay,

    /// Snapshot of player names + role IDs at game end
    @Default([]) List<PlayerSnapshot> roster,

    /// Full game timeline
    @Default([]) List<String> history,

    /// Structured event log
    @Default([]) List<GameEvent> eventLog,
  }) = _GameRecord;

  factory GameRecord.fromJson(Map<String, dynamic> json) =>
      _$GameRecordFromJson(json);
}

/// Lightweight player info for the game record roster.
@freezed
abstract class PlayerSnapshot with _$PlayerSnapshot {
  const factory PlayerSnapshot({
    required String id,
    required String name,
    required String roleId,
    required Team alliance,
    @Default(true) bool alive,
  }) = _PlayerSnapshot;

  factory PlayerSnapshot.fromJson(Map<String, dynamic> json) =>
      _$PlayerSnapshotFromJson(json);
}
```

## File: apps/host/lib/host_settings.dart
```dart
import 'dart:async';

import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class HostSettings {
  final double sfxVolume;
  final double musicVolume;
  final bool highContrast;
  final bool geminiNarrationEnabled;
  final String hostPersonalityId;

  const HostSettings({
    required this.sfxVolume,
    required this.musicVolume,
    required this.highContrast,
    required this.geminiNarrationEnabled,
    required this.hostPersonalityId,
  });

  HostSettings copyWith({
    double? sfxVolume,
    double? musicVolume,
    bool? highContrast,
    bool? geminiNarrationEnabled,
    String? hostPersonalityId,
  }) {
    return HostSettings(
      sfxVolume: sfxVolume ?? this.sfxVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      highContrast: highContrast ?? this.highContrast,
      geminiNarrationEnabled:
          geminiNarrationEnabled ?? this.geminiNarrationEnabled,
      hostPersonalityId: hostPersonalityId ?? this.hostPersonalityId,
    );
  }

  static const defaults = HostSettings(
    sfxVolume: 1.0,
    musicVolume: 1.0,
    highContrast: false,
    geminiNarrationEnabled: true,
    hostPersonalityId: 'noir_narrator',
  );
}

class HostSettingsNotifier extends Notifier<HostSettings> {
  static const _keySfxVolume = 'sfxVolume';
  static const _keyMusicVolume = 'musicVolume';
  static const _keyHighContrast = 'highContrast';
  static const _keyGeminiNarrationEnabled = 'geminiNarrationEnabled';
  static const _keyHostPersonalityId = 'hostPersonalityId';

  @override
  HostSettings build() {
    _hydrate();
    return HostSettings.defaults;
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final sfxVolume = prefs.getDouble(_keySfxVolume);
      final musicVolume = prefs.getDouble(_keyMusicVolume);
      final highContrast = prefs.getBool(_keyHighContrast);
      final geminiNarrationEnabled = prefs.getBool(_keyGeminiNarrationEnabled);
      final hostPersonalityId = prefs.getString(_keyHostPersonalityId);

      state = state.copyWith(
        sfxVolume: (sfxVolume ?? state.sfxVolume).clamp(0.0, 1.0),
        musicVolume: (musicVolume ?? state.musicVolume).clamp(0.0, 1.0),
        highContrast: highContrast ?? state.highContrast,
        geminiNarrationEnabled:
            geminiNarrationEnabled ?? state.geminiNarrationEnabled,
        hostPersonalityId: hostPersonalityId ?? state.hostPersonalityId,
      );

      _applySideEffects(state);
    } catch (e) {
      // Best-effort
    }
  }

  Future<void> _persist(HostSettings next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keySfxVolume, next.sfxVolume);
      await prefs.setDouble(_keyMusicVolume, next.musicVolume);
      await prefs.setBool(_keyHighContrast, next.highContrast);
      await prefs.setBool(_keyGeminiNarrationEnabled, next.geminiNarrationEnabled);
      await prefs.setString(_keyHostPersonalityId, next.hostPersonalityId);
    } catch (e) {
      // Best-effort
    }
  }

  void setSfxVolume(double value) {
    final next = state.copyWith(sfxVolume: value.clamp(0.0, 1.0));
    state = next;
    _applySideEffects(next);
    unawaited(_persist(next));
  }

  void setMusicVolume(double value) {
    final next = state.copyWith(musicVolume: value.clamp(0.0, 1.0));
    state = next;
    _applySideEffects(next);
    unawaited(_persist(next));
  }

  void setHighContrast(bool enabled) {
    final next = state.copyWith(highContrast: enabled);
    state = next;
    _applySideEffects(next);
    unawaited(_persist(next));
  }

  void setGeminiNarrationEnabled(bool enabled) {
    final next = state.copyWith(geminiNarrationEnabled: enabled);
    state = next;
    _applySideEffects(next);
    unawaited(_persist(next));
  }

  void setHostPersonalityId(String id) {
    final next = state.copyWith(hostPersonalityId: id);
    state = next;
    _applySideEffects(next);
    unawaited(_persist(next));
  }

  void _applySideEffects(HostSettings settings) {
    SoundService.setVolume(settings.sfxVolume);
    SoundService.setMusicVolume(settings.musicVolume);
  }
}

final hostSettingsProvider =
    NotifierProvider<HostSettingsNotifier, HostSettings>(
  HostSettingsNotifier.new,
);
```

## File: packages/cb_theme/lib/src/widgets.dart
```dart
// Export modular widgets
export 'widgets/chat_bubble.dart';
export 'widgets/glass_tile.dart';
export 'widgets/phase_interrupt.dart';
export 'widgets/ghost_lounge_view.dart';
export 'widgets/cb_breathing_loader.dart';
export 'widgets/cb_role_id_card.dart';

// Newly extracted widgets
export 'widgets/cb_neon_background.dart';
export 'widgets/cb_panel.dart';
export 'widgets/cb_section_header.dart';
export 'widgets/cb_badge.dart';
export 'widgets/cb_bottom_sheet_handle.dart';
export 'widgets/cb_buttons.dart';
export 'widgets/cb_text_field.dart';
export 'widgets/cb_switch.dart';
export 'widgets/cb_slider.dart';
export 'widgets/cb_fade_slide.dart';
export 'widgets/cb_status_overlay.dart';
export 'widgets/cb_connection_dot.dart';
export 'widgets/cb_countdown_timer.dart';
export 'widgets/cb_report_card.dart';
export 'widgets/cb_role_avatar.dart';
export 'widgets/cb_compact_player_chip.dart';
export 'widgets/cb_filter_chip.dart';
export 'widgets/cb_player_status_tile.dart';
export 'widgets/cb_status_rail.dart';
export 'widgets/cb_prism_scaffold.dart';
// ═══════════════════════════════════════════════
//  REUSABLE NEON SYNTHWAVE WIDGET KIT
// ═══════════════════════════════════════════════

/// Atmospheric background with blurring and solid overlay.
class CBNeonBackground extends StatefulWidget {
  final Widget child;
  final String? backgroundAsset;
  final double blurSigma;
  final bool showOverlay;
  final bool showRadiance;

  const CBNeonBackground({
    super.key,
    required this.child,
    this.backgroundAsset,
    this.blurSigma = 10.0,
    this.showOverlay = true,
    this.showRadiance = false,
  });

  @override
  State<CBNeonBackground> createState() => _CBNeonBackgroundState();
}

class _CBNeonBackgroundState extends State<CBNeonBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    Widget radianceLayer() {
      if (!widget.showRadiance) return const SizedBox.shrink();
      if (reduceMotion) {
        return _StaticRadiance(scheme: scheme);
      }

      return AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Slow drift across the screen. Big radii keep it soft and "club" not "spinner".
          final a = 0.5 + 0.45 * math.sin(2 * math.pi * t);
          final b = 0.5 + 0.45 * math.cos(2 * math.pi * (t + 0.23));
          final c = 0.5 + 0.45 * math.sin(2 * math.pi * (t + 0.57));

          final primary = scheme.primary;
          final secondary = scheme.secondary;
          final shimmerCyan = CBColors.cyanRefract;
          final shimmerMagenta = CBColors.magentaShift;

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.lerp(
                        Alignment.topLeft,
                        Alignment.bottomRight,
                        a,
                      )!,
                      radius: 1.25,
                      colors: [
                        primary.withValues(alpha: 0.18),
                        secondary.withValues(alpha: 0.10),
                        CBColors.voidBlack.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Transform.rotate(
                  angle: (t * 2 * math.pi) * 0.15,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.lerp(
                          Alignment.bottomRight,
                          Alignment.topLeft,
                          b,
                        )!,
                        radius: 1.35,
                        colors: [
                          shimmerCyan.withValues(alpha: 0.08),
                          shimmerMagenta.withValues(alpha: 0.06),
                          CBColors.voidBlack.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.lerp(
                        const Alignment(-0.2, 0.8),
                        const Alignment(0.9, -0.3),
                        c,
                      )!,
                      radius: 1.6,
                      colors: [
                        secondary.withValues(alpha: 0.06),
                        primary.withValues(alpha: 0.05),
                        CBColors.voidBlack.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return Stack(
      children: [
        // Base Layer
        Positioned.fill(
          child: widget.backgroundAsset != null
              ? Image.asset(
                  widget.backgroundAsset!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: theme.scaffoldBackgroundColor),
                )
              : Container(color: theme.scaffoldBackgroundColor),
        ),

        // Radiance (neon spill)
        if (widget.showRadiance) Positioned.fill(child: radianceLayer()),

        // Blur Layer
        if (widget.blurSigma > 0)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurSigma,
                sigmaY: widget.blurSigma,
              ),
              child: const ColoredBox(color: CBColors.transparent),
            ),
          ),

        // Dark Overlay (keeps contrast and makes the neon feel like light, not background paint)
        if (widget.showOverlay)
          Positioned.fill(
            child: Container(
              color: CBColors.voidBlack.withValues(alpha: 0.66),
            ),
          ),

        // Content
        widget.child,
      ],
    );
  }
}

class _StaticRadiance extends StatelessWidget {
  final ColorScheme scheme;

  const _StaticRadiance({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.25),
          radius: 1.35,
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.secondary.withValues(alpha: 0.08),
            CBColors.voidBlack.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }
}

/// A glowing panel for grouping related content.
class CBPanel extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const CBPanel({
    super.key,
    required this.child,
    this.borderColor,
    this.borderWidth = 1,
    this.padding = const EdgeInsets.all(CBSpace.x4),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = borderColor ?? theme.colorScheme.primary;
    final panelRadius = BorderRadius.circular(CBRadius.md);

    return Container(
      width: double.infinity,
      margin: margin,
      child: ClipRRect(
        borderRadius: panelRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (theme.cardTheme.color ?? scheme.surfaceContainerLow)
                  .withValues(alpha: 0.44),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.onSurface.withValues(alpha: 0.06),
                  scheme.primary.withValues(alpha: 0.11),
                  scheme.secondary.withValues(alpha: 0.09),
                  CBColors.transparent,
                ],
                stops: const [0.0, 0.22, 0.56, 1.0],
              ),
              borderRadius: panelRadius,
              border: Border.all(
                  color: color.withValues(alpha: 0.54), width: borderWidth),
              boxShadow: [
                ...CBColors.boxGlow(scheme.primary, intensity: 0.1),
                ...CBColors.boxGlow(scheme.secondary, intensity: 0.08),
              ],
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Section header bar with label + optional count badge.
class CBSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color? color;
  final IconData? icon;

  const CBSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: CBSpace.x4, vertical: CBSpace.x3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(CBRadius.sm),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: CBSpace.x3),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.titleMedium!.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                shadows: CBColors.textGlow(accentColor, intensity: 0.35),
              ),
            ),
          ),
          if (count != null)
            CBBadge(text: count.toString(), color: accentColor),
        ],
      ),
    );
  }
}

/// Compact label chip (e.g., role badge, status tag).
class CBBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const CBBadge({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: CBSpace.x3, vertical: CBSpace.x1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(CBRadius.xs),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        text.toUpperCase(),
        style: CBTypography.micro.copyWith(color: badgeColor),
      ),
    );
  }
}

/// Standard bottom-sheet handle (used when you need a handle inside a custom sheet,
/// e.g. a [DraggableScrollableSheet]).
class CBBottomSheetHandle extends StatelessWidget {
  final EdgeInsets margin;

  const CBBottomSheetHandle({
    super.key,
    this.margin = const EdgeInsets.only(bottom: CBSpace.x4),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 44,
        height: 5,
        margin: margin,
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(CBRadius.pill),
        ),
      ),
    );
  }
}

/// Full-width primary action button. Inherits all styling from the central theme.
class CBPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CBPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor;
    final fg = foregroundColor ??
        (bg == null
            ? null
            : (ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
                ? theme.colorScheme.onSurface
                : CBColors.voidBlack));

    final button = FilledButton(
      style: (bg != null || fg != null)
          ? FilledButton.styleFrom(backgroundColor: bg, foregroundColor: fg)
          : null,
      onPressed: onPressed != null
          ? () {
              HapticService.light();
              onPressed!();
            }
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label.toUpperCase()),
        ],
      ),
    );

    if (!fullWidth) return button;

    return SizedBox(width: double.infinity, child: button);
  }
}

/// Outlined ghost button. Inherits styling from the central theme,
/// but can be customized with a specific color.
class CBGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color; // Retained for accent customization

  const CBGhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: buttonColor, width: 2),
        foregroundColor: buttonColor,
      ),
      onPressed: onPressed != null
          ? () {
              HapticService.light();
              onPressed!();
            }
          : null,
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

/// Dark input field. Inherits all styling from the central theme.
class CBTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final InputDecoration? decoration;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;
  final bool readOnly;
  final TextCapitalization textCapitalization;
  final bool monospace;
  final bool hapticOnChange;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? textStyle;
  final TextAlign textAlign;

  const CBTextField({
    super.key,
    this.controller,
    this.hintText,
    this.errorText,
    this.decoration,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
    this.readOnly = false,
    this.textCapitalization = TextCapitalization.none,
    this.monospace = false,
    this.hapticOnChange = false,
    this.onChanged,
    this.onSubmitted,
    this.inputFormatters,
    this.textStyle,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseDecoration = decoration ?? const InputDecoration();
    final effectiveDecoration = baseDecoration.copyWith(
      hintText: hintText ?? baseDecoration.hintText,
      errorText: errorText ?? baseDecoration.errorText,
    );
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      focusNode: focusNode,
      enabled: enabled,
      readOnly: readOnly,
      onChanged: (val) {
        if (hapticOnChange && val.isNotEmpty) {
          HapticService.selection();
        }
        onChanged?.call(val);
      },
      onSubmitted: onSubmitted,
      textCapitalization: textCapitalization,
      textAlign: textAlign,
      style: textStyle ??
          (monospace ? CBTypography.code : theme.textTheme.bodyLarge!),
      inputFormatters: [
        ...?inputFormatters,
        // Safety net: if no explicit limit is set via maxLength,
        // apply a generous default limit to prevent memory exhaustion attacks.
        if (maxLength == null) LengthLimitingTextInputFormatter(8192),
      ],
      cursorColor: theme.colorScheme.primary,
      decoration: effectiveDecoration,
    );
  }
}

/// Neon-styled switch with consistent track/thumb treatment + haptics.
class CBSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? color;

  const CBSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return Switch(
      value: value,
      onChanged: onChanged == null
          ? null
          : (v) {
              HapticService.selection();
              onChanged!(v);
            },
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accent;
        return scheme.onSurfaceVariant.withValues(alpha: 0.85);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent.withValues(alpha: 0.35);
        }
        return scheme.surfaceContainerHighest.withValues(alpha: 0.85);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent.withValues(alpha: 0.55);
        }
        return scheme.outlineVariant.withValues(alpha: 0.7);
      }),
    );
  }
}

/// Neon-styled slider wrapper (thin track + clean thumb + subtle overlay).
class CBSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final Color? color;

  const CBSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: accent,
        inactiveTrackColor: scheme.outlineVariant.withValues(alpha: 0.35),
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.14),
        trackHeight: 4,
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        onChangeEnd: (v) {
          HapticService.light();
          onChangeEnd?.call(v);
        },
      ),
    );
  }
}

/// Simple "enter" animation: fade + slight slide. Useful for lists and sheets.
class CBFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final Offset beginOffset;

  const CBFadeSlide({
    super.key,
    required this.child,
    this.duration = CBMotion.micro,
    this.delay = Duration.zero,
    this.curve = CBMotion.emphasizedCurve,
    this.beginOffset = const Offset(0, 0.06),
  });

  @override
  State<CBFadeSlide> createState() => _CBFadeSlideState();
}

class _CBFadeSlideState extends State<CBFadeSlide> {
  bool _shown = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _shown = true;
    } else {
      _timer = Timer(widget.delay, () {
        if (!mounted) return;
        setState(() => _shown = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _shown ? 1 : 0,
      duration: widget.duration,
      curve: widget.curve,
      child: AnimatedSlide(
        offset: _shown ? Offset.zero : widget.beginOffset,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

/// Status overlay card (ELIMINATED, SILENCED, etc.).
class CBStatusOverlay extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final String detail;

  const CBStatusOverlay({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CBSpace.x8),
      margin: const EdgeInsets.symmetric(vertical: CBSpace.x4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(CBRadius.md),
        border: Border.all(color: accentColor, width: 2),
        boxShadow: CBColors.boxGlow(accentColor, intensity: 0.3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: accentColor),
          const SizedBox(height: CBSpace.x4),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.displaySmall!.copyWith(color: accentColor),
          ),
          const SizedBox(height: CBSpace.x3),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium!,
          ),
        ],
      ),
    );
  }
}

/// Connection status indicator dot.
class CBConnectionDot extends StatelessWidget {
  final bool isConnected;
  final String? label;

  const CBConnectionDot({super.key, required this.isConnected, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isConnected ? CBColors.success : theme.colorScheme.error;
    final text = label ?? (isConnected ? 'LIVE' : 'OFFLINE');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: CBSpace.x2),
        Text(
          text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall!.copyWith(color: color),
        ),
      ],
    );
  }
}

/// Countdown timer widget for timed phases.
class CBCountdownTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback? onComplete;
  final Color? color;

  const CBCountdownTimer({
    super.key,
    required this.seconds,
    this.onComplete,
    this.color, // Allow overriding base color
  });

  @override
  State<CBCountdownTimer> createState() => _CBCountdownTimerState();
}

class _CBCountdownTimerState extends State<CBCountdownTimer> {
  late int _remaining;
  late final Stream<int> _timerStream;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
    _timerStream = Stream.periodic(
      const Duration(seconds: 1),
      (tick) => widget.seconds - tick - 1,
    ).take(widget.seconds);

    _timerStream.listen((seconds) {
      if (mounted) {
        setState(() => _remaining = seconds);
        if (_remaining <= 5) {
          HapticService.light();
        }
      }
      if (seconds == 0) {
        HapticService.heavy();
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minutes = _remaining ~/ 60;
    final seconds = _remaining % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isCritical = _remaining <= 30;
    final displayColor = widget.color ??
        (isCritical ? CBColors.warning : theme.colorScheme.primary);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CBSpace.x8),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(CBRadius.md),
        border: Border.all(color: displayColor, width: 2),
        boxShadow: CBColors.boxGlow(displayColor, intensity: 0.3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeStr,
            style: CBTypography.timer.copyWith(color: displayColor),
          ),
          const SizedBox(height: CBSpace.x2),
          Text(
            (isCritical ? 'TIME RUNNING OUT' : 'TIME REMAINING').toUpperCase(),
            style: theme.textTheme.labelMedium!.copyWith(color: displayColor),
          ),
        ],
      ),
    );
  }
}

/// Report card showing a list of events or results.
class CBReportCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final Color? color;

  const CBReportCard({
    super.key,
    required this.title,
    required this.lines,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CBSpace.x4),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(CBRadius.md),
        border: Border.all(color: accentColor, width: 1),
        boxShadow: CBColors.boxGlow(accentColor, intensity: 0.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  color: accentColor,
                  shadows: CBColors.textGlow(accentColor, intensity: 0.4),
                ),
          ),
          const SizedBox(height: CBSpace.x4),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: CBSpace.x3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '// ',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                      child: Text(line, style: theme.textTheme.bodySmall!)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unified role avatar with glowing border for the chat feed.
class CBRoleAvatar extends StatefulWidget {
  final String? assetPath;
  final Color? color;
  final double size;
  final bool pulsing;
  final bool breathing; // Enables role-color shimmer cycle

  const CBRoleAvatar({
    super.key,
    this.assetPath,
    this.color,
    this.size = 36,
    this.pulsing = false,
    this.breathing = false,
  });

  @override
  State<CBRoleAvatar> createState() => _CBRoleAvatarState();
}

class _CBRoleAvatarState extends State<CBRoleAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.pulsing || widget.breathing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CBRoleAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldAnimate = widget.pulsing || widget.breathing;
    final wasAnimating = oldWidget.pulsing || oldWidget.breathing;

    if (shouldAnimate && !wasAnimating) {
      _controller.repeat(reverse: true);
    } else if (!shouldAnimate && wasAnimating) {
      _controller.stop();
      _controller.value = 0.6;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.color ?? theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        Color effectiveColor = baseColor;
        double intensity = widget.pulsing ? _animation.value : 0.6;

        // Apply breathing gradient if enabled
        if (widget.breathing) {
          effectiveColor =
              CBColors.roleShimmerColor(baseColor, _controller.value);
          intensity = 0.5 + (_controller.value * 0.5); // 0.5 -> 1.0 glow
        }

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: CBColors.offBlack,
            shape: BoxShape.circle,
            border: Border.all(color: effectiveColor, width: 2),
            boxShadow:
                CBColors.circleGlow(effectiveColor, intensity: intensity),
          ),
          child: ClipOval(
            child: widget.assetPath != null
                ? Image.asset(
                    widget.assetPath!,
                    width: widget.size * 0.6,
                    height: widget.size * 0.6,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      color: effectiveColor,
                      size: widget.size * 0.5,
                    ),
                  )
                : Icon(
                    Icons.smart_toy,
                    color: effectiveColor,
                    size: widget.size * 0.5,
                  ),
          ),
        );
      },
    );
  }
}

/// A compact player chip for inline selection in chat action bubbles.
class CBCompactPlayerChip extends StatelessWidget {
  final String name;
  final String? assetPath;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isDisabled;

  const CBCompactPlayerChip({
    super.key,
    required this.name,
    this.assetPath,
    this.color,
    this.onTap,
    this.isSelected = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;
    final effectiveOpacity = isDisabled ? 0.35 : 1.0;
    final bgColor = isSelected
        ? accentColor.withValues(alpha: 0.15)
        : theme.colorScheme.surface;
    final borderClr =
        isSelected ? accentColor : theme.colorScheme.outlineVariant;

    return Opacity(
      opacity: effectiveOpacity,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderClr, width: 1.5),
              boxShadow: isSelected
                  ? CBColors.boxGlow(accentColor, intensity: 0.2)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tiny avatar
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: CBColors.offBlack,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 1),
                  ),
                  child: ClipOval(
                    child: assetPath != null
                        ? Image.asset(
                            assetPath!,
                            width: 14,
                            height: 14,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: accentColor,
                              size: 12,
                            ),
                          )
                        : Icon(Icons.person, color: accentColor, size: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name.toUpperCase(),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color:
                        isSelected ? accentColor : theme.colorScheme.onSurface,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A lightweight, neon-friendly filter chip (no avatar) for small toggles.
class CBFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;
  final IconData? icon;
  final bool dense;

  const CBFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
    this.icon,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = color ?? scheme.primary;

    final bg = selected
        ? accent.withValues(alpha: 0.16)
        : scheme.surfaceContainerLow.withValues(alpha: 0.9);
    final border = selected
        ? accent.withValues(alpha: 0.9)
        : scheme.outlineVariant.withValues(alpha: 0.7);
    final fg = selected ? accent : scheme.onSurface.withValues(alpha: 0.8);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          HapticService.selection();
          onSelected();
        },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: dense
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 7)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1.5),
            boxShadow:
                selected ? CBColors.boxGlow(accent, intensity: 0.18) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  letterSpacing: 1.0,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Unified player status tile for the host feed.
class CBPlayerStatusTile extends StatelessWidget {
  final String playerName;
  final String roleName;
  final String? assetPath;
  final Color? roleColor;
  final bool isAlive;
  final List<String> statusEffects;

  const CBPlayerStatusTile({
    super.key,
    required this.playerName,
    required this.roleName,
    this.assetPath,
    this.roleColor,
    this.isAlive = true,
    this.statusEffects = const [],
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = roleColor ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: accentColor.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          // Avatar
          CBRoleAvatar(assetPath: assetPath, color: accentColor, size: 32),
          const SizedBox(width: 10),

          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  playerName.toUpperCase(),
                  style: theme.textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    shadows: CBColors.textGlow(accentColor, intensity: 0.4),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleName.toUpperCase(),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color: accentColor,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),

          // Status chips
          if (!isAlive) CBBadge(text: 'DEAD', color: CBColors.dead),
          if (isAlive && statusEffects.isNotEmpty)
            ...statusEffects.map(
              (effect) => Padding(
                padding: const EdgeInsets.only(left: 4),
                child: CBBadge(
                  text: effect.toUpperCase(),
                  color: _statusColor(effect),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String effect) {
    return switch (effect.toLowerCase()) {
      'protected' => CBColors.fromHex('#FF0000'), // Medic (red)
      'silenced' => CBColors.fromHex('#00C853'), // Roofi (green)
      'id checked' => CBColors.fromHex('#4169E1'), // Bouncer (royal blue)
      'sighted' => CBColors.fromHex('#483C32'), // Club Manager (dark brown)
      'alibi' => CBColors.fromHex('#808000'), // Silver Fox (olive)
      'sent home' => CBColors.fromHex('#32CD32'), // Sober (lime green)
      'clinging' => CBColors.fromHex('#FFFF00'), // Clinger (yellow)
      'paralysed' || 'paralyzed' => CBColors.purple,
      _ => CBColors.dead,
    };
  }
}

/// High-density technical status rail.
class CBStatusRail extends StatelessWidget {
  final List<({String label, String value, Color color})> stats;

  const CBStatusRail({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 24,
      width: double.infinity,
      color: theme.scaffoldBackgroundColor,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: stats.length,
        separatorBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '|',
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
        ),
        itemBuilder: (context, index) {
          final s = stats[index];
          return Row(
            children: [
              Text(
                '${s.label}: ',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
              Text(
                s.value.toUpperCase(),
                style: theme.textTheme.bodySmall!.copyWith(
                  color: s.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// CBPrismScaffold: Neon-themed scaffold with glowing effects
class CBPrismScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool showAppBar;
  final bool useSafeArea;
  final List<Widget>? actions;
  final Widget? drawer;
  final String backgroundAsset;
  final bool showBackgroundRadiance;

  const CBPrismScaffold({
    super.key,
    required this.title,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.showAppBar = true,
    this.useSafeArea = true,
    this.actions,
    this.drawer,
    this.backgroundAsset = CBTheme.globalBackgroundAsset,
    this.showBackgroundRadiance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: showAppBar
          ? AppBar(
              title: Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge!,
              ),
              centerTitle: true,
              actions: actions,
            )
          : null,
      drawer: drawer,
      body: CBNeonBackground(
        backgroundAsset: backgroundAsset,
        showRadiance: showBackgroundRadiance,
        child: useSafeArea ? SafeArea(child: body) : body,
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
```

## File: packages/cb_logic/lib/src/room_effects_provider.dart
```dart
import 'package:riverpod/riverpod.dart';

class RoomEffectsState {
  final String? activeEffect;
  final Map<String, dynamic>? activeEffectPayload;

  const RoomEffectsState({
    this.activeEffect,
    this.activeEffectPayload,
  });

  RoomEffectsState copyWith({
    String? activeEffect,
    Map<String, dynamic>? activeEffectPayload,
  }) {
    return RoomEffectsState(
      activeEffect: activeEffect,
      activeEffectPayload: activeEffectPayload,
    );
  }
}

class RoomEffectsNotifier extends Notifier<RoomEffectsState> {
  @override
  RoomEffectsState build() {
    return const RoomEffectsState();
  }

  void triggerEffect(String effectType, Map<String, dynamic>? payload) {
    state =
        state.copyWith(activeEffect: effectType, activeEffectPayload: payload);
    // Clear the effect after a short duration if not a persistent one
    Future.delayed(const Duration(milliseconds: 500), () {
      state = state.copyWith(activeEffect: null, activeEffectPayload: null);
    });
  }
}

final roomEffectsProvider =
    NotifierProvider<RoomEffectsNotifier, RoomEffectsState>(
  RoomEffectsNotifier.new,
);
```

## File: apps/host/lib/widgets/common_dialogs.dart
```dart
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

Future<String?> showStartSessionDialog(BuildContext context) async {
  final controller = TextEditingController();
  final scheme = Theme.of(context).colorScheme;
  return showThemedDialog<String>(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'START GAMES NIGHT',
          style: CBTypography.headlineSmall.copyWith(
            color: scheme.tertiary, // Migrated from CBColors.matrixGreen
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
            shadows: CBColors.textGlow(
                scheme.tertiary), // Migrated from CBColors.matrixGreen
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'CONNECT MULTIPLE ROUNDS FOR A FULL RECAP',
          style: CBTypography.labelSmall.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        CBTextField(
          controller: controller,
          autofocus: true,
          textStyle: CBTypography.bodyLarge.copyWith(color: scheme.onSurface),
          decoration: InputDecoration(
            labelText: 'SESSION NAME',
            labelStyle: CBTypography.bodyMedium.copyWith(
                color: scheme.tertiary.withValues(
                    alpha: 0.7)), // Migrated from CBColors.matrixGreen
            hintText: 'e.g. SATURDAY NIGHT FEVER',
            hintStyle: CBTypography.bodyMedium
                .copyWith(color: scheme.onSurface.withValues(alpha: 0.2)),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color:
                      scheme.tertiary), // Migrated from CBColors.matrixGreen
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CBGhostButton(
              label: 'ABORT',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            CBPrimaryButton(
              label: 'INITIALIZE',
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context, controller.text);
                }
              },
            ),
          ],
        )
      ],
    ),
  );
}
```

import 'dart:math';
import 'package:cb_models/cb_models.dart';
import 'night_actions/night_actions.dart';

class NightResolution {
  final List<Player> players;
  final List<String> report;
  final List<String> teasers;
  final Map<String, List<String>> privateMessages;

  const NightResolution({
    required this.players,
    required this.report,
    required this.teasers,
    required this.privateMessages,
  });
}

class DayResolution {
  final List<Player> players;
  final List<String> report;
  const DayResolution({required this.players, required this.report});
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

    // 6. Apply Silencing (Post-processing)
    for (final silencedId in context.silencedIds) {
      final p = context.getPlayer(silencedId);
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

    return DayResolution(
      players: updatedPlayers,
      report: ['${victim.name} was exiled from the club by popular vote.'],
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

import 'dart:math';
import 'package:cb_models/cb_models.dart';

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
    var currentPlayers = List<Player>.from(players);
    final spicyReport = <String>[];
    final teaserReport = <String>[];
    final privates = Map<String, List<String>>.from(currentPrivateMessages);

    final murderTargets = <String>[];
    final protectedIds = <String>{};
    final blockedIds = <String>{};
    final silencedIds = <String>{};

    // 1. Process Pre-emptive actions (Sober, Roofi)
    for (final p in currentPlayers.where((p) => p.isAlive)) {
      final targetId = log['sober_act_${p.id}'];
      if (targetId != null) {
        blockedIds.add(targetId);
        protectedIds.add(targetId);
        spicyReport.add(
            '${p.name} sent ${players.firstWhere((pl) => pl.id == targetId).name} home.');
        teaserReport.add(
            '${players.firstWhere((pl) => pl.id == targetId).name} was seen leaving the club early.');
      }

      final roofiTarget = log['roofi_act_${p.id}'];
      if (roofiTarget != null) {
        silencedIds.add(roofiTarget);
        // Roofi also blocks if they hit the ONLY active dealer
        final activeDealers = currentPlayers.where((pl) =>
            pl.isAlive &&
            pl.role.id == RoleIds.dealer &&
            !blockedIds.contains(pl.id));
        if (activeDealers.length == 1 &&
            activeDealers.first.id == roofiTarget) {
          blockedIds.add(roofiTarget);
        }
        spicyReport.add(
            '${p.name} drugged ${players.firstWhere((pl) => pl.id == roofiTarget).name}.');
        teaserReport.add(
            '${players.firstWhere((pl) => pl.id == roofiTarget).name} looks a bit dazed.');
      }
    }

    // 2. Process Investigative (Bouncer, Bartender)
    for (final p in currentPlayers
        .where((p) => p.isAlive && !blockedIds.contains(p.id))) {
      final bouncerTarget = log['bouncer_act_${p.id}'];
      if (bouncerTarget != null) {
        final target =
            currentPlayers.firstWhere((pl) => pl.id == bouncerTarget);
        final isStaff = target.alliance == Team.clubStaff;
        privates.putIfAbsent(p.id, () => []).add(
            'ID CHECK: ${target.name} is ${isStaff ? "STAFF" : "NOT STAFF"}.');
        spicyReport.add('${p.name} checked ${target.name}\'s ID.');
        teaserReport
            .add('Someone\'s ID was carefully scrutinized by the Bouncer.');
      }
    }

    // 3. Process Murder (Dealer)
    for (final p in currentPlayers.where((p) =>
        p.isAlive && p.role.id == RoleIds.dealer && !blockedIds.contains(p.id))) {
      final targetId = log['dealer_act_${p.id}'];
      if (targetId != null) murderTargets.add(targetId);
    }

    // 4. Process Protection (Medic)
    for (final p in currentPlayers.where((p) =>
        p.isAlive && p.role.id == RoleIds.medic && !blockedIds.contains(p.id))) {
      final targetId = log['medic_act_${p.id}'];
      if (targetId != null && p.medicChoice == 'PROTECT_DAILY') {
        protectedIds.add(targetId);
      }
    }

    // 5. Apply Deaths
    for (final targetId in murderTargets) {
      if (protectedIds.contains(targetId)) {
        spicyReport.add(
            'A murder attempt on ${players.firstWhere((pl) => pl.id == targetId).name} was thwarted.');
        teaserReport
            .add('A patron barely escaped a close encounter with "the staff".');
        continue;
      }

      final victim = currentPlayers.firstWhere((p) => p.id == targetId);

      // Handle Second Wind
      if (victim.role.id == RoleIds.secondWind && !victim.secondWindConverted) {
        currentPlayers = currentPlayers
            .map((p) => p.id == targetId
                ? p.copyWith(secondWindPendingConversion: true)
                : p)
            .toList();
        spicyReport.add('Second Wind triggered for ${victim.name}.');
        teaserReport.add('Someone survived a lethal encounter.');
        continue;
      }

      // Handle Seasoned Drinker lives
      if (victim.role.id == RoleIds.seasonedDrinker && victim.lives > 1) {
        currentPlayers = currentPlayers
            .map((p) => p.id == targetId ? p.copyWith(lives: p.lives - 1) : p)
            .toList();
        spicyReport
            .add('Seasoned Drinker ${victim.name} lost a life but survived.');
        teaserReport.add('A seasoned patron took a hit but kept going.');
        continue;
      }

      // Final kill
      currentPlayers = currentPlayers
          .map((p) => p.id == targetId
              ? p.copyWith(
                  isAlive: false,
                  deathDay: dayCount,
                  deathReason: 'murder')
              : p)
          .toList();
      spicyReport.add('The Dealers butchered ${victim.name} in cold blood.');
      teaserReport
          .add('A messy scene was found. ${victim.name} didn\'t make it.');
    }

    // Apply silencing
    currentPlayers = currentPlayers
        .map((p) => silencedIds.contains(p.id)
            ? p.copyWith(silencedDay: dayCount)
            : p)
        .toList();

    return NightResolution(
      players: currentPlayers,
      report: spicyReport,
      teasers: teaserReport,
      privateMessages: privates,
    );
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

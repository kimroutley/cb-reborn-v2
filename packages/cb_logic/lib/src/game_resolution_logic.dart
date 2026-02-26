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
  static List<Player> assignRoles(
    List<Player> players, {
    GameStyle gameStyle = GameStyle.chaos,
  }) {
    final rng = Random();
    final count = players.length;
    final staffCount = max(1, count ~/ 5);

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
    final requiredRoles = roleCatalog
        .where((r) => r.isRequired && r.id != RoleIds.dealer)
        .toList();
    for (final role in requiredRoles) {
      if (shuffledPlayers.isNotEmpty) {
        final p = shuffledPlayers.removeAt(0);
        assigned.add(p.copyWith(role: role, alliance: role.alliance));
      }
    }

    // 3. Assign remaining roles using game-style pool
    final modePool = gameStyle.rolePool.toSet();
    final poolRoleIds = modePool.where((id) => id != RoleIds.dealer).toSet();
    final scopedPool = roleCatalog
        .where((r) => !r.isRequired && r.id != RoleIds.dealer)
        .where((r) => poolRoleIds.isEmpty || poolRoleIds.contains(r.id))
        .toList();

    final fallbackPool = roleCatalog
        .where((r) => !r.isRequired && r.id != RoleIds.dealer)
        .toList();

    var remainingRoles = scopedPool.isEmpty ? fallbackPool : [...scopedPool];

    while (shuffledPlayers.isNotEmpty) {
      final p = shuffledPlayers.removeAt(0);
      if (remainingRoles.isEmpty) {
        final partyAnimal = roleCatalogMap[RoleIds.partyAnimal]!;
        assigned
            .add(p.copyWith(role: partyAnimal, alliance: partyAnimal.alliance));
        continue;
      }

      final role = remainingRoles[rng.nextInt(remainingRoles.length)];
      assigned.add(p.copyWith(role: role, alliance: role.alliance));
      if (!role.canRepeat) remainingRoles.remove(role);
    }

    // 4. Special Initialization for multi-life roles
    final actualStaffCount =
        assigned.where((p) => p.alliance == Team.clubStaff).length;
    assigned = assigned.map((p) {
      if (p.role.id == RoleIds.seasonedDrinker) {
        return p.copyWith(lives: actualStaffCount);
      }
      if (p.role.id == RoleIds.allyCat) {
        return p.copyWith(lives: 9);
      }
      return p;
    }).toList();

    return assigned;
  }

  static NightResolution resolveNightActions(
    GameState gameState,
  ) {
    final players = gameState.players;
    final log = gameState.actionLog;
    final dayCount = gameState.dayCount;
    final currentPrivateMessages = gameState.privateMessages;

    final context = NightResolutionContext(
      players: players,
      log: log,
      dayCount: dayCount,
      privateMessages: currentPrivateMessages,
    );

    final actionStrategies = [
      SoberAction(),
      DealerAction(),
      RoofiAction(),
      BouncerAction(),
      BartenderAction(),
      ClubManagerAction(),
      MessyBitchAction(),
      LightweightAction(),
      AttackDogAction(),
      MessyBitchKillAction(),
      MedicAction(),
      SilverFoxAction(),
      WhoreAction(),
    ];

    // Sort strategies by role night priority (stable fallback: declaration order).
    final strategyOrder = <String, int>{
      for (var i = 0; i < actionStrategies.length; i++)
        actionStrategies[i].roleId: i,
    };
    final sortedStrategies = [...actionStrategies]..sort((a, b) {
        if (a.roleId == RoleIds.dealer && b.roleId == RoleIds.roofi) return -1;
        if (a.roleId == RoleIds.roofi && b.roleId == RoleIds.dealer) return 1;
        final roleA = roleCatalogMap[a.roleId];
        final roleB = roleCatalogMap[b.roleId];
        final priorityA = roleA?.nightPriority ?? 999;
        final priorityB = roleB?.nightPriority ?? 999;
        final byPriority = priorityA.compareTo(priorityB);
        if (byPriority != 0) return byPriority;
        return (strategyOrder[a.roleId] ?? 0)
            .compareTo(strategyOrder[b.roleId] ?? 0);
      });

    // Execute strategies in order
    for (final strategy in sortedStrategies) {
      strategy.execute(context);
    }

    // 5. Apply Deaths
    DeathResolutionStrategy().execute(context);

    // Apply silencing
    for (final id in context.silencedPlayerIds) {
      final p = context.getPlayer(id);
      context.updatePlayer(p.copyWith(silencedDay: dayCount));
    }

    // Announce Gawked Wallflower
    if (gameState.gawkedPlayerId != null) {
      final player = context.getPlayer(gameState.gawkedPlayerId!);
      context.addReport(
        '${player.name} was caught gawking at the murder! Their identity as the Wallflower has been exposed.',
      );
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
    final report = <String>[];

    // 1. Identify valid targets (Filter out Alibis)
    final filteredTally = Map<String, int>.from(tally);
    for (final p in players) {
      if (p.alibiDay == dayCount && filteredTally.containsKey(p.id)) {
        filteredTally.remove(p.id);
        report
            .add('${p.name} has an airtight alibi and cannot be exiled today.');
      }
    }

    if (filteredTally.isEmpty) {
      return DayResolution(
        players: players,
        report: [...report, 'The club decided to abstain from exiling anyone.'],
      );
    }

    final sorted = filteredTally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;

    if (top.key == 'abstain') {
      return DayResolution(
        players: players,
        report: [...report, 'The club decided to abstain from exiling anyone.'],
      );
    }

    // Check for ties
    if (sorted.length > 1 && sorted[1].value == top.value) {
      return DayResolution(
        players: players,
        report: [...report, 'The vote ended in a tie. No one was exiled.'],
      );
    }

    var victimId = top.key;
    var victim = players.firstWhere((p) => p.id == victimId);
    var reportMsg = '${victim.name} was exiled from the club by popular vote.';
    String? whoreWhoUsedDeflectionId;

    // 2. Resolve Whore Deflection
    if (victim.alliance == Team.clubStaff) {
      Player? activeWhore;
      for (final p in players) {
        if (p.isAlive &&
            p.role.id == RoleIds.whore &&
            !p.whoreDeflectionUsed &&
            p.whoreDeflectionTargetId != null) {
          activeWhore = p;
          break;
        }
      }

      if (activeWhore != null) {
        final targetId = activeWhore.whoreDeflectionTargetId!;
        Player? scapegoat;
        for (final p in players) {
          if (p.id == targetId && p.isAlive) {
            scapegoat = p;
            break;
          }
        }

        if (scapegoat != null) {
          reportMsg =
              'SCANDAL: The vote was deflected! ${scapegoat.name} was framed and exiled in ${victim.name}\'s place.';
          victimId = scapegoat.id;
          victim = scapegoat;
          whoreWhoUsedDeflectionId = activeWhore.id;
        }
      }
    }

    final updatedPlayers = players.map((p) {
      if (p.id == victimId) {
        return p.copyWith(
          isAlive: false,
          deathDay: dayCount,
          deathReason: 'exile',
        );
      }
      if (p.id == whoreWhoUsedDeflectionId) {
        return p.copyWith(whoreDeflectionUsed: true);
      }
      return p;
    }).toList();

    events.add(GameEvent.death(
      playerId: victimId,
      reason: 'exile',
      day: dayCount,
    ));

    return DayResolution(
      players: updatedPlayers,
      report: [...report, reportMsg],
      events: events,
    );
  }

  static WinResult? checkWinCondition(List<Player> players) {
    final livingPlayers = players.where((p) => p.isAlive).toList();

    // Messy Bitch solo win: if every living player has heard a rumour and
    // at least one living Messy Bitch remains.
    final livingMessyBitches =
        livingPlayers.where((p) => p.role.id == RoleIds.messyBitch).toList();
    if (livingMessyBitches.isNotEmpty &&
        livingPlayers.isNotEmpty &&
        livingPlayers.every((p) => p.hasRumour)) {
      return WinResult(
        winner: Team.neutral,
        report: [
          'Messy Bitch has spread rumors to everyone still alive. Messy Bitch wins solo!',
        ],
      );
    }

    int staff = 0;
    int pa = 0;

    for (final p in livingPlayers) {
      if (p.alliance == Team.clubStaff) {
        staff++;
      } else if (p.alliance == Team.partyAnimals) {
        pa++;
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

  static String getImmediateActionText(
    Player actor,
    Player target,
    GameState state,
  ) {
    switch (actor.role.id) {
      case RoleIds.bouncer:
        return 'You check ${target.name}\'s ID. They are a ${target.alliance.name}.';
      case RoleIds.bartender:
        return 'You serve ${target.name} a drink and listen for gossip. You learn they visited ${state.actionLog[target.id] ?? 'nobody'}.';
      case RoleIds.clubManager:
        return 'You check the books on ${target.name}. Their role is ${target.role.name}.';
      default:
        return '${actor.name} targeted ${target.name}.';
    }
  }

  static GameState handleDeathTriggers(GameState state, String deadPlayerId) {
    final deadPlayer = state.players.firstWhere((p) => p.id == deadPlayerId);
    var updatedPlayers = List<Player>.from(state.players);
    final history = <String>[];
    final events = <GameEvent>[];

    // 1. Clinger Trigger: If partner dies, Clinger dies.
    for (final p in updatedPlayers
        .where((p) => p.isAlive && p.role.id == RoleIds.clinger)) {
      if (p.clingerPartnerId == deadPlayerId) {
        updatedPlayers = updatedPlayers
            .map(
              (pl) => pl.id == p.id
                  ? pl.copyWith(
                      isAlive: false,
                      deathDay: state.dayCount,
                      deathReason: 'clinger_bond',
                    )
                  : pl,
            )
            .toList();
        history.add('The Clinger ${p.name} died with their partner.');
        events.add(
          GameEvent.death(
            playerId: p.id,
            reason: 'clinger_bond',
            day: state.dayCount,
          ),
        );
      }
    }

    // 2. Creep Trigger: If target dies, Creep inherits role.
    for (final p in updatedPlayers
        .where((p) => p.isAlive && p.role.id == RoleIds.creep)) {
      if (p.creepTargetId == deadPlayerId) {
        updatedPlayers = updatedPlayers
            .map(
              (pl) => pl.id == p.id
                  ? pl.copyWith(
                      role: deadPlayer.role,
                      alliance: deadPlayer.alliance,
                      creepTargetId: null,
                    )
                  : pl,
            )
            .toList();
        history.add(
          'The Creep ${p.name} inherited the role of ${deadPlayer.role.name}.',
        );
      }
    }

    if (history.isNotEmpty) {
      return state.copyWith(
        players: updatedPlayers,
        gameHistory: [...state.gameHistory, ...history],
        eventLog: [...state.eventLog, ...events],
      );
    }

    return state;
  }

  static GameState applyWinResult(GameState state, WinResult win) {
    final winningReport = List<String>.from(win.report);
    if (win.winner != Team.neutral) {
      final livingManagers = state.players.where(
        (p) => p.isAlive && p.role.id == RoleIds.clubManager,
      );
      if (livingManagers.isNotEmpty) {
        final managerNames = livingManagers.map((p) => p.name).join(', ');
        winningReport.add(
          'Club Manager survived and wins with the house: $managerNames.',
        );
      }
    }

    return state.copyWith(
      phase: GamePhase.endGame,
      winner: win.winner,
      endGameReport: winningReport,
      scriptQueue: const [],
      scriptIndex: 0,
    );
  }
}

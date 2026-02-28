import 'dart:math';
import 'package:cb_models/cb_models.dart';
import 'night_actions/night_actions.dart';

class NightResolution {
  final List<Player> players;
  final List<String> report;
  final List<String> teasers;
  final Map<String, List<String>> privateMessages;
  final List<GameEvent> events;
  final List<({String playerId, String roleId})> pendingCreepSetups;

  const NightResolution({
    required this.players,
    required this.report,
    required this.teasers,
    required this.privateMessages,
    this.events = const [],
    this.pendingCreepSetups = const [],
  });
}

class DayResolution {
  final List<Player> players;
  final List<String> report;
  final List<GameEvent> events;
  final Map<String, List<String>> privateMessages;

  const DayResolution({
    required this.players,
    required this.report,
    this.events = const [],
    this.privateMessages = const {},
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

    // 4. Special Initialisation for multi-life roles
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
        int getPriority(NightActionStrategy s) {
          if (s is AttackDogAction) return 9;
          if (s is MessyBitchKillAction) return 10;

          return roleCatalogMap[s.roleId]?.nightPriority ?? 999;
        }

        final priorityA = getPriority(a);
        final priorityB = getPriority(b);

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

    // 6. Handle Second Wind Conversion
    for (final p in context.players) {
      if (p.secondWindPendingConversion && !p.secondWindConverted) {
        final dealerRole = roleCatalogMap[RoleIds.dealer]!;
        context.updatePlayer(p.copyWith(
          role: dealerRole,
          alliance: Team.clubStaff,
          secondWindConverted: true,
          secondWindPendingConversion: false,
          secondWindConversionNight: gameState.dayCount,
        ));
      }
    }

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
    Map<String, String> votesByVoter,
    TieBreakStrategy tieBreakStrategy,
    int dayCount, {
    Map<String, List<String>>? privateMessages,
  }) {
    if (tally.isEmpty) {
      return DayResolution(players: players, report: ['No votes were cast.']);
    }

    final events = <GameEvent>[];
    final report = <String>[];
    final updatedPrivateMessages =
        privateMessages != null ? Map<String, List<String>>.from(privateMessages) : <String, List<String>>{};

    void addPrivateMessage(String playerId, String message) {
      updatedPrivateMessages.putIfAbsent(playerId, () => []).add(message);
    }

    // Log individual votes
    for (final entry in votesByVoter.entries) {
      final voterId = entry.key;
      final targetId = entry.value;
      final voter = players.firstWhere((p) => p.id == voterId,
          orElse: () => Player(
                id: voterId,
                name: 'Unknown Voter',
                role: roleCatalog.first,
                alliance: Team.unknown,
              ));
      final target = players.firstWhere(
        (p) => p.id == targetId,
        orElse: () => Player(
          id: '',
          name: 'Abstain',
          role: roleCatalog.first,
          alliance: Team.unknown,
        ),
      );
      report.add('${voter.name} cast a vote against ${target.name}.');
      events.add(GameEvent.vote(
        voterId: voterId,
        targetId: targetId,
        day: dayCount,
      ));
    }

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
        events: events,
      );
    }

    final sorted = filteredTally.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;

    if (top.key == 'abstain') {
      return DayResolution(
        players: players,
        report: [...report, 'The club decided to abstain from exiling anyone.'],
        events: events,
      );
    }

    // Tie handling strategy
    final isTie = sorted.length > 1 && sorted[1].value == top.value;
    var selectedTargetId = top.key;
    if (isTie) {
      final tiedTargetIds = sorted
          .where((e) => e.value == top.value && e.key != 'abstain')
          .map((e) => e.key)
          .toList();

      if (tiedTargetIds.isEmpty) {
        return DayResolution(
          players: players,
          report: [
            ...report,
            'The club tied itself in knots and abstained from exile.',
          ],
          events: events,
        );
      }

      switch (tieBreakStrategy) {
        case TieBreakStrategy.peaceful:
          events.add(GameEvent.tieBreak(
            day: dayCount,
            strategy: TieBreakStrategy.peaceful.name,
            tiedPlayerIds: tiedTargetIds,
            resultantExileIds: const [],
          ));
          return DayResolution(
            players: players,
            report: [
              ...report,
              'Tie break: NO EXILE. The club chose diplomacy over another poor life choice.',
            ],
            events: events,
          );
        case TieBreakStrategy.random:
          final rng = Random(dayCount + players.length + votesByVoter.length);
          selectedTargetId = tiedTargetIds[rng.nextInt(tiedTargetIds.length)];
          events.add(GameEvent.tieBreak(
            day: dayCount,
            strategy: TieBreakStrategy.random.name,
            tiedPlayerIds: tiedTargetIds,
            resultantExileIds: [selectedTargetId],
          ));
          report.add(
            'Tie break: RANDOM. The DJ hit shuffle and fate picked the exile.',
          );
          break;
        case TieBreakStrategy.bloodbath:
          final doomedIds = tiedTargetIds
              .where((id) => players.any((p) => p.id == id && p.isAlive))
              .toSet()
              .toList();
          events.add(GameEvent.tieBreak(
            day: dayCount,
            strategy: TieBreakStrategy.bloodbath.name,
            tiedPlayerIds: tiedTargetIds,
            resultantExileIds: doomedIds,
          ));
          final updatedPlayers = players.map((p) {
            if (doomedIds.contains(p.id)) {
              return p.copyWith(
                isAlive: false,
                deathDay: dayCount,
                deathReason: 'exile',
              );
            }
            return p;
          }).toList();

          for (final playerId in doomedIds) {
            events.add(GameEvent.death(
              playerId: playerId,
              reason: 'exile',
              day: dayCount,
            ));
          }

          final names = doomedIds
              .map((id) => players
                  .firstWhere(
                    (p) => p.id == id,
                    orElse: () => Player(
                      id: '',
                      name: '',
                      role: roleCatalog.first,
                      alliance: Team.unknown,
                    ),
                  )
                  .name)
              .where((name) => name.isNotEmpty)
              .join(', ');

          final count = doomedIds.length;
          return DayResolution(
            players: updatedPlayers,
            report: [
              ...report,
              'The club descended into a BLOODBATH! $count patron${count == 1 ? '' : 's'} ${count == 1 ? 'was' : 'were'} kicked out.',
              'Tie break: BLOODBATH. The club made spectacularly poor life choices and exiled everyone tied.',
              if (names.isNotEmpty) 'Exiled in the chaos: $names.',
            ],
            events: events,
          );
        case TieBreakStrategy.dealerMercy:
          final dealerVotes = <String, int>{};
          for (final vote in votesByVoter.entries) {
            final voter = players.firstWhere(
              (p) => p.id == vote.key,
              orElse: () => Player(
                id: '',
                name: '',
                role: roleCatalog.first,
                alliance: Team.unknown,
              ),
            );
            if (voter.alliance != Team.clubStaff) continue;
            if (!tiedTargetIds.contains(vote.value)) continue;
            dealerVotes[vote.value] = (dealerVotes[vote.value] ?? 0) + 1;
          }

          if (dealerVotes.isEmpty) {
            events.add(GameEvent.tieBreak(
              day: dayCount,
              strategy: '${TieBreakStrategy.dealerMercy.name}_fallback',
              tiedPlayerIds: tiedTargetIds,
              resultantExileIds: const [],
            ));
            return DayResolution(
              players: players,
              report: [
                ...report,
                'Tie break: DEALER MERCY found no deciding Dealer vote. No exile tonight.',
              ],
              events: events,
            );
          }

          final dealerSorted = dealerVotes.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final dealerTop = dealerSorted.first.value;
          final dealerLeaders = dealerSorted
              .where((e) => e.value == dealerTop)
              .map((e) => e.key)
              .toList();

          if (dealerLeaders.length == 1) {
            selectedTargetId = dealerLeaders.first;
          } else {
            final rng = Random(dayCount + dealerLeaders.length + 17);
            selectedTargetId = dealerLeaders[rng.nextInt(dealerLeaders.length)];
          }
          events.add(GameEvent.tieBreak(
            day: dayCount,
            strategy: TieBreakStrategy.dealerMercy.name,
            tiedPlayerIds: tiedTargetIds,
            resultantExileIds: [selectedTargetId],
          ));
          report.add(
            'Tie break: DEALER MERCY. House privilege activated; the Dealers nudged the final call.',
          );
          break;
        case TieBreakStrategy.silentTreatment:
          final silencedIds = tiedTargetIds.toSet();
          events.add(GameEvent.tieBreak(
            day: dayCount,
            strategy: TieBreakStrategy.silentTreatment.name,
            tiedPlayerIds: tiedTargetIds,
            resultantExileIds: const [],
          ));
          final updatedPlayers = players.map((p) {
            if (silencedIds.contains(p.id) && p.isAlive) {
              return p.copyWith(silencedDay: dayCount + 1);
            }
            return p;
          }).toList();
          return DayResolution(
            players: updatedPlayers,
            report: [
              ...report,
              'Tie break: SILENT TREATMENT. Nobody was exiled, but tied players lose their voice tomorrow.',
            ],
            events: events,
          );
      }
    }

    var victimId = selectedTargetId;
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
              "ABSOLUTE CHAOS: ${victim.name} (The Dealer) was about to be exiled, but a scandalous photo surfaced! ${scapegoat.name} has been framed and kicked out in their place!";
          addPrivateMessage(scapegoat.id,
              "You've been framed! Your 'friend' just pinned their crimes on you. You're out of the club.");
          addPrivateMessage(activeWhore.id,
              "Your scapegoat worked perfectly. ${scapegoat.name} took the fall for you. You're safe... for now.");
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
          deathReason: "exile",
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
      privateMessages: updatedPrivateMessages,
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
          'Messy Bitch has spread rumours to everyone still alive. Messy Bitch wins solo!',
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
    // Night actions should be secretive until resolution
    if (state.phase == GamePhase.night) {
      return 'Action confirmed.';
    }

    switch (actor.role.id) {
      case RoleIds.bouncer:
        return 'You check ${target.name}\'s ID. Results will be revealed in the morning.';
      case RoleIds.bartender:
        return 'You mix a drink for ${target.name}. Intel will be revealed in the morning.';
      case RoleIds.clubManager:
        return 'You check the books on ${target.name}. File contents will be revealed in the morning.';
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

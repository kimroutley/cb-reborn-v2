import 'package:cb_models/cb_models.dart';
import 'role_logic.dart';

class ScriptBuilder {
  /// Generates the setup script (Night 0 / Day 1 Intro)
  static List<ScriptStep> buildSetupScript(List<Player> players,
      {int dayCount = 0}) {
    final steps = <ScriptStep>[
      const ScriptStep(
        id: 'intro_01',
        title: 'WELCOME TO CLUB BLACKOUT',
        readAloudText:
            'Welcome to Club Blackout. The neon is on, the drinks are flowing, and somebody in this room is not who they say they are. Staff are running the show. Party Animals are here to shut it down. Trust no one.',
        instructionText: 'Wait for players to settle.',
        actionType: ScriptActionType.info,
        aiVariationPrompt:
            'Open the game with dramatic neon-club narration. Keep all role reveals hidden.',
        aiVariationVoice: 'host_hype',
      ),
      const ScriptStep(
        id: 'assign_roles_warning',
        title: 'ROLE ASSIGNMENT',
        readAloudText:
            'Check your devices now. Your role has been assigned. Read it carefully — your survival depends on it.',
        instructionText: 'Ensure all players have seen their role card.',
        actionType: ScriptActionType.confirm,
      ),
    ];

    String? lastRoleId;

    void addSteps(List<Player> specificPlayers, String titleBase,
        String readAloudBase, String instructionBase,
        {required ScriptActionType actionType}) {
      for (final p in specificPlayers) {
        final isContinuation = p.role.id == lastRoleId;
        steps.add(ScriptStep(
          id: '${p.role.id}_setup_${p.id}_$dayCount',
          title: isContinuation ? '$titleBase (CONT.)' : titleBase,
          readAloudText: isContinuation ? '' : readAloudBase,
          instructionText: instructionBase,
          actionType: actionType,
          roleId: p.role.id,
        ));
        lastRoleId = p.role.id;
      }
    }

    // ── Medic binary choice ──
    final medics =
        players.where((p) => p.role.id == RoleIds.medic && p.isAlive).toList();
    for (final medic in medics) {
      final isContinuation = medic.role.id == lastRoleId;
      steps.add(ScriptStep(
        id: 'medic_choice_${medic.id}_$dayCount',
        title: isContinuation ? 'MEDIC - CHOICE (CONT.)' : 'MEDIC - CHOICE',
        readAloudText: isContinuation
            ? ''
            : 'Medic, wake up. You have a choice to make — protect someone every night, or save your power for a one-time resurrection.',
        instructionText: 'CHOOSE YOUR STRATEGY: NIGHTLY PROTECTION OR ONE-TIME REVIVE',
        actionType: ScriptActionType.binaryChoice,
        roleId: RoleIds.medic,
        options: const ['PROTECT_DAILY', 'REVIVE'],
      ));
      lastRoleId = medic.role.id;
    }

    // ── Creep picks a target at Night 0 ──
    final creeps =
        players.where((p) => p.role.id == RoleIds.creep && p.isAlive).toList();
    addSteps(
      creeps,
      'THE CREEP',
      'Creep, wake up. Choose someone to shadow — you will inherit their identity.',
      'SELECT A PLAYER TO MIMIC (INHERIT ALLIANCE & ROLE)',
      actionType: ScriptActionType.selectPlayer,
    );

    // ── Clinger chooses a partner at Night 0 ──
    final clingers = players
        .where((p) => p.role.id == RoleIds.clinger && p.isAlive)
        .toList();
    addSteps(
      clingers,
      'THE CLINGER',
      'Clinger, wake up. Who are you obsessing over? Choose your partner wisely — their fate is now yours.',
      'SELECT A PARTNER TO OBSESS OVER',
      actionType: ScriptActionType.selectPlayer,
    );

    // ── Drama Queen chooses two swap targets at Night 0 ──
    final dramaQueens = players
        .where((p) => p.role.id == RoleIds.dramaQueen && p.isAlive)
        .toList();
    for (final dramaQueen in dramaQueens) {
      final isContinuation = dramaQueen.role.id == lastRoleId;
      steps.add(ScriptStep(
        id: 'drama_queen_setup_${dramaQueen.id}_$dayCount',
        title: isContinuation ? 'THE DRAMA QUEEN (CONT.)' : 'THE DRAMA QUEEN',
        readAloudText: isContinuation
            ? ''
            : 'Drama Queen, wake up. Pick two players. If you die, their roles swap. Make it count.',
        instructionText: 'SELECT TWO PLAYERS FOR POST-MORTEM ROLE SWAP',
        actionType: ScriptActionType.selectTwoPlayers,
        roleId: RoleIds.dramaQueen,
      ));
      lastRoleId = dramaQueen.role.id;
    }

    // ── Wallflower instruction ──
    final wallflowers = players
        .where((p) => p.role.id == RoleIds.wallflower && p.isAlive)
        .toList();
    if (wallflowers.isNotEmpty) {
      steps.add(const ScriptStep(
        id: 'wallflower_info_global',
        title: 'WALLFLOWER IN PLAY',
        readAloudText:
            'Heads up — there is a Wallflower in the club tonight. During the kill, they get a peek. Eyes everywhere.',
        instructionText:
            'Announce Wallflower mechanic. No player input required.',
        actionType: ScriptActionType.info,
      ));
    }

    return steps;
  }

  /// Generates the Night Script based on active roles
  static List<ScriptStep> buildNightScript(List<Player> players, int dayCount) {
    if (dayCount == 0 || players.isEmpty) {
      return buildSetupScript(players, dayCount: dayCount);
    }

    final steps = <ScriptStep>[
      ScriptStep(
        id: 'night_start_$dayCount',
        title: 'NIGHT PHASE',
        readAloudText:
            'The lights go down. Club Blackout falls silent. Close your eyes — the night shift begins.',
        instructionText: 'Wait for silence.',
        actionType: ScriptActionType.info,
      ),
    ];

    final activePlayers = players.where((p) => p.isActive).toList()
      ..sort((a, b) => a.role.nightPriority.compareTo(b.role.nightPriority));

    String? lastRoleId;

    for (final player in activePlayers) {
      if (player.role.id == RoleIds.wallflower) {
        continue;
      }
      final strategy = roleStrategies[player.role.id];
      if (strategy == null) {
        continue;
      }

      if (strategy.canAct(player, dayCount)) {
        var step = strategy.buildStep(player, dayCount);

        if (step.roleId == lastRoleId) {
          step = step.copyWith(
            readAloudText: '',
            title: '${step.title} (CONT.)',
          );
        }

        steps.add(step);
        lastRoleId = step.roleId;
      }
    }

    // ── Attack Dog ──
    final attackDogStrategy =
        roleStrategies[RoleIds.attackDog]! as AttackDogStrategy;
    for (final player
        in players.where((p) => p.isActive && p.role.id == RoleIds.clinger)) {
      if (attackDogStrategy.canAct(player, dayCount)) {
        var step = attackDogStrategy.buildStep(player, dayCount);
        if (step.roleId == lastRoleId) {
          step = step.copyWith(
            readAloudText: '',
            title: '${step.title} (CONT.)',
          );
        }
        steps.add(step);
        lastRoleId = step.roleId;
      }
    }

    // ── Messy Bitch Kill ──
    final mbKillStrategy =
        roleStrategies[RoleIds.messyBitchKill]! as MessyBitchKillStrategy;
    for (final player in players
        .where((p) => p.isActive && p.role.id == RoleIds.messyBitch)) {
      if (mbKillStrategy.canAct(player, dayCount)) {
        var step = mbKillStrategy.buildStep(player, dayCount);
        if (step.roleId == lastRoleId) {
          step = step.copyWith(
            readAloudText: '',
            title: '${step.title} (CONT.)',
          );
        }
        steps.add(step);
        lastRoleId = step.roleId;
      }
    }

    // ── Wallflower Host Observation ──
    final wallflowers = players
        .where((p) => p.role.id == RoleIds.wallflower && p.isAlive)
        .toList();
    final dealerStepIndex =
        steps.lastIndexWhere((s) => s.id.startsWith('dealer_act_'));

    if (wallflowers.isNotEmpty && dealerStepIndex != -1) {
      var insertIndex = dealerStepIndex + 1;

      for (final wallflower in wallflowers) {
        steps.insert(
          insertIndex,
          ScriptStep(
            id: 'wallflower_observe_${wallflower.id}_$dayCount',
            title: 'HOST OBSERVATION',
            readAloudText: '',
            instructionText:
                'Did ${wallflower.name} peek? (HOST INPUT ONLY)',
            actionType: ScriptActionType.binaryChoice,
            roleId: null, // Host only
            options: const ['PEEKED', 'GAWKED'],
          ),
        );
        insertIndex++;
      }
    }

    if (steps.length == 1) {
      steps.add(ScriptStep(
        id: 'night_no_actions_$dayCount',
        title: 'NIGHT PHASE',
        readAloudText: 'The night is quiet. No actions are taken.',
        instructionText: 'Proceed to morning.',
        actionType: ScriptActionType.info,
      ));
    }

    steps.add(ScriptStep(
      id: 'night_end_$dayCount',
      title: 'WAKE UP',
      readAloudText:
          'Dawn breaks. Open your eyes — let\'s see who made it through the night.',
      instructionText: 'Proceed to Morning Report.',
      actionType: ScriptActionType.info,
    ));

    return steps;
  }

  static List<ScriptStep> buildDayScript(int dayCount,
      [List<Player> players = const []]) {
    final alive = players.where((p) => p.isAlive).length;
    final timerSeconds = alive > 0 ? (alive * 30).clamp(30, 300) : 300;

    final steps = <ScriptStep>[
      ScriptStep(
        id: 'day_results_$dayCount',
        title: 'MORNING REPORT',
        readAloudText:
            'Last call is over. The damage report is in. Let\'s see who didn\'t survive the night.',
        instructionText: 'Review the night report.',
        actionType: ScriptActionType.showInfo,
        aiVariationPrompt:
            'Summarize last night in cinematic mystery style, suspenseful but concise.',
        aiVariationVoice: 'nightclub_noir',
      ),
    ];

    // ── Second Wind conversion opportunity ──
    final pendingConversions = players.where(
      (p) => p.isAlive && p.secondWindPendingConversion,
    );
    for (final sw in pendingConversions) {
      steps.add(ScriptStep(
        id: 'second_wind_convert_${sw.id}_$dayCount',
        title: 'SECOND WIND',
        readAloudText:
            '${sw.name} has a Second Wind — they survived the hit. Dealers, what\'s it going to be: recruit them, or finish the job?',
        instructionText:
            'Ask Dealers for decision. HOST INPUT: Convert or Execute?',
        actionType: ScriptActionType.binaryChoice,
        roleId: null, // Host-mediated, no specific player ID to avoid sync lock
        options: const ['CONVERT', 'EXECUTE'],
      ));
    }

    steps.addAll([
      ScriptStep(
        id: 'day_start_$dayCount',
        title: 'DAY $dayCount',
        readAloudText:
            'The club is open for business. Talk, argue, accuse — the clock is ticking.',
        instructionText: 'Start the timer.',
        actionType: ScriptActionType.showTimer,
        timerSeconds: timerSeconds,
      ),
      ScriptStep(
        id: 'day_vote_$dayCount',
        title: 'VOTING',
        readAloudText:
            'Time\'s up. Cast your votes — who is getting thrown out of Club Blackout?',
        instructionText: 'Monitor voting via Dashboard.',
        actionType: ScriptActionType.selectPlayer,
      ),
    ]);

    return steps;
  }
}

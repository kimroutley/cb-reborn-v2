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
            'Welcome to Club Blackout. Some of you are staff members keeping this place running. Others... are here to ruin the party.',
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
            'Please check your devices now. You have received your role.',
        instructionText: 'Ensure all players have seen their role card.',
        actionType: ScriptActionType.confirm,
      ),
    ];

    // ── Medic binary choice ──
    final medics =
        players.where((p) => p.role.id == RoleIds.medic && p.isAlive).toList();
    for (final medic in medics) {
      steps.add(ScriptStep(
        id: 'medic_choice_${medic.id}_$dayCount',
        title: 'MEDIC - CHOICE',
        readAloudText: 'Medic, choose your strategy for the game.',
        instructionText: 'Protect Daily or Revive (one time).',
        actionType: ScriptActionType.binaryChoice,
        roleId: RoleIds.medic,
        options: const ['PROTECT_DAILY', 'REVIVE'],
      ));
    }

    // ── Creep picks a target at Night 0 ──
    final creeps =
        players.where((p) => p.role.id == RoleIds.creep && p.isAlive).toList();
    for (final creep in creeps) {
      steps.add(ScriptStep(
        id: 'creep_setup_${creep.id}_$dayCount',
        title: 'THE CREEP',
        readAloudText: 'Creep, wake up and choose a player to mimic.',
        instructionText:
            'This player\'s alliance becomes yours. If they die, you inherit their role.',
        actionType: ScriptActionType.selectPlayer,
        roleId: RoleIds.creep,
      ));
    }

    // ── Clinger chooses a partner at Night 0 ──
    final clingers = players
        .where((p) => p.role.id == RoleIds.clinger && p.isAlive)
        .toList();
    for (final clinger in clingers) {
      steps.add(ScriptStep(
        id: 'clinger_setup_${clinger.id}_$dayCount',
        title: 'THE CLINGER',
        readAloudText: 'Clinger, wake up and choose your partner.',
        instructionText:
            'You are now obsessed with this player. If they die, you die.',
        actionType: ScriptActionType.selectPlayer,
        roleId: RoleIds.clinger,
      ));
    }

    // ── Drama Queen chooses two swap targets at Night 0 ──
    final dramaQueens = players
        .where((p) => p.role.id == RoleIds.dramaQueen && p.isAlive)
        .toList();
    for (final dramaQueen in dramaQueens) {
      steps.add(ScriptStep(
        id: 'drama_queen_setup_${dramaQueen.id}_$dayCount',
        title: 'THE DRAMA QUEEN',
        readAloudText:
            'Drama Queen, wake up and pick two players for your vendetta.',
        instructionText:
            'Select two players. If you are exiled, their role cards will be swapped.',
        actionType: ScriptActionType.selectTwoPlayers,
        roleId: RoleIds.dramaQueen,
      ));
    }

    // ── Wallflower instruction ──
    final wallflowers = players
        .where((p) => p.role.id == RoleIds.wallflower && p.isAlive)
        .toList();
    if (wallflowers.isNotEmpty) {
      for (final wallflower in wallflowers) {
        steps.add(ScriptStep(
          id: 'wallflower_info_${wallflower.id}',
          title: 'WALLFLOWER IN PLAY',
          readAloudText:
              'A heads-up for everyone: a Wallflower is in play. During the night\'s murder, they will be allowed to briefly open their eyes.',
          instructionText:
              'Announce that the Wallflower ability is active. The actual peek happens after the Dealer action at night.',
          actionType: ScriptActionType.info,
        ));
      }
    }

    return steps;
  }

  /// Generates the Night Script based on active roles
  static List<ScriptStep> buildNightScript(List<Player> players, int dayCount) {
    if (dayCount == 0 || players.isEmpty) {
      // Fallback for empty state or setup
      return buildSetupScript(players, dayCount: dayCount);
    }

    final steps = <ScriptStep>[
      ScriptStep(
        id: 'night_start_$dayCount',
        title: 'NIGHT PHASE',
        readAloudText: 'It is now night time. Everyone close your eyes.',
        instructionText: 'Wait for silence.',
        actionType: ScriptActionType.info,
      ),
    ];

    // Priority Sort: Lower number first
    final activePlayers = players.where((p) => p.isActive).toList()
      ..sort((a, b) => a.role.nightPriority.compareTo(b.role.nightPriority));

    for (final player in activePlayers) {
      // Wallflower is handled separately now
      if (player.role.id == RoleIds.wallflower) {
        continue;
      }
      final strategy = roleStrategies[player.role.id];
      if (strategy == null) {
        continue;
      }

      if (strategy.canAct(player, dayCount)) {
        steps.add(strategy.buildStep(player, dayCount));
      }
    }

    // ── Attack Dog: Clinger freed after partner death, one-shot ──
    final attackDogStrategy =
        roleStrategies[RoleIds.attackDog]! as AttackDogStrategy;
    for (final player
        in players.where((p) => p.isActive && p.role.id == RoleIds.clinger)) {
      if (attackDogStrategy.canAct(player, dayCount)) {
        steps.add(attackDogStrategy.buildStep(player, dayCount));
      }
    }

    // ── Messy Bitch Kill: optional one-shot ability ──
    final mbKillStrategy =
        roleStrategies[RoleIds.messyBitchKill]! as MessyBitchKillStrategy;
    for (final player in players
        .where((p) => p.isActive && p.role.id == RoleIds.messyBitch)) {
      if (mbKillStrategy.canAct(player, dayCount)) {
        steps.add(mbKillStrategy.buildStep(player, dayCount));
      }
    }

    // ── Wallflower Host Observation ──
    final wallflowers = players
        .where((p) => p.role.id == RoleIds.wallflower && p.isAlive)
        .toList();
    final dealerStepIndex =
        steps.indexWhere((s) => s.id.startsWith('dealer_act_'));

    if (wallflowers.isNotEmpty && dealerStepIndex != -1) {
      for (final wallflower in wallflowers) {
        // This step is for the HOST, not the player. It happens after the murder.
        steps.insert(
          dealerStepIndex + 1, // Place it right after the dealer's action
          ScriptStep(
            id: 'wallflower_observe_${wallflower.id}_$dayCount',
            title: 'HOST OBSERVATION',
            readAloudText: '', // No read-aloud text for this host-only action
            instructionText:
                'Observe ${wallflower.name}, how did they witness the murder?',
            actionType: ScriptActionType.binaryChoice,
            roleId: RoleIds.wallflower,
            options: const ['PEEKED', 'GAWKED'],
          ),
        );
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
      readAloudText: 'The sun is rising. Everyone wake up.',
      instructionText: 'Proceed to Morning Report.',
      actionType: ScriptActionType.info,
    ));

    return steps;
  }

  static List<ScriptStep> buildDayScript(int dayCount,
      [List<Player> players = const []]) {
    // Smart timer: 30s per alive player, max 300s (5 min)
    final alive = players.where((p) => p.isAlive).length;
    final timerSeconds = alive > 0 ? (alive * 30).clamp(30, 300) : 300;

    final steps = <ScriptStep>[
      ScriptStep(
        id: 'day_results_$dayCount',
        title: 'MORNING REPORT',
        readAloudText: 'The night is over. Here is what happened.',
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
            '${sw.name} survived the Dealer\'s attack. Dealers, do you convert or execute?',
        instructionText:
            'CONVERT: joins Dealers next night. EXECUTE: killed immediately.',
        actionType: ScriptActionType.binaryChoice,
        roleId: RoleIds.secondWind,
        options: const ['CONVERT', 'EXECUTE'],
      ));
    }

    steps.addAll([
      ScriptStep(
        id: 'day_start_$dayCount',
        title: 'DAY $dayCount',
        readAloudText: 'The Club is open. Discuss amongst yourselves.',
        instructionText: 'Start the timer.',
        actionType: ScriptActionType.showTimer,
        timerSeconds: timerSeconds,
      ),
      ScriptStep(
        id: 'day_vote_$dayCount',
        title: 'VOTING',
        readAloudText: 'Who do you want to exile from the club?',
        instructionText: 'Select the player to eliminate (if any).',
        actionType: ScriptActionType.selectPlayer,
      ),
    ]);

    return steps;
  }
}

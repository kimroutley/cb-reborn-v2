import 'dart:math';
import 'package:cb_models/cb_models.dart';
import '../scripting/step_key.dart';

class GameBotController {
  static const List<String> _stepPrefixesWithPlayerId = [
    '${RoleIds.dealer}_act_',
    '${RoleIds.silverFox}_act_',
    '${RoleIds.whore}_act_',
    '${RoleIds.sober}_act_',
    '${RoleIds.roofi}_act_',
    '${RoleIds.bouncer}_act_',
    '${RoleIds.medic}_act_',
    '${RoleIds.bartender}_act_',
    '${RoleIds.lightweight}_act_',
    '${RoleIds.messyBitch}_act_',
    '${RoleIds.clubManager}_act_',
    '${RoleIds.attackDog}_act_',
    '${RoleIds.messyBitchKill}_',
    '${RoleIds.medic}_choice_',
    '${RoleIds.creep}_setup_',
    '${RoleIds.clinger}_setup_',
    '${RoleIds.dramaQueen}_setup_',
    '${RoleIds.dramaQueen}_vendetta_',
    '${RoleIds.minor}_id_',
    '${RoleIds.secondWind}_convert_',
    '${RoleIds.teaSpiller}_reveal_',
    '${RoleIds.predator}_retaliation_',
  ];

  static GameState addBot(GameState state) {
    final botNames = [
      'Auto-Pilot',
      'Cyber-Punk',
      'Synth-Wave',
      'Neon-Glitch',
      'Data-Stream',
      'Bit-Crusher',
      'Logic-Gate',
      'Null-Pointer',
    ];

    // Find a unique name
    String name = 'Bot';
    for (final n in botNames) {
      if (!state.players.any((p) => p.name == n)) {
        name = n;
        break;
      }
    }

    if (state.players.any((p) => p.name == name)) {
      name = '$name ${state.players.length + 1}';
    }

    final id =
        'bot_${name.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

    final newPlayer = Player(
      id: id,
      name: name,
      role: Role(
        id: 'unassigned',
        name: 'Unassigned',
        alliance: Team.unknown,
        type: '',
        description: '',
        nightPriority: 0,
        assetPath: '',
        colorHex: '#000000',
      ),
      alliance: Team.unknown,
      isBot: true,
    );
    return state.copyWith(players: [...state.players, newPlayer]);
  }

  static int simulateBotTurns(
    GameState state,
    void Function({required String stepId, String? targetId, String? voterId})
        onInteract,
  ) {
    final step = state.currentStep;
    if (step == null) return 0;

    if (_isDayVoteStep(step.id)) {
      return _simulateDayVotes(state, step.id, onInteract, botsOnly: true);
    }

    // 1. Check if the current step belongs to a specific player
    final actorId = _extractActorId(step.id);
    if (actorId != null) {
      final actor = state.players.firstWhere(
        (p) => p.id == actorId,
        orElse: () => state.players.first,
      );
      if (actor.isBot && !state.actionLog.containsKey(step.id)) {
        return _performRandomStepAction(state, step, onInteract);
      }
    }
    // 2. Fallback: Group action (no actor ID in step, check role)
    else if (step.roleId != null && step.roleId != 'unassigned') {
      final botsWithRole = state.players
          .where((p) => p.role.id == step.roleId && p.isBot)
          .toList();
      if (botsWithRole.isNotEmpty && !state.actionLog.containsKey(step.id)) {
        // If any bot has this role, we assume the bot(s) can act for the group
        return _performRandomStepAction(state, step, onInteract);
      }
    }

    return 0;
  }

  static int _performRandomStepAction(
    GameState state,
    ScriptStep step,
    void Function({required String stepId, String? targetId, String? voterId})
        onInteract,
  ) {
    final rng = Random();
    var actionCount = 0;

    if (step.actionType == ScriptActionType.binaryChoice) {
      if (step.options.isNotEmpty) {
        final choice = _pickSimulatedOption(step, rng);
        onInteract(stepId: step.id, targetId: choice);
        actionCount = 1;
      }
    } else if (step.actionType == ScriptActionType.selectTwoPlayers) {
      final targetPool = _eligibleTargetsForStep(state, step);
      if (targetPool.length >= 2) {
        final first = targetPool[rng.nextInt(targetPool.length)];
        final remaining = targetPool.where((p) => p.id != first.id).toList();
        if (remaining.isNotEmpty) {
          final second = remaining[rng.nextInt(remaining.length)];
          onInteract(
            stepId: step.id,
            targetId: '${first.id},${second.id}',
          );
          actionCount = 1;
        }
      }
    } else if (_isInteractiveAction(step.actionType)) {
      final targetPool = _eligibleTargetsForStep(state, step);
      if (targetPool.isNotEmpty) {
        final target = targetPool[rng.nextInt(targetPool.length)];
        onInteract(stepId: step.id, targetId: target.id);
        actionCount = 1;
      }
    }

    return actionCount;
  }

  static bool _isDayVoteStep(String stepId) => StepKey.isDayVoteStep(stepId);

  static String? _extractActorId(String stepId) {
    for (final prefix in _stepPrefixesWithPlayerId) {
      if (stepId.startsWith(prefix)) {
        return StepKey.extractScopedPlayerId(stepId: stepId, prefix: prefix);
      }
    }
    return null;
  }

  static List<Player> _eligibleTargetsForStep(
      GameState state, ScriptStep step) {
    final actorId = _extractActorId(step.id);
    final actor = actorId == null
        ? null
        : state.players.firstWhere((p) => p.id == actorId,
            orElse: () => state.players.first); // fallback

    List<Player> pool;
    if (step.id.startsWith('medic_act_') && actor?.medicChoice == 'REVIVE') {
      pool = state.players.where((p) => !p.isAlive).toList();
    } else {
      pool = state.players.where((p) => p.isAlive).toList();
    }

    if (actorId != null) {
      pool = pool.where((p) => p.id != actorId).toList();
    }

    return pool;
  }

  static String _pickSimulatedOption(ScriptStep step, Random rng) {
    if (step.options.isEmpty) return '';
    if (step.id.startsWith('medic_choice_') &&
        step.options.contains('PROTECT_DAILY')) {
      return 'PROTECT_DAILY';
    }
    if (step.id.startsWith('second_wind_convert_') &&
        step.options.contains('CONVERT')) {
      return 'CONVERT';
    }
    return step.options[rng.nextInt(step.options.length)];
  }

  static int _simulateDayVotes(
      GameState state,
      String stepId,
      void Function({required String stepId, String? targetId, String? voterId})
          onInteract,
      {bool botsOnly = false}) {
    final rng = Random();
    final alive = state.players.where((p) => p.isAlive).toList();
    if (alive.length < 2) return 0;

    final voters = alive.where((p) {
      if (botsOnly && !p.isBot) return false;
      if (p.silencedDay == state.dayCount) return false;
      if (p.isSinBinned) return false;
      if (state.dayVotesByVoter.containsKey(p.id)) return false;
      return true;
    }).toList();

    if (voters.isEmpty) return 0;

    var cast = 0;
    for (final voter in voters) {
      final targets = alive.where((p) => p.id != voter.id).toList();
      final targetId = targets.isEmpty || rng.nextDouble() < 0.15
          ? 'abstain'
          : targets[rng.nextInt(targets.length)].id;
      onInteract(stepId: stepId, targetId: targetId, voterId: voter.id);
      cast++;
    }

    return cast;
  }

  static bool _isInteractiveAction(ScriptActionType type) {
    return type == ScriptActionType.selectPlayer ||
        type == ScriptActionType.selectTwoPlayers ||
        type == ScriptActionType.binaryChoice ||
        type == ScriptActionType.confirm ||
        type == ScriptActionType.optional ||
        type == ScriptActionType.multiSelect;
  }
}

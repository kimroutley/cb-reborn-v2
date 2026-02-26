import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:cb_models/cb_models.dart';
import 'persistence/persistence_service.dart';
import 'session_provider.dart';
import 'games_night_provider.dart';
import 'gemini_narration_service.dart';
import 'scripting/script_builder.dart';
import 'scripting/step_key.dart';
import 'day_actions/resolution/day_resolution.dart';
import 'game_resolution_logic.dart';

part 'game_provider.g.dart';

@Riverpod(keepAlive: true)
class Game extends _$Game {
  DateTime? _gameStartedAt;
  final Map<String, String> _stepNarrationOverrides = {};
  Timer? _persistDebounceTimer;

  @override
  GameState build() {
    ref.onDispose(() {
      _persistDebounceTimer?.cancel();
    });
    return const GameState();
  }

  // ────────────── Persistence helpers ──────────────

  /// Auto-save current state for crash recovery (debounced).
  void _persist() {
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      try {
        final session = ref.read(sessionProvider);
        PersistenceService.instance.saveActiveGame(state, session);
      } catch (_) {
        // Persistence is best-effort; don't crash the game
      }
    });
  }

  /// Attempt to restore a previously saved game.
  bool tryRestoreGame() {
    try {
      final saved = PersistenceService.instance.loadActiveGame();
      if (saved == null) return false;
      final (gameState, _) = saved;
      state = gameState;
      _gameStartedAt = DateTime.now(); // approximate
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Archive the finished game to history and clear active save.
  Future<void> archiveGame() async {
    if (state.winner == null) return; // game not finished
    try {
      final service = PersistenceService.instance;
      final record = GameRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startedAt: _gameStartedAt ?? DateTime.now(),
        endedAt: DateTime.now(),
        winner: state.winner!,
        playerCount: state.players.length,
        dayCount: state.dayCount,
        rolesInPlay: state.players.map((p) => p.role.id).toSet().toList(),
        roster: state.players
            .map(
              (p) => GameRecordPlayerSnapshot(
                id: p.id,
                name: p.name,
                roleId: p.role.id,
                alliance: p.alliance,
                alive: p.isAlive,
                isBot: p.isBot,
              ),
            )
            .toList(),
        history: state.gameHistory,
        eventLog: state.eventLog,
      );
      await service.saveGameRecord(record);

      // Link to active Games Night session if one exists
      final activeSession = ref.read(gamesNightProvider);
      if (activeSession != null && activeSession.isActive) {
        final playerNames = state.players.map((p) => p.name).toList();
        await service.updateSessionWithGame(
          activeSession.id,
          record.id,
          playerNames,
        );
        ref.read(gamesNightProvider.notifier).refreshSession();
      }

      await service.clearActiveGame();
    } catch (_) {
      // best-effort
    }
  }

  /// Manually save the current game state (triggered by UI).
  bool manualSave({String slotId = defaultSaveSlotId}) {
    try {
      final session = ref.read(sessionProvider);
      PersistenceService.instance.saveGameSlot(slotId, state, session);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Manually load a previously saved game.
  bool manualLoad({String slotId = defaultSaveSlotId}) {
    try {
      final saved = PersistenceService.instance.loadGameSlot(slotId);
      if (saved == null) return false;
      final (gameState, _) = saved;
      state = gameState;
      _gameStartedAt = DateTime.now();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Load a deterministic sandbox game for host feature testing.
  bool loadTestGameSandbox() {
    try {
      final syncMode = state.syncMode;
      final gameStyle = state.gameStyle;
      final timerSeconds = state.discussionTimerSeconds;
      final tieBreaksRandomly = state.tieBreaksRandomly;
      final eyesOpen = state.eyesOpen;

      const roster = <(String, String)>[
        ('Ava Viper', RoleIds.dealer),
        ('Nico Pulse', RoleIds.silverFox),
        ('Mara Halo', RoleIds.medic),
        ('Jax Cipher', RoleIds.bouncer),
        ('Rhea Static', RoleIds.roofi),
        ('Kai Drift', RoleIds.sober),
        ('Luna Glitch', RoleIds.messyBitch),
        ('Ivy Luxe', RoleIds.clubManager),
        ('Zed Echo', RoleIds.clinger),
        ('Nova Flux', RoleIds.secondWind),
      ];

      final players = <Player>[];
      for (final (name, roleId) in roster) {
        final role = roleCatalogMap[roleId];
        if (role == null) continue;
        players.add(
          Player(
            id: _idFromName(name),
            name: name,
            role: role,
            alliance: role.alliance,
          ),
        );
      }

      if (players.length < 4) return false;

      state = GameState(
        players: players,
        phase: GamePhase.setup,
        dayCount: 1,
        scriptQueue: ScriptBuilder.buildSetupScript(players, dayCount: 0),
        scriptIndex: 0,
        actionLog: const {},
        gameHistory: const [
          '[TEST] Sandbox game loaded.',
          '[TEST] Use "SIMULATE PLAYERS" in Game Control for bot input.',
        ],
        syncMode: syncMode,
        gameStyle: gameStyle,
        discussionTimerSeconds: timerSeconds,
        tieBreaksRandomly: tieBreaksRandomly,
        eyesOpen: eyesOpen,
      );

      _gameStartedAt = DateTime.now();
      _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Add a bot player to the game.
  void addBot() {
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
      name = _buildUniqueName('Bot');
    }

    final id = _buildUniquePlayerId(
      'bot_${name.toLowerCase().replaceAll(' ', '_')}',
    );

    final newPlayer = Player(
      id: id,
      name: name,
      role: roleCatalogMap['unassigned'] ?? roleCatalog.first,
      alliance: Team.unknown,
      isBot: true,
    );
    state = state.copyWith(players: [...state.players, newPlayer]);
  }

  /// Simulate inputs for bots in the current step.
  int simulateBotTurns() {
    final step = state.currentStep;
    if (step == null) return 0;

    if (_isDayVoteStep(step.id)) {
      return _simulateDayVotes(stepId: step.id, botsOnly: true);
    }

    // 1. Check if the current step belongs to a specific player
    final actorId = _extractActorId(step.id);
    if (actorId != null) {
      final actor = state.players.firstWhere(
        (p) => p.id == actorId,
        orElse: () => state.players.first,
      );
      if (actor.isBot && !state.actionLog.containsKey(step.id)) {
        return _performRandomStepAction(step);
      }
    }
    // 2. Fallback: Group action (no actor ID in step, check role)
    else if (step.roleId != null && step.roleId != 'unassigned') {
      final botsWithRole = state.players
          .where((p) => p.role.id == step.roleId)
          .toList();
      if (botsWithRole.isNotEmpty && !state.actionLog.containsKey(step.id)) {
        // If any bot has this role, we assume the bot(s) can act for the group
        return _performRandomStepAction(step);
      }
    }

    return 0;
  }

  /// Simulate one batch of player inputs for the current step (Legacy method, kept for manual full simulation).
  int simulatePlayersForCurrentStep() {
    final step = state.currentStep;
    if (step == null) return 0;

    if (_isDayVoteStep(step.id)) {
      return _simulateDayVotes(stepId: step.id);
    }

    return _performRandomStepAction(step);
  }

  int _performRandomStepAction(ScriptStep step) {
    final rng = Random();
    var actionCount = 0;

    if (step.actionType == ScriptActionType.binaryChoice) {
      if (step.options.isNotEmpty) {
        final choice = _pickSimulatedOption(step, rng);
        handleInteraction(stepId: step.id, targetId: choice);
        actionCount = 1;
      }
    } else if (step.actionType == ScriptActionType.selectTwoPlayers) {
      final targetPool = _eligibleTargetsForStep(step);
      if (targetPool.length >= 2) {
        final first = targetPool[rng.nextInt(targetPool.length)];
        final remaining = targetPool.where((p) => p.id != first.id).toList();
        if (remaining.isNotEmpty) {
          final second = remaining[rng.nextInt(remaining.length)];
          handleInteraction(
            stepId: step.id,
            targetId: '${first.id},${second.id}',
          );
          actionCount = 1;
        }
      }
    } else if (_isInteractiveAction(step.actionType)) {
      final targetPool = _eligibleTargetsForStep(step);
      if (targetPool.isNotEmpty) {
        final target = targetPool[rng.nextInt(targetPool.length)];
        handleInteraction(stepId: step.id, targetId: target.id);
        actionCount = 1;
      }
    }

    if (actionCount > 0) {
      _persist();
    }
    return actionCount;
  }

  String _idFromName(String name) => name.toLowerCase().replaceAll(' ', '_');

  bool _isDayVoteStep(String stepId) => StepKey.isDayVoteStep(stepId);

  bool _isCompatibleStepId(String expectedStepId, String incomingStepId) {
    if (expectedStepId == incomingStepId) return true;

    // Backward compatibility: accept legacy unscoped day vote IDs ("day_vote")
    // when the active script step is scoped (e.g. "day_vote_3").
    if (_isDayVoteStep(expectedStepId) && _isDayVoteStep(incomingStepId)) {
      return true;
    }

    return false;
  }

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

  String? _extractActorId(String stepId) {
    for (final prefix in _stepPrefixesWithPlayerId) {
      if (stepId.startsWith(prefix)) {
        return _extractScopedPlayerId(stepId: stepId, prefix: prefix);
      }
    }
    return null;
  }

  String? _extractScopedPlayerId({
    required String stepId,
    required String prefix,
  }) {
    return StepKey.extractScopedPlayerId(stepId: stepId, prefix: prefix);
  }

  Player? _findPlayerById(String id) {
    for (final p in state.players) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<ScriptStep> _buildPredatorRetaliationSteps({
    required List<Player> players,
    required Map<String, String> votesByVoter,
    required int dayCount,
    required String? exiledPlayerId,
  }) {
    if (exiledPlayerId == null || exiledPlayerId.isEmpty) {
      return const [];
    }

    final exiledMatches = players.where((p) => p.id == exiledPlayerId).toList();
    if (exiledMatches.isEmpty) {
      return const [];
    }

    final exiled = exiledMatches.first;
    if (exiled.role.id != RoleIds.predator || exiled.deathReason != 'exile') {
      return const [];
    }

    final eligibleVoterIds = votesByVoter.entries
        .where((entry) => entry.value == exiled.id)
        .map((entry) => entry.key)
        .where((voterId) => voterId != exiled.id)
        .where((voterId) => players.any((p) => p.id == voterId && p.isAlive))
        .toList();

    if (eligibleVoterIds.isEmpty) {
      return const [];
    }

    return [
      ScriptStep(
        id: 'predator_retaliation_${exiled.id}_$dayCount',
        title: 'PREDATOR RETALIATION',
        readAloudText:
            '${exiled.name}, choose one voter to take down with you.',
        instructionText:
            'Select one player who voted against ${exiled.name}. That player dies immediately.',
        actionType: ScriptActionType.selectPlayer,
        roleId: RoleIds.predator,
      ),
    ];
  }

  List<ScriptStep> _buildTeaSpillerRevealSteps({
    required List<Player> players,
    required Map<String, String> votesByVoter,
    required int dayCount,
    required String? exiledPlayerId,
  }) {
    if (exiledPlayerId == null || exiledPlayerId.isEmpty) {
      return const [];
    }

    final exiledMatches = players.where((p) => p.id == exiledPlayerId).toList();
    if (exiledMatches.isEmpty) {
      return const [];
    }

    final exiled = exiledMatches.first;
    if (exiled.role.id != RoleIds.teaSpiller || exiled.deathReason != 'exile') {
      return const [];
    }

    final eligibleVoterIds = votesByVoter.entries
        .where((entry) => entry.value == exiled.id)
        .map((entry) => entry.key)
        .where((voterId) => voterId != exiled.id)
        .where((voterId) => players.any((p) => p.id == voterId))
        .toList();

    if (eligibleVoterIds.isEmpty) {
      return const [];
    }

    return [
      ScriptStep(
        id: 'tea_spiller_reveal_${exiled.id}_$dayCount',
        title: 'TEA SPILLER REVEAL',
        readAloudText:
            '${exiled.name}, choose one voter to expose before you leave.',
        instructionText:
            'Select one player who voted against ${exiled.name}. Their role will be revealed publicly.',
        actionType: ScriptActionType.selectPlayer,
        roleId: RoleIds.teaSpiller,
      ),
    ];
  }

  List<ScriptStep> _buildDramaQueenVendettaSteps({
    required List<Player> players,
    required int dayCount,
    required String? exiledPlayerId,
  }) {
    if (exiledPlayerId == null || exiledPlayerId.isEmpty) {
      return const [];
    }

    final exiledMatches = players.where((p) => p.id == exiledPlayerId).toList();
    if (exiledMatches.isEmpty) {
      return const [];
    }

    final exiled = exiledMatches.first;
    if (exiled.role.id != RoleIds.dramaQueen || exiled.deathReason != 'exile') {
      return const [];
    }

    final eligibleTargets = players
        .where((p) => p.isAlive && p.id != exiled.id)
        .map((p) => p.id)
        .toList();

    if (eligibleTargets.length < 2) {
      return const [];
    }

    return [
      ScriptStep(
        id: 'drama_queen_vendetta_${exiled.id}_$dayCount',
        title: 'DRAMA QUEEN VENDETTA',
        readAloudText: '${exiled.name}, choose two players to swap roles.',
        instructionText:
            'Select two alive players. Their roles and alliances will be swapped immediately.',
        actionType: ScriptActionType.selectTwoPlayers,
        roleId: RoleIds.dramaQueen,
      ),
    ];
  }

  Map<String, String> _predatorRetaliationChoicesFromActionLog(int dayCount) {
    final result = <String, String>{};

    for (final entry in state.actionLog.entries) {
      final stepId = entry.key;
      if (!stepId.startsWith('predator_retaliation_') ||
          !stepId.endsWith('_$dayCount')) {
        continue;
      }

      final predatorId = _extractScopedPlayerId(
        stepId: stepId,
        prefix: 'predator_retaliation_',
      );
      if (predatorId == null || predatorId.isEmpty) {
        continue;
      }

      if (entry.value.isEmpty) {
        continue;
      }
      result[predatorId] = entry.value;
    }

    return result;
  }

  Map<String, String> _teaSpillerRevealChoicesFromActionLog(int dayCount) {
    final result = <String, String>{};

    for (final entry in state.actionLog.entries) {
      final stepId = entry.key;
      if (!stepId.startsWith('tea_spiller_reveal_') ||
          !stepId.endsWith('_$dayCount')) {
        continue;
      }

      final teaSpillerId = _extractScopedPlayerId(
        stepId: stepId,
        prefix: 'tea_spiller_reveal_',
      );
      if (teaSpillerId == null || teaSpillerId.isEmpty) {
        continue;
      }

      if (entry.value.isEmpty) {
        continue;
      }
      result[teaSpillerId] = entry.value;
    }

    return result;
  }

  Map<String, String> _dramaQueenSwapChoicesFromActionLog(int dayCount) {
    final result = <String, String>{};

    for (final entry in state.actionLog.entries) {
      final stepId = entry.key;
      if (!stepId.startsWith('drama_queen_vendetta_') ||
          !stepId.endsWith('_$dayCount')) {
        continue;
      }

      final dramaQueenId = _extractScopedPlayerId(
        stepId: stepId,
        prefix: 'drama_queen_vendetta_',
      );
      if (dramaQueenId == null || dramaQueenId.isEmpty) {
        continue;
      }

      if (entry.value.isEmpty) {
        continue;
      }
      result[dramaQueenId] = entry.value;
    }

    return result;
  }

  String? _findLatestDealerTargetIdForDay(int dayCount) {
    final daySuffix = '_$dayCount';
    final dealerActions = state.actionLog.entries
        .where(
          (entry) =>
              entry.key.startsWith('dealer_act_') &&
              entry.key.endsWith(daySuffix) &&
              entry.value.isNotEmpty,
        )
        .toList();

    if (dealerActions.isEmpty) {
      return null;
    }

    return dealerActions.last.value;
  }

  List<Player> _eligibleTargetsForStep(ScriptStep step) {
    final actorId = _extractActorId(step.id);
    final actor = actorId == null ? null : _findPlayerById(actorId);

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

  String _pickSimulatedOption(ScriptStep step, Random rng) {
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

  int _simulateDayVotes({required String stepId, bool botsOnly = false}) {
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
      handleInteraction(stepId: stepId, targetId: targetId, voterId: voter.id);
      cast++;
    }

    _persist();
    return cast;
  }

  /// Export the game log as a formatted string.
  String exportGameLog() {
    final buffer = StringBuffer();
    buffer.writeln('=== CLUB BLACKOUT GAME LOG ===');
    buffer.writeln('Date: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Day: ${state.dayCount}');
    buffer.writeln('Phase: ${state.phase.name}');
    buffer.writeln('Players: ${state.players.length}');
    buffer.writeln('');
    buffer.writeln('=== ROSTER ===');
    for (final player in state.players) {
      buffer.writeln(
        '${player.name} - ${player.role.name} (${player.alliance.name}) - ${player.isAlive ? "Alive" : "Dead"}',
      );
    }
    buffer.writeln('');
    buffer.writeln('=== GAME HISTORY ===');
    for (final event in state.gameHistory) {
      buffer.writeln(event);
    }
    if (state.winner != null) {
      buffer.writeln('');
      buffer.writeln('=== WINNER ===');
      buffer.writeln(state.winner.toString());
    }
    return buffer.toString();
  }

  /// Generate an AI-ready recap prompt for Gemini
  String generateAIRecapPrompt(String style) {
    final buffer = StringBuffer();

    switch (style.toLowerCase()) {
      case 'r-rated':
        buffer.writeln('[R-RATED RECAP REQUEST]');
        buffer.writeln(
          'You are recapping a social deduction game called Club Blackout set in a nightclub.',
        );
        buffer.writeln(
          'Be ironic, dramatic, and roast the players mercilessly.',
        );
        buffer.writeln(
          'Use self-deprecating humor about the host and snarky commentary about player mistakes.',
        );
        break;
      case 'spicy':
        buffer.writeln('[SPICY CLUB-THEMED RECAP REQUEST]');
        buffer.writeln(
          'You are recapping a social deduction game called Club Blackout.',
        );
        buffer.writeln(
          'Use club culture innuendo, bouncer jokes, and VIP lounge drama.',
        );
        break;
      case 'pg':
        buffer.writeln('[PG MYSTERY RECAP REQUEST]');
        buffer.writeln(
          'You are recapping a social deduction game called Club Blackout.',
        );
        buffer.writeln(
          'Tell it like a dramatic mystery story suitable for all ages.',
        );
        break;
    }

    buffer.writeln('\n=== GAME LOG ===');
    for (final event in state.gameHistory) {
      buffer.writeln(event);
    }

    buffer.writeln('\n=== TASK ===');
    buffer.writeln(
      'Create a 200-300 word dramatic recap of this game. Make it memorable!',
    );

    return buffer.toString();
  }

  /// Generate dynamic read-aloud narration from the last resolved night report
  /// using Gemini.
  Future<String?> generateDynamicNightNarration({
    String? personalityId,
    String? voice,
    String? variationPrompt,
  }) async {
    if (state.lastNightReport.isEmpty) {
      return null;
    }

    var effectiveVoice = voice ?? 'nightclub_noir';
    var effectivePrompt = variationPrompt;

    if (personalityId != null) {
      final p = hostPersonalities.firstWhere(
        (element) => element.id == personalityId,
        orElse: () => hostPersonalities.first,
      );
      effectiveVoice = p.voice;
      effectivePrompt = [
        effectivePrompt,
        p.variationPrompt,
      ].whereType<String>().join(' ');
    }

    final gemini = ref.read(geminiNarrationServiceProvider);
    return gemini.generateNightNarration(
      lastNightReport: state.lastNightReport,
      dayCount: state.dayCount,
      aliveCount: state.players.where((p) => p.isAlive).length,
      voice: effectiveVoice,
      variationPrompt: effectivePrompt,
    );
  }

  Future<String?> _generateCurrentStepNarrationVariation({
    String? personalityId,
  }) async {
    final step = state.currentStep;
    if (step == null || step.readAloudText.trim().isEmpty) {
      return null;
    }

    var effectiveVoice = step.aiVariationVoice ?? 'nightclub_noir';
    var effectivePrompt = step.aiVariationPrompt;

    if (personalityId != null) {
      final p = hostPersonalities.firstWhere(
        (element) => element.id == personalityId,
        orElse: () => hostPersonalities.first,
      );
      effectiveVoice = p.voice;
      effectivePrompt = [
        effectivePrompt,
        p.variationPrompt,
      ].whereType<String>().join(' ');
    }

    final gemini = ref.read(geminiNarrationServiceProvider);
    final variation = await gemini.generateStepNarrationVariation(
      baseReadAloudText: step.readAloudText,
      stepTitle: step.title,
      voice: effectiveVoice,
      variationPrompt: effectivePrompt,
    );

    if (variation.trim().isEmpty) {
      return null;
    }
    return variation;
  }

  /// Prepare a one-time narration override for the current step.
  /// The next [emitStepToFeed] call will use this text instead of
  /// `step.readAloudText`.
  Future<bool> prepareCurrentStepNarrationOverrideWithAi({
    String? personalityId,
  }) async {
    final step = state.currentStep;
    if (step == null || step.readAloudText.trim().isEmpty) {
      return false;
    }

    try {
      final variation = await _generateCurrentStepNarrationVariation(
        personalityId: personalityId,
      );
      if (variation == null) {
        return false;
      }
      _stepNarrationOverrides[step.id] = variation;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Generate and append an AI narration variation for the current step.
  Future<bool> emitCurrentStepNarrationVariationToFeed({
    String? personalityId,
  }) async {
    final step = state.currentStep;
    if (step == null || step.readAloudText.trim().isEmpty) {
      return false;
    }

    try {
      final variation = await _generateCurrentStepNarrationVariation(
        personalityId: personalityId,
      );
      if (variation == null) {
        return false;
      }

      final now = DateTime.now();
      _appendFeed(
        FeedEvent(
          id: '${now.millisecondsSinceEpoch}_ai_var',
          type: FeedEventType.narrative,
          title: '${step.title} • AI VARIATION',
          content: variation,
          roleId: step.roleId,
          timestamp: now,
          stepId: step.id,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- INTERACTION ---

  void _appendFeed(FeedEvent event) {
    state = state.copyWith(feedEvents: [...state.feedEvents, event]);
  }

  void emitStepToFeed() {
    final step = state.currentStep;
    if (step == null) return;
    final narrationOverride = _stepNarrationOverrides.remove(step.id);
    final narrationText = narrationOverride ?? step.readAloudText;

    final now = DateTime.now();
    final baseId = '${now.millisecondsSinceEpoch}';

    if (narrationText.isNotEmpty) {
      _appendFeed(
        FeedEvent(
          id: '${baseId}_narr',
          type: FeedEventType.narrative,
          title: narrationOverride == null
              ? step.title
              : '${step.title} • AI VARIATION',
          content: narrationText,
          roleId: step.roleId,
          timestamp: now,
          stepId: step.id,
        ),
      );
    }

    if (step.instructionText.isNotEmpty) {
      _appendFeed(
        FeedEvent(
          id: '${baseId}_dir',
          type: FeedEventType.directive,
          title: 'HOST NOTES',
          content: step.instructionText,
          roleId: step.roleId,
          timestamp: now,
          stepId: step.id,
        ),
      );
    }

    if (_isInteractiveAction(step.actionType)) {
      _appendFeed(
        FeedEvent(
          id: '${baseId}_act',
          type: FeedEventType.action,
          title: step.title,
          content: _actionPrompt(step),
          roleId: step.roleId,
          timestamp: now,
          actionType: step.actionType,
          options: step.options,
          stepId: step.id,
          timerSeconds: step.timerSeconds,
        ),
      );
    }
  }

  void emitResultToFeed(String resultText, {String? roleId}) {
    _resolveLastAction(resultText);
    _appendFeed(
      FeedEvent(
        id: '${DateTime.now().millisecondsSinceEpoch}_res',
        type: FeedEventType.result,
        title: 'RESULT',
        content: resultText,
        roleId: roleId,
        timestamp: DateTime.now(),
      ),
    );
  }

  void emitSystemToFeed(String text) {
    _appendFeed(
      FeedEvent(
        id: '${DateTime.now().millisecondsSinceEpoch}_sys',
        type: FeedEventType.system,
        title: '',
        content: text,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Triggers a visual/sync effect on all player devices.
  void sendDirectorCommand(String command) {
    // 1. Show in Host Feed
    emitSystemToFeed('STIM: $command');

    // 2. Send to Players via Bulletin Board (as a hidden system msg)
    dispatchBulletin(title: 'SYSTEM', content: 'STIM:$command', type: 'system');

    // 3. Log it
    state = state.copyWith(
      gameHistory: [...state.gameHistory, '[DIRECTOR] Triggered $command'],
    );
  }

  void _resolveLastAction(String resolution) {
    final events = List<FeedEvent>.from(state.feedEvents);
    for (int i = events.length - 1; i >= 0; i--) {
      if (events[i].type == FeedEventType.action && !events[i].resolved) {
        events[i] = events[i].copyWith(resolved: true, resolution: resolution);
        break;
      }
    }
    state = state.copyWith(feedEvents: events);
  }

  bool _isInteractiveAction(ScriptActionType type) {
    return type == ScriptActionType.selectPlayer ||
        type == ScriptActionType.selectTwoPlayers ||
        type == ScriptActionType.binaryChoice ||
        type == ScriptActionType.confirm ||
        type == ScriptActionType.optional ||
        type == ScriptActionType.multiSelect;
  }

  String _actionPrompt(ScriptStep step) {
    return step.instructionText.isNotEmpty
        ? step.instructionText
        : 'Select an option.';
  }

  void handleInteraction({
    required String stepId,
    String? targetId,
    String? voterId,
    String? actorId,
  }) {
    // Safety check: Ensure the interaction matches the current step in the queue.
    // We only enforce this if a queue exists (standard game flow).
    final currentQueue = state.scriptQueue;
    final currentIndex = state.scriptIndex;
    if (!_isDayVoteStep(stepId) &&
        currentQueue.isNotEmpty &&
        currentIndex >= 0 &&
        currentIndex < currentQueue.length) {
      final step = currentQueue[currentIndex];
      if (!_isCompatibleStepId(step.id, stepId)) {
        // Stale event, ignore.
        return;
      }
    }

    // If targetId is null, it's a deselection.
    if (targetId == null || targetId.isEmpty) {
      final updatedLog = Map<String, String>.from(state.actionLog);
      if (updatedLog.containsKey(stepId)) {
        updatedLog.remove(stepId);
        state = state.copyWith(actionLog: updatedLog);
      }
      return;
    }

    if (_isDayVoteStep(stepId)) {
      if (voterId == null) return;

      final voterMatches = state.players.where((p) => p.id == voterId);
      if (voterMatches.isNotEmpty) {
        final voter = voterMatches.first;
        if (voter.silencedDay == state.dayCount || voter.isSinBinned) {
          return;
        }

        // Clinger must support their partner's current vote while partner is alive.
        if (voter.role.id == RoleIds.clinger &&
            voter.clingerPartnerId != null &&
            voter.clingerPartnerId!.isNotEmpty) {
          final partnerMatches = state.players.where(
            (p) => p.id == voter.clingerPartnerId,
          );
          if (partnerMatches.isNotEmpty) {
            final partner = partnerMatches.first;
            if (partner.isAlive) {
              final partnerVote = state.dayVotesByVoter[partner.id];
              if (partnerVote == null || partnerVote != targetId) {
                return;
              }
            }
          }
        }
      }

      final updatedTally = Map<String, int>.from(state.dayVoteTally);
      final updatedVotes = Map<String, String>.from(state.dayVotesByVoter);
      final previousVote = updatedVotes[voterId];

      if (previousVote == targetId) return;
      if (previousVote != null) {
        updatedTally[previousVote] = (updatedTally[previousVote] ?? 1) - 1;
        if (updatedTally[previousVote]! <= 0) updatedTally.remove(previousVote);
      }

      updatedTally[targetId] = (updatedTally[targetId] ?? 0) + 1;
      updatedVotes[voterId] = targetId;
      state = state.copyWith(
        dayVoteTally: updatedTally,
        dayVotesByVoter: updatedVotes,
        eventLog: [
          ...state.eventLog,
          GameEvent.vote(
            voterId: voterId,
            targetId: targetId,
            day: state.dayCount,
          ),
        ],
      );
      return;
    }

    // Special case: Second Wind conversion
    if (stepId.startsWith('second_wind_convert_')) {
      final playerId = _extractScopedPlayerId(
        stepId: stepId,
        prefix: 'second_wind_convert_',
      );
      if (playerId == null) return;
      if (targetId == 'CONVERT') {
        _applySecondWindConversion(playerId);
      } else if (targetId == 'EXECUTE') {
        forceKillPlayer(playerId, reason: 'second_wind_executed');
      }
      return;
    }

    // Special case: Medic choice
    if (stepId.startsWith('medic_choice_')) {
      final medicId = _extractScopedPlayerId(
        stepId: stepId,
        prefix: 'medic_choice_',
      );
      if (medicId == null) return;
      state = state.copyWith(
        players: state.players.map((p) {
          if (p.id == medicId) {
            return p.copyWith(
              medicChoice: targetId,
              hasReviveToken: targetId == 'REVIVE',
            );
          }
          return p;
        }).toList(),
      );
    }

    // Special case: Creep setup
    if (stepId.startsWith('creep_setup_')) {
      final creepId = _extractScopedPlayerId(
        stepId: stepId,
        prefix: 'creep_setup_',
      );
      if (creepId == null) return;
      final target = state.players.firstWhere((p) => p.id == targetId);
      state = state.copyWith(
        players: state.players.map((p) {
          if (p.id == creepId) {
            return p.copyWith(
              creepTargetId: targetId,
              alliance: target.alliance,
            );
          }
          return p;
        }).toList(),
      );
    }

    // Special case: Clinger setup
    if (stepId.startsWith('clinger_setup_')) {
      final clingerId = _extractScopedPlayerId(
        stepId: stepId,
        prefix: 'clinger_setup_',
      );
      if (clingerId == null) return;
      state = state.copyWith(
        players: state.players.map((p) {
          if (p.id == clingerId) {
            return p.copyWith(clingerPartnerId: targetId);
          }
          return p;
        }).toList(),
      );
    }

    // Special case: Drama Queen setup (select two players, comma-separated IDs)
    if (stepId.startsWith('drama_queen_setup_')) {
      final dramaQueenId = _extractScopedPlayerId(
        stepId: stepId,
        prefix: 'drama_queen_setup_',
      );
      if (dramaQueenId == null) return;

      final targetIds = targetId
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();

      if (targetIds.length < 2) return;
      final targetAId = targetIds[0];
      final targetBId = targetIds[1];

      if (targetAId == targetBId) return;
      if (targetAId == dramaQueenId || targetBId == dramaQueenId) return;

      final alivePlayerIds = state.players
          .where((p) => p.isAlive)
          .map((p) => p.id)
          .toSet();
      if (!alivePlayerIds.contains(targetAId) ||
          !alivePlayerIds.contains(targetBId)) {
        return;
      }

      state = state.copyWith(
        players: state.players.map((p) {
          if (p.id == dramaQueenId) {
            return p.copyWith(
              dramaQueenTargetAId: targetAId,
              dramaQueenTargetBId: targetBId,
            );
          }
          return p;
        }).toList(),
      );
    }

    // Special case: Wallflower observation by Host
    if (stepId.startsWith('wallflower_observe_')) {
      final wallflowerId = _extractScopedPlayerId(
        stepId: stepId,
        prefix: 'wallflower_observe_',
      );
      if (wallflowerId == null) return;
      if (targetId == 'PEEKED') {
        state = state.copyWith(gawkedPlayerId: null);
        final dealerTargetId = _findLatestDealerTargetIdForDay(state.dayCount);
        if (dealerTargetId != null) {
          final target = _findPlayerById(dealerTargetId);
          if (target != null) {
            final updatedPrivates = <String, List<String>>{
              ...state.privateMessages,
            };
            final existing = updatedPrivates[wallflowerId] ?? const <String>[];
            final intelLine =
                'You discreetly witnessed Dealer target ${target.name}.';
            final shouldAppend = existing.isEmpty || existing.last != intelLine;
            updatedPrivates[wallflowerId] = shouldAppend
                ? [...existing, intelLine]
                : existing;
            state = state.copyWith(privateMessages: updatedPrivates);
          }
        }
      } else if (targetId == 'GAWKED') {
        state = state.copyWith(
          gawkedPlayerId: wallflowerId,
          players: state.players.map((p) {
            if (p.id == wallflowerId) {
              return p.copyWith(isExposed: true);
            }
            return p;
          }).toList(),
        );
      }
      // "PEEKED" requires no state change
    }

    // Special case: Whore act
    if (stepId.startsWith('whore_act_')) {
      final whoreId = _extractScopedPlayerId(
        stepId: stepId,
        prefix: 'whore_act_',
      );
      if (whoreId == null) return;
      if (targetId == whoreId) return;
      state = state.copyWith(
        players: state.players.map((p) {
          if (p.id == whoreId) {
            return p.copyWith(whoreDeflectionTargetId: targetId);
          }
          return p;
        }).toList(),
      );
    }

    // Special case: Minor ID
    if (stepId.startsWith('minor_id_')) {
      final minorId = _extractScopedPlayerId(
        stepId: stepId,
        prefix: 'minor_id_',
      );
      if (minorId == null) return;
      state = state.copyWith(
        players: state.players.map((p) {
          if (p.id == minorId) {
            return p.copyWith(minorHasBeenIDd: targetId == 'true');
          }
          return p;
        }).toList(),
      );
    }

    final updatedLog = Map<String, String>.from(state.actionLog)
      ..[stepId] = targetId;
    state = state.copyWith(actionLog: updatedLog);

    final resolvedActorId = actorId ?? _extractActorId(stepId);
    if (resolvedActorId != null) {
      _resolveAndReportAction(
        stepId: stepId,
        actorId: resolvedActorId,
        targetId: targetId,
      );
    }
  }

  void _resolveAndReportAction({
    required String stepId,
    required String actorId,
    required String targetId,
  }) {
    final actor = _findPlayerById(actorId);
    final target = _findPlayerById(targetId);
    if (actor == null || target == null) return;

    final resultText = GameResolutionLogic.getImmediateActionText(
      actor,
      target,
      state,
    );

    if (resultText.isNotEmpty) {
      emitResultToFeed(resultText, roleId: actor.role.id);
    }
  }

  void placeDeadPoolBet({
    required String playerId,
    required String targetPlayerId,
  }) {
    final bettor = state.players.firstWhere(
      (p) => p.id == playerId,
      orElse: () => Player(
        id: '',
        name: '',
        role: roleCatalog.first,
        alliance: Team.unknown,
      ),
    );
    final target = state.players.firstWhere(
      (p) => p.id == targetPlayerId,
      orElse: () => Player(
        id: '',
        name: '',
        role: roleCatalog.first,
        alliance: Team.unknown,
      ),
    );

    if (bettor.id.isEmpty || target.id.isEmpty) {
      return;
    }

    // Ghost-only mechanic: only eliminated players can place Dead Pool bets.
    if (bettor.isAlive) {
      return;
    }

    // Cannot bet on dead players.
    if (!target.isAlive) {
      return;
    }

    final updatedBets = Map<String, String>.from(state.deadPoolBets)
      ..[playerId] = targetPlayerId;

    state = state.copyWith(
      deadPoolBets: updatedBets,
      players: state.players.map((p) {
        if (p.id == playerId) {
          return p.copyWith(currentBetTargetId: targetPlayerId);
        }
        return p;
      }).toList(),
      gameHistory: [
        ...state.gameHistory,
        '[DEAD POOL] ${bettor.name} bet on ${target.name}',
      ],
    );
    _persist();
  }

  void addGhostChatMessage({
    required String senderPlayerId,
    String? senderPlayerName,
    required String message,
  }) {
    final senderMatches = state.players.where((p) => p.id == senderPlayerId);
    if (senderMatches.isEmpty) {
      return;
    }
    final sender = senderMatches.first;
    if (sender.isAlive) {
      return;
    }

    final senderName = (senderPlayerName == null || senderPlayerName.isEmpty)
        ? sender.name
        : senderPlayerName;
    final line = '[GHOST] $senderName: $message';

    final updatedPrivates = <String, List<String>>{...state.privateMessages};
    for (final player in state.players.where((p) => !p.isAlive)) {
      final existing = updatedPrivates[player.id] ?? const <String>[];
      updatedPrivates[player.id] = [...existing, line];
    }

    state = state.copyWith(
      privateMessages: updatedPrivates,
      gameHistory: [...state.gameHistory, line],
    );
    _persist();
  }

  void _applySecondWindConversion(String playerId) {
    state = state.copyWith(
      players: state.players.map((p) {
        if (p.id == playerId) {
          return p.copyWith(
            alliance: Team.clubStaff,
            secondWindConverted: true,
            secondWindPendingConversion: false,
            joinsNextNight: true,
          );
        }
        return p;
      }).toList(),
      gameHistory: [
        ...state.gameHistory,
        'Second Wind ${state.players.firstWhere((p) => p.id == playerId).name} was converted to Staff.',
      ],
    );
  }

  void dispatchBulletin({
    required String title,
    required String content,
    String type = 'info',
    String? roleId,
  }) {
    final entry = BulletinEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      roleId: roleId,
    );
    state = state.copyWith(
      bulletinBoard: [...state.bulletinBoard, entry],
      gameHistory: [...state.gameHistory, 'BULLETIN: $title - $content'],
    );
  }

  void toggleEyes(bool open) {
    state = state.copyWith(eyesOpen: open);
    state = state.copyWith(
      gameHistory: [
        ...state.gameHistory,
        'DIRECTOR: EYES ${open ? "OPEN" : "CLOSED"} COMMAND',
      ],
    );
  }

  // --- SETTINGS ---

  void setSyncMode(SyncMode mode) {
    state = state.copyWith(syncMode: mode);
    _persist();
  }

  void setGameStyle(GameStyle style) {
    state = state.copyWith(gameStyle: style);
    _persist();
  }

  /// Reset the game back to lobby state while preserving settings.
  void returnToLobby() {
    state = GameState(
      syncMode: state.syncMode,
      gameStyle: state.gameStyle,
      discussionTimerSeconds: state.discussionTimerSeconds,
    );
    _gameStartedAt = null;
    _persist();
  }

  /// Grant a host shield to a player for a given number of days.
  void grantHostShield(String playerId, int days) {
    state = state.copyWith(
      players: state.players
          .map(
            (p) => p.id == playerId
                ? p.copyWith(
                    hasHostShield: true,
                    hostShieldExpiresDay: state.dayCount + days,
                  )
                : p,
          )
          .toList(),
      gameHistory: [
        ...state.gameHistory,
        '[HOST] Granted $days-day shield to ${state.players.firstWhere((p) => p.id == playerId).name}',
      ],
    );
    _persist();
  }

  // --- LOBBY ACTIONS ---

  static final _whitespaceRegex = RegExp(r'\s+');

  String _normalizeName(String value) {
    return value.trim().toLowerCase().replaceAll(_whitespaceRegex, ' ');
  }

  String _buildUniqueName(String desired, {String? excludePlayerId}) {
    final base = desired.trim();
    if (base.isEmpty) {
      return desired;
    }

    final existing = state.players
        .where((p) => p.id != excludePlayerId)
        .map((p) => _normalizeName(p.name))
        .toSet();

    var candidate = base;
    var suffix = 2;
    while (existing.contains(_normalizeName(candidate))) {
      candidate = '$base ($suffix)';
      suffix++;
    }
    return candidate;
  }

  String _buildUniquePlayerId(String baseId) {
    final existingIds = state.players.map((p) => p.id).toSet();
    var candidate = baseId;
    var suffix = 2;
    while (existingIds.contains(candidate)) {
      candidate = '${baseId}_$suffix';
      suffix++;
    }
    return candidate;
  }

  void addPlayer(String name, {String? authUid}) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    if (authUid != null && authUid.isNotEmpty) {
      final existingByUid = state.players.where((p) => p.authUid == authUid);
      if (existingByUid.isNotEmpty) {
        final existing = existingByUid.first;
        final nextName = _buildUniqueName(
          trimmedName,
          excludePlayerId: existing.id,
        );
        state = state.copyWith(
          players: state.players
              .map(
                (p) => p.id == existing.id
                    ? p.copyWith(name: nextName, authUid: authUid)
                    : p,
              )
              .toList(),
        );
        return;
      }
    }

    if (state.players.length >= maxPlayers) {
      return;
    }

    final canonicalName = _buildUniqueName(trimmedName);
    final seedId = (authUid != null && authUid.isNotEmpty)
        ? authUid.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        : canonicalName.toLowerCase().replaceAll(' ', '_');
    final id = _buildUniquePlayerId(seedId);

    final newPlayer = Player(
      id: id,
      name: canonicalName,
      authUid: authUid,
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
    );
    state = state.copyWith(players: [...state.players, newPlayer]);
  }

  void removePlayer(String id) {
    state = state.copyWith(
      players: state.players.where((p) => p.id != id).toList(),
    );
  }

  void updatePlayerName(String id, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final updatedName = _buildUniqueName(trimmed, excludePlayerId: id);
    state = state.copyWith(
      players: state.players
          .map((p) => p.id == id ? p.copyWith(name: updatedName) : p)
          .toList(),
    );
  }

  void mergePlayers({required String sourceId, required String targetId}) {
    if (sourceId == targetId) {
      return;
    }

    final source = state.players.where((p) => p.id == sourceId).toList();
    final target = state.players.where((p) => p.id == targetId).toList();
    if (source.isEmpty || target.isEmpty) {
      return;
    }

    final src = source.first;
    final tgt = target.first;
    final mergedTarget = tgt.copyWith(
      authUid: tgt.authUid ?? src.authUid,
      name: _buildUniqueName(tgt.name, excludePlayerId: targetId),
    );

    state = state.copyWith(
      players: state.players
          .where((p) => p.id != sourceId)
          .map((p) => p.id == targetId ? mergedTarget : p)
          .toList(),
      gameHistory: [
        ...state.gameHistory,
        '[HOST] Merged ${src.name} into ${mergedTarget.name}',
      ],
    );
  }

  void assignRole(String playerId, String roleId) {
    final role = roleCatalogMap[roleId] ?? roleCatalog.first;
    state = state.copyWith(
      players: state.players
          .map(
            (p) => p.id == playerId
                ? p.copyWith(
                    role: role,
                    alliance: role.alliance,
                    lives: role.id == RoleIds.allyCat ? 9 : p.lives,
                  )
                : p,
          )
          .toList(),
    );
  }

  // --- GOD MODE ACTIONS ---

  void forceKillPlayer(String id, {String reason = 'host_kick'}) {
    final p = state.players.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Player not found'),
    );
    if (!p.isAlive) return;

    var updatedPlayers = state.players
        .map(
          (p) => p.id == id
              ? p.copyWith(
                  isAlive: false,
                  deathReason: reason,
                  deathDay: state.dayCount,
                )
              : p,
        )
        .toList();

    state = state.copyWith(
      players: updatedPlayers,
      gameHistory: [...state.gameHistory, '${p.name} was removed by the host.'],
      eventLog: [
        ...state.eventLog,
        GameEvent.death(playerId: id, reason: reason, day: state.dayCount),
      ],
    );

    _handleDeathTriggers(id);
    _checkAndResolveWinCondition(state.players);
    _persist();
  }

  void _handleDeathTriggers(String deadPlayerId) {
    final deadPlayer = state.players.firstWhere((p) => p.id == deadPlayerId);
    var updatedPlayers = List<Player>.from(state.players);
    final history = <String>[];
    final events = <GameEvent>[];

    // 1. Clinger Trigger: If partner dies, Clinger dies.
    for (final p in updatedPlayers.where(
      (p) => p.isAlive && p.role.id == RoleIds.clinger,
    )) {
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
    for (final p in updatedPlayers.where(
      (p) => p.isAlive && p.role.id == RoleIds.creep,
    )) {
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
      state = state.copyWith(
        players: updatedPlayers,
        gameHistory: [...state.gameHistory, ...history],
        eventLog: [...state.eventLog, ...events],
      );
      // Recursively handle triggers for newly dead players
      for (final h in history) {
        if (h.contains('died')) {
          // This is a simplified check, ideally we'd track who died in this pass
        }
      }
    }
  }

  void revivePlayer(String id) {
    final p = state.players.firstWhere((p) => p.id == id);
    if (p.isAlive) return;
    state = state.copyWith(
      players: state.players
          .map(
            (p) => p.id == id
                ? p.copyWith(isAlive: true, deathReason: null, deathDay: null)
                : p,
          )
          .toList(),
      gameHistory: [...state.gameHistory, '[HOST] Revived ${p.name}'],
    );
    _persist();
  }

  void togglePlayerMute(String id, bool muted) {
    state = state.copyWith(
      players: state.players
          .map((p) => p.id == id ? p.copyWith(isMuted: muted) : p)
          .toList(),
      gameHistory: [
        ...state.gameHistory,
        '[HOST] ${muted ? "Muted" : "Unmuted"} ${state.players.firstWhere((p) => p.id == id).name}',
      ],
    );
    _persist();
  }

  void setSinBin(String id, bool binned) {
    state = state.copyWith(
      players: state.players
          .map((p) => p.id == id ? p.copyWith(isSinBinned: binned) : p)
          .toList(),
      gameHistory: [
        ...state.gameHistory,
        '[HOST] ${binned ? "Sin binned" : "Released"} ${state.players.firstWhere((p) => p.id == id).name}',
      ],
    );
    _persist();
  }

  void setShadowBan(String id, bool banned) {
    state = state.copyWith(
      players: state.players
          .map((p) => p.id == id ? p.copyWith(isShadowBanned: banned) : p)
          .toList(),
      gameHistory: [
        ...state.gameHistory,
        '[HOST] ${banned ? "Shadow banned" : "Unbanned"} ${state.players.firstWhere((p) => p.id == id).name}',
      ],
    );
    _persist();
  }

  void kickPlayer(String id, String reason) {
    forceKillPlayer(id);
    state = state.copyWith(
      gameHistory: [
        ...state.gameHistory,
        '[HOST] Kicked player - Reason: $reason',
      ],
    );
    _persist();
  }

  // --- GAME FLOW ---

  static const int minPlayers = 4;
  static const int maxPlayers = 25;

  bool startGame() {
    if (state.players.length < minPlayers) return false;
    if (state.phase != GamePhase.lobby) return false;

    if (state.gameStyle == GameStyle.manual) {
      final allAssigned = state.players.every(
        (p) => p.role.id != 'unassigned' && p.alliance != Team.unknown,
      );
      if (!allAssigned) {
        return false;
      }

      state = state.copyWith(
        phase: GamePhase.setup,
        scriptQueue: ScriptBuilder.buildSetupScript(
          state.players,
          dayCount: state.dayCount,
        ),
        scriptIndex: 0,
        actionLog: const {},
        dayCount: 1,
      );
      final sessionController = ref.read(sessionProvider.notifier);
      sessionController.clearRoleConfirmations();
      sessionController.setForceStartOverride(false);
      _gameStartedAt = DateTime.now();
      _persist();
      return true;
    }

    final assignedPlayers = GameResolutionLogic.assignRoles(
      state.players,
      gameStyle: state.gameStyle,
    );
    state = state.copyWith(
      players: assignedPlayers,
      phase: GamePhase.setup,
      scriptQueue: ScriptBuilder.buildSetupScript(assignedPlayers, dayCount: 0),
      scriptIndex: 0,
      actionLog: const {},
      dayCount: 1,
    );
    final sessionController = ref.read(sessionProvider.notifier);
    sessionController.clearRoleConfirmations();
    sessionController.setForceStartOverride(false);
    _gameStartedAt = DateTime.now();
    _persist();
    return true;
  }

  void resetDayVotes() =>
      state = state.copyWith(dayVoteTally: const {}, dayVotesByVoter: const {});

  bool handleTimerExpiry() {
    final tally = state.dayVoteTally;
    final hasEnoughVotes = tally.entries.any(
      (e) => e.key != 'abstain' && e.value >= 2,
    );
    if (!hasEnoughVotes) {
      state = state.copyWith(
        gameHistory: [
          ...state.gameHistory,
          '── VOTE SKIPPED: no votes resolved ──',
        ],
        scriptQueue: [],
      );
      advancePhase();
      return true;
    }
    return false;
  }

  void advancePhase() {
    if (state.phase == GamePhase.setup) {
      final session = ref.read(sessionProvider);
      final requiredIds = state.players
          .where((player) => !player.isBot)
          .map((player) => player.id)
          .toSet();
      final confirmedIds = session.roleConfirmedPlayerIds.toSet();
      final allConfirmed = requiredIds.every(confirmedIds.contains);
      final usesRoleConfirmationFlow =
          session.claimedPlayerIds.isNotEmpty ||
          session.roleConfirmedPlayerIds.isNotEmpty;
      if (usesRoleConfirmationFlow &&
          !allConfirmed &&
          !session.forceStartOverride) {
        return;
      }
    }

    emitStepToFeed();
    if (state.scriptQueue.isNotEmpty &&
        state.scriptIndex < state.scriptQueue.length - 1) {
      state = state.copyWith(scriptIndex: state.scriptIndex + 1);
      return;
    }

    // Phase transitions
    switch (state.phase) {
      case GamePhase.lobby:
      case GamePhase.setup:
        state = state.copyWith(
          phase: GamePhase.night,
          scriptQueue: ScriptBuilder.buildNightScript(
            state.players,
            state.dayCount,
          ),
          scriptIndex: 0,
          actionLog: const {},
        );
        break;
      case GamePhase.night:
        final res = GameResolutionLogic.resolveNightActions(state);
        state = state.copyWith(
          players: res.players,
          lastNightReport: res.report,
          lastNightTeasers: res.teasers,
          privateMessages: res.privateMessages,
          gawkedPlayerId: null,
          gameHistory: [
            ...state.gameHistory,
            '── NIGHT ${state.dayCount} RESOLVED ──',
            ...res.report,
          ],
          eventLog: [...state.eventLog, ...res.events],
          phase: GamePhase.day,
          scriptQueue: ScriptBuilder.buildDayScript(
            state.dayCount,
            state.players,
          ),
          scriptIndex: 0,
          actionLog: const {},
        );
        // Dispatch teasers to bulletin
        for (final teaser in res.teasers) {
          dispatchBulletin(
            title: 'NIGHT RECAP',
            content: teaser,
            type: 'result',
          );
        }

        _checkAndResolveWinCondition(state.players);
        break;
      case GamePhase.day:
        final reactiveChoiceStepsInQueue = state.scriptQueue
            .where(
              (step) =>
                  step.id.startsWith('predator_retaliation_') ||
                  step.id.startsWith('tea_spiller_reveal_') ||
                  step.id.startsWith('drama_queen_vendetta_'),
            )
            .toList();
        if (reactiveChoiceStepsInQueue.isNotEmpty) {
          final hasAllChoices = reactiveChoiceStepsInQueue.every((step) {
            final selected = state.actionLog[step.id];
            return selected != null && selected.isNotEmpty;
          });
          if (!hasAllChoices) {
            return;
          }
        }

        final dayVotesSnapshot = Map<String, String>.from(
          state.dayVotesByVoter,
        );
        final res = GameResolutionLogic.resolveDayVote(
          state.players,
          state.dayVoteTally,
          state.dayCount,
        );

        // Apply resolution results to state first
        state = state.copyWith(players: res.players);

        // ── RESOLVE DEAD POOL BETS ──
        final exiledPlayerId = res.players
            .firstWhere(
              (p) => !p.isAlive && p.deathReason == 'exile',
              orElse: () => Player(
                id: '',
                name: '',
                role: roleCatalog.first,
                alliance: Team.unknown,
              ),
            )
            .id;

        final predatorRetaliationSteps = _buildPredatorRetaliationSteps(
          players: state.players,
          votesByVoter: dayVotesSnapshot,
          dayCount: state.dayCount,
          exiledPlayerId: exiledPlayerId.isEmpty ? null : exiledPlayerId,
        );
        final teaSpillerRevealSteps = _buildTeaSpillerRevealSteps(
          players: state.players,
          votesByVoter: dayVotesSnapshot,
          dayCount: state.dayCount,
          exiledPlayerId: exiledPlayerId.isEmpty ? null : exiledPlayerId,
        );
        final dramaQueenVendettaSteps = _buildDramaQueenVendettaSteps(
          players: state.players,
          dayCount: state.dayCount,
          exiledPlayerId: exiledPlayerId.isEmpty ? null : exiledPlayerId,
        );

        final reactiveChoiceSteps = [
          ...teaSpillerRevealSteps,
          ...dramaQueenVendettaSteps,
          ...predatorRetaliationSteps,
        ];

        final missingReactiveChoice = reactiveChoiceSteps.any((step) {
          final selected = state.actionLog[step.id];
          return selected == null || selected.isEmpty;
        });

        if (reactiveChoiceSteps.isNotEmpty && missingReactiveChoice) {
          state = state.copyWith(
            players: state.players,
            lastDayReport: [...res.report],
            scriptQueue: reactiveChoiceSteps,
            scriptIndex: 0,
            actionLog: const {},
          );
          return;
        }

        final predatorRetaliationChoices =
            _predatorRetaliationChoicesFromActionLog(state.dayCount);
        final teaSpillerRevealChoices = _teaSpillerRevealChoicesFromActionLog(
          state.dayCount,
        );
        final dramaQueenSwapChoices = _dramaQueenSwapChoicesFromActionLog(
          state.dayCount,
        );

        final dayResolution = DayResolutionStrategy().execute(
          DayResolutionContext(
            players: state.players,
            votesByVoter: dayVotesSnapshot,
            dayCount: state.dayCount,
            exiledPlayerId: exiledPlayerId.isEmpty ? null : exiledPlayerId,
            predatorRetaliationChoices: predatorRetaliationChoices,
            teaSpillerRevealChoices: teaSpillerRevealChoices,
            dramaQueenSwapChoices: dramaQueenSwapChoices,
          ),
        );
        state = state.copyWith(players: dayResolution.players);

        state = state.copyWith(
          players:
              state.players, // Current state includes resolution + deadpool
          lastDayReport: [...res.report, ...dayResolution.lines],
          gameHistory: [
            ...state.gameHistory,
            '── DAY ${state.dayCount} RESOLVED ──',
            ...res.report,
            ...dayResolution.lines,
          ],
          eventLog: [...state.eventLog, ...res.events, ...dayResolution.events],
          dayCount: state.dayCount + 1,
          phase: GamePhase.night,
          scriptQueue: ScriptBuilder.buildNightScript(
            state.players,
            state.dayCount + 1,
          ),
          scriptIndex: 0,
          actionLog: const {},
          dayVoteTally: const {},
          dayVotesByVoter: const {},
          deadPoolBets: dayResolution.clearDeadPoolBets
              ? const {}
              : state.deadPoolBets,
        );

        for (final victimId in dayResolution.deathTriggerVictimIds) {
          _handleDeathTriggers(victimId);
        }

        _checkAndResolveWinCondition(state.players);
        break;
      default:
        break;
    }
    _persist();
  }

  void _checkAndResolveWinCondition(List<Player> players) {
    final win = GameResolutionLogic.checkWinCondition(players);
    if (win != null) {
      final winningReport = List<String>.from(win.report);
      if (win.winner != Team.neutral) {
        final livingManagers = players.where(
          (p) => p.isAlive && p.role.id == RoleIds.clubManager,
        );
        if (livingManagers.isNotEmpty) {
          final managerNames = livingManagers.map((p) => p.name).join(', ');
          winningReport.add(
            'Club Manager survived and wins with the house: $managerNames.',
          );
        }
      }

      state = state.copyWith(
        phase: GamePhase.endGame,
        winner: win.winner,
        endGameReport: winningReport,
        scriptQueue: const [],
        scriptIndex: 0,
      );
      archiveGame();
    }
  }
}

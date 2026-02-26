import 'package:cb_models/cb_models.dart';
import '../gemini_narration_service.dart';

class GameNarrationController {
  final GeminiNarrationService _geminiService;

  GameNarrationController(this._geminiService);

  String exportGameLog(GameState state) {
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

  String generateAIRecapPrompt(GameState state, String style) {
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

  Future<String?> generateDynamicNightNarration(
    GameState state, {
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

    return _geminiService.generateNightNarration(
      lastNightReport: state.lastNightReport,
      dayCount: state.dayCount,
      aliveCount: state.players.where((p) => p.isAlive).length,
      voice: effectiveVoice,
      variationPrompt: effectivePrompt,
    );
  }

  Future<String?> generateCurrentStepNarrationVariation(
    GameState state, {
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

    final variation = await _geminiService.generateStepNarrationVariation(
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
}

import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod/riverpod.dart';

final geminiNarrationServiceProvider = Provider<GeminiNarrationService>((ref) {
  return GeminiNarrationService();
});

class GeminiNarrationService {
  GeminiNarrationService({String? apiKey}) : _runtimeApiKey = apiKey;

  String? _runtimeApiKey;
  static const _fallbackModel = 'gemini-2.0-flash';

  void setApiKey(String? key) {
    _runtimeApiKey = (key != null && key.trim().isNotEmpty) ? key.trim() : null;
  }

  bool get hasApiKey => _apiKey.isNotEmpty;

  String get _apiKey {
    if (_runtimeApiKey != null && _runtimeApiKey!.isNotEmpty) {
      return _runtimeApiKey!;
    }
    const direct = String.fromEnvironment('GEMINI_API_KEY');
    if (direct.isNotEmpty) return direct;
    const google = String.fromEnvironment('GOOGLE_API_KEY');
    if (google.isNotEmpty) return google;
    return '';
  }

  GenerativeModel? _getModel({String modelName = _fallbackModel, bool isMature = false}) {
    final key = _apiKey;
    if (key.isEmpty) return null;

    final safetySettings = isMature
        ? [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
          ]
        : [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
          ];

    return GenerativeModel(
      model: modelName,
      apiKey: key,
      safetySettings: safetySettings,
      generationConfig: GenerationConfig(
        temperature: 0.9,
        maxOutputTokens: 450,
      ),
    );
  }

  Future<String> generateNightNarration({
    required List<String> lastNightReport,
    int dayCount = 1,
    int aliveCount = 0,
    String voice = 'nightclub_noir',
    String? variationPrompt,
    String model = _fallbackModel,
    bool isMature = false,
    bool forHostOnly = false,
  }) async {
    if (lastNightReport.isEmpty) return 'No night events were recorded.';

    final genModel = _getModel(modelName: model, isMature: isMature);
    if (genModel == null) {
      debugPrint('[Gemini] No API key. Using local fallback.');
      return _buildLocalFallbackNarration(lastNightReport, voice: voice);
    }

    final prompt = forHostOnly
        ? _buildHostNightPrompt(
            lastNightReport: lastNightReport,
            dayCount: dayCount,
            aliveCount: aliveCount,
            voice: voice,
            variationPrompt: variationPrompt,
            isMature: isMature,
          )
        : _buildPlayerNightPrompt(
            lastNightReport: lastNightReport,
            dayCount: dayCount,
            aliveCount: aliveCount,
            voice: voice,
            variationPrompt: variationPrompt,
            isMature: isMature,
          );

    try {
      final response = await genModel.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return _buildLocalFallbackNarration(lastNightReport, voice: voice);
      }
      return text.trim();
    } catch (e) {
      debugPrint('[Gemini] API Error: $e');
      return _buildLocalFallbackNarration(lastNightReport, voice: voice);
    }
  }

  Future<String> generatePersonalityPreview({
    required String voice,
    required String variationPrompt,
    String model = _fallbackModel,
  }) async {
    final genModel = _getModel(modelName: model);
    if (genModel == null) {
      return 'API Key not found. Fallback: "The neon flickers as the host steps into the light..."';
    }

    final prompt = '''
You are generating a short "Introductory Teaser" to demonstrate your hosting personality for Club Blackout.
Voice Style: $voice
Personality Directive: $variationPrompt

Hard Constraints:
1. Length: 40 to 70 words.
2. Context: You are welcoming a group of players to the club for a new game.
3. Tone: High-fidelity, cinematic.
4. Do not list game rules. Just set the mood in your specific voice.

Show off your unique style now:
''';

    try {
      final response = await genModel.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'The club is silent tonight. (No Output)';
    } catch (e) {
      return 'Connection lost in the static. Try again later. ($e)';
    }
  }

  Future<String> generateStepNarrationVariation({
    required String baseReadAloudText,
    String stepTitle = '',
    String voice = 'nightclub_noir',
    String? variationPrompt,
    String model = _fallbackModel,
    bool isMature = false,
  }) async {
    if (baseReadAloudText.trim().isEmpty) return '';

    final genModel = _getModel(modelName: model, isMature: isMature);
    if (genModel == null) {
      return _buildLocalStepFallbackNarration(
        baseReadAloudText,
        voice: voice,
        variationPrompt: variationPrompt,
      );
    }

    final prompt = _buildStepPrompt(
      baseReadAloudText: baseReadAloudText,
      stepTitle: stepTitle,
      voice: voice,
      variationPrompt: variationPrompt,
      isMature: isMature,
    );

    try {
      final response = await genModel.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null || text.trim().isEmpty) {
        return _buildLocalStepFallbackNarration(
          baseReadAloudText,
          voice: voice,
          variationPrompt: variationPrompt,
        );
      }
      return text.trim();
    } catch (e) {
      debugPrint('[Gemini] Step Error: $e');
      return _buildLocalStepFallbackNarration(
        baseReadAloudText,
        voice: voice,
        variationPrompt: variationPrompt,
      );
    }
  }

  String _buildHostNightPrompt({
    required List<String> lastNightReport,
    required int dayCount,
    required int aliveCount,
    required String voice,
    String? variationPrompt,
    required bool isMature,
  }) {
    final formattedEvents = lastNightReport.map((e) => '- $e').join('\n');

    final safetyDirective = isMature
        ? 'SAFETY LEVEL: R-RATED / MATURE. Allow profanity, dark humor, and abrasive language if fits the persona.'
        : 'SAFETY LEVEL: CLEAN. Strictly family-friendly. No swearing.';

    const audienceDirective = '''
AUDIENCE: HOST ONLY (private, never shown to players).
- Include real player names and role names from the source events.
- The tone can be spicy, heated, explicit, or R-rated for the host's private read-aloud.
- Be spicy, heated, and dramatic. The host reads this for their own amusement.
- You may be irreverent, roast players, and use R-rated humor if the safety level allows.
- Use phrases like: "absolute clown show", "bottled it in the VIP", "neon-soaked catastrophe", "spectacularly poor life choice", "the Dealers are laughing at you".
- Add some self-deprecating host humor like: "I've seen better deductive reasoning from a broken jukebox".
''';

    return '''
You are the narrator for Club Blackout, a neon social-deduction party game set in a high-stakes cyberpunk nightclub.
Write a dramatic spoken recap for the host to read aloud.

GAME CONTEXT:
- Day: $dayCount
- Players Remaining Alive: $aliveCount
- Voice Style: $voice
- $safetyDirective
${variationPrompt == null || variationPrompt.isEmpty ? '' : '- Variation Directive: $variationPrompt'}

$audienceDirective

LORE-STRICT ALLIANCE NAMES (NON-NEGOTIABLE):
- "The Dealers": The killers/staff (Antagonists).
- "The Party Animals": The innocent patrons (Protagonists).
- "Wildcards": The neutral/unpredictable elements.

HARD CONSTRAINTS:
1. Length: Exactly 90 to 160 words.
2. Factual Integrity: Keep names and factual outcomes (deaths, saves, IDs) 100% consistent with source events.
3. No Hallucinations: Do not invent new roles, votes, or player actions not in the report.
4. Tone: High-fidelity, cinematic, nightclub-noir. Adjust tone based on stakes:
   - Early game (High aliveCount): High energy, "The party is just getting started."
   - Late game (Low aliveCount): Gritty, desperate, "The club is nearly empty, the end is near."

VOICE STYLE GUIDE:
- system_glitch: Stuttering, digital fragments, recursive loops, "C-C-Club... [ERROR]".
- vixen_whisper: Dangerous, seductive, low-register, intimate but threatening.
- nightclub_noir: Classic gritty narrator, smoke and mirrors.
- host_hype: High energy, electric, keeping the crowd moving.

SOURCE EVENTS (Night Report):
$formattedEvents
''';
  }

  String _buildPlayerNightPrompt({
    required List<String> lastNightReport,
    required int dayCount,
    required int aliveCount,
    required String voice,
    String? variationPrompt,
    required bool isMature,
  }) {
    final formattedEvents = lastNightReport.map((e) => '- $e').join('\n');

    final safetyDirective = isMature
        ? 'SAFETY LEVEL: PG-13. No profanity, but can be dark/dramatic.'
        : 'SAFETY LEVEL: CLEAN. Strictly family-friendly.';

    const audienceDirective = '''
AUDIENCE: PLAYERS (public, shown to everyone).
- DO NOT use real player names.
- DO NOT use real role names (e.g., "Medic", "Bouncer").
- Describe outcomes dramatically but anonymously.
- Examples: "A patron fell to the Dealers", "Someone was saved in the shadows", "A life was spared tonight".
''';

    return '''
You are the narrator for Club Blackout, a neon social-deduction party game set in a high-stakes cyberpunk nightclub.
Write a dramatic spoken recap for the players to read.

GAME CONTEXT:
- Day: $dayCount
- Players Remaining Alive: $aliveCount
- Voice Style: $voice
- $safetyDirective
${variationPrompt == null || variationPrompt.isEmpty ? '' : '- Variation Directive: $variationPrompt'}

$audienceDirective

LORE-STRICT ALLIANCE NAMES (NON-NEGOTIABLE):
- "The Dealers": The killers/staff (Antagonists).
- "The Party Animals": The innocent patrons (Protagonists).
- "Wildcards": The neutral/unpredictable elements.

HARD CONSTRAINTS:
1. Length: Exactly 90 to 160 words.
2. Factual Integrity: Keep factual outcomes (deaths, saves, IDs) 100% consistent with source events, but make them anonymous.
3. No Hallucinations: Do not invent new roles, votes, or player actions not in the report.
4. Tone: High-fidelity, cinematic, nightclub-noir. Adjust tone based on stakes:
   - Early game (High aliveCount): High energy, "The party is just getting started."
   - Late game (Low aliveCount): Gritty, desperate, "The club is nearly empty, the end is near."

VOICE STYLE GUIDE:
- system_glitch: Stuttering, digital fragments, recursive loops, "C-C-Club... [ERROR]".
- vixen_whisper: Dangerous, seductive, low-register, intimate but threatening.
- nightclub_noir: Classic gritty narrator, smoke and mirrors.
- host_hype: High energy, electric, keeping the crowd moving.

SOURCE EVENTS (Night Report):
$formattedEvents
''';
  }

  String _buildStepPrompt({
    required String baseReadAloudText,
    required String stepTitle,
    required String voice,
    String? variationPrompt,
    required bool isMature,
  }) {
    final safetyDirective = isMature
        ? 'SAFETY LEVEL: R-RATED. Allow profanity/edge.'
        : 'SAFETY LEVEL: CLEAN. Family-friendly.';

    return '''
You are the narrator for Club Blackout, a neon social-deduction party game.
Rewrite the host read-aloud line as a punchier variation while preserving intent.

Step title: $stepTitle
Voice style: $voice
$safetyDirective
${variationPrompt == null || variationPrompt.isEmpty ? '' : 'Variation directive: $variationPrompt'}

Hard constraints:
- 25 to 70 words.
- Keep factual meaning consistent with the source line.
- Do not introduce new game outcomes, players, or roles.
- Keep the tone cinematic and host-friendly.

Source line:
$baseReadAloudText
''';
  }

  String _buildLocalFallbackNarration(
    List<String> lastNightReport, {
    required String voice,
  }) {
    final highlights = lastNightReport.take(4).toList();
    final opener = switch (voice) {
      'host_hype' => 'Club Blackout surged into another electric night.',
      'nightclub_noir' =>
        'Neon shadows stretched across the floor as the night turned.',
      'system_glitch' =>
        'N-N-Night... p-processing... system integrity compromised.',
      'vixen_whisper' =>
        'Lean in close, darling. The night has secrets to share.',
      _ => 'The night closed in and the club changed by morning.',
    };

    final body = highlights.map((line) => '• $line').join('\n');
    return '$opener\n\n$body\n\nBy sunrise, the room had fewer certainties and far more suspicion.';
  }

  String _buildLocalStepFallbackNarration(
    String baseReadAloudText, {
    required String voice,
    String? variationPrompt,
  }) {
    final directive = (variationPrompt ?? '').trim();
    final styleLead = switch (voice) {
      'host_hype' => 'Host energy up.',
      'nightclub_noir' => 'Neon-noir tone.',
      'system_glitch' => '[GLITCH MODE]',
      'vixen_whisper' => '[WHISPER MODE]',
      _ => 'Keep it dramatic.',
    };

    if (directive.isNotEmpty) {
      return '$styleLead $directive\n$baseReadAloudText';
    }
    return '$styleLead $baseReadAloudText';
  }
}

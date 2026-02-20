import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';

final geminiNarrationServiceProvider = Provider<GeminiNarrationService>((ref) {
  return GeminiNarrationService();
});

class GeminiNarrationService {
  GeminiNarrationService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        _injectedApiKey = apiKey;

  final http.Client _client;
  final String? _injectedApiKey;

  static const _fallbackModel = 'gemini-1.5-flash';

  String get _apiKey {
    // 0. Check for injected API key (highest priority, for testing)
    if (_injectedApiKey != null) return _injectedApiKey!;

    // 1. Check for command-line/environment injection (highest priority)
    const direct = String.fromEnvironment('GEMINI_API_KEY');
    if (direct.isNotEmpty) return direct;

    const google = String.fromEnvironment('GOOGLE_API_KEY');
    if (google.isNotEmpty) return google;

    return '';
  }

  Future<String> generateNightNarration({
    required List<String> lastNightReport,
    int dayCount = 1,
    int aliveCount = 0,
    String voice = 'nightclub_noir',
    String? variationPrompt,
    String model = _fallbackModel,
  }) async {
    if (lastNightReport.isEmpty) {
      return 'No night events were recorded.';
    }

    final key = _apiKey;
    if (key.isEmpty) {
      debugPrint(
          '[GeminiNarrationService] No API key found. Using local fallback narration.');
      return _buildLocalFallbackNarration(lastNightReport, voice: voice);
    }

    final endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
    );

    final prompt = _buildPrompt(
      lastNightReport: lastNightReport,
      dayCount: dayCount,
      aliveCount: aliveCount,
      voice: voice,
      variationPrompt: variationPrompt,
    );

    try {
      final response = await _client.post(
        endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.9,
            'maxOutputTokens': 450,
          },
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
            '[GeminiNarrationService] API error ${response.statusCode}: ${response.body}');
        return _buildLocalFallbackNarration(lastNightReport, voice: voice);
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = payload['candidates'] as List<dynamic>?;
      final firstCandidate = candidates != null && candidates.isNotEmpty
          ? candidates.first as Map<String, dynamic>
          : null;
      final content = firstCandidate?['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final firstPart = parts != null && parts.isNotEmpty
          ? parts.first as Map<String, dynamic>
          : null;
      final text = firstPart?['text'] as String?;

      if (text == null || text.trim().isEmpty) {
        return _buildLocalFallbackNarration(lastNightReport, voice: voice);
      }

      return text.trim();
    } catch (e) {
      debugPrint(
          '[GeminiNarrationService] Request failed, using local fallback: $e');
      return _buildLocalFallbackNarration(lastNightReport, voice: voice);
    }
  }

  Future<String> generatePersonalityPreview({
    required String voice,
    required String variationPrompt,
    String model = _fallbackModel,
  }) async {
    final key = _apiKey;
    if (key.isEmpty) {
      return 'API Key not found. Fallback: "The neon flickers as the host steps into the light..."';
    }

    final endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
    );

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
      final response = await _client.post(
        endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.95,
            'maxOutputTokens': 150,
          },
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'The club is silent tonight. (API Error)';
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final text = (payload['candidates'] as List)
          .first['content']['parts']
          .first['text'] as String;
      return text.trim();
    } catch (e) {
      return 'Connection lost in the static. Try again later.';
    }
  }

  Future<String> generateStepNarrationVariation({
    required String baseReadAloudText,
    String stepTitle = '',
    String voice = 'nightclub_noir',
    String? variationPrompt,
    String model = _fallbackModel,
  }) async {
    if (baseReadAloudText.trim().isEmpty) {
      return '';
    }

    final key = _apiKey;
    if (key.isEmpty) {
      debugPrint(
          '[GeminiNarrationService] No API key found. Using local step fallback narration.');
      return _buildLocalStepFallbackNarration(
        baseReadAloudText,
        voice: voice,
        variationPrompt: variationPrompt,
      );
    }

    final endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
    );

    final prompt = _buildStepPrompt(
      baseReadAloudText: baseReadAloudText,
      stepTitle: stepTitle,
      voice: voice,
      variationPrompt: variationPrompt,
    );

    try {
      final response = await _client.post(
        endpoint,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.92,
            'maxOutputTokens': 220,
          },
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
            '[GeminiNarrationService] API error ${response.statusCode}: ${response.body}');
        return _buildLocalStepFallbackNarration(
          baseReadAloudText,
          voice: voice,
          variationPrompt: variationPrompt,
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = payload['candidates'] as List<dynamic>?;
      final firstCandidate = candidates != null && candidates.isNotEmpty
          ? candidates.first as Map<String, dynamic>
          : null;
      final content = firstCandidate?['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final firstPart = parts != null && parts.isNotEmpty
          ? parts.first as Map<String, dynamic>
          : null;
      final text = firstPart?['text'] as String?;

      if (text == null || text.trim().isEmpty) {
        return _buildLocalStepFallbackNarration(
          baseReadAloudText,
          voice: voice,
          variationPrompt: variationPrompt,
        );
      }

      return text.trim();
    } catch (e) {
      debugPrint(
          '[GeminiNarrationService] Step narration request failed, using local fallback: $e');
      return _buildLocalStepFallbackNarration(
        baseReadAloudText,
        voice: voice,
        variationPrompt: variationPrompt,
      );
    }
  }

  String _buildPrompt({
    required List<String> lastNightReport,
    required int dayCount,
    required int aliveCount,
    required String voice,
    String? variationPrompt,
  }) {
    final report = lastNightReport.join('\n- ');

    return '''
You are the narrator for Club Blackout, a neon social-deduction party game set in a high-stakes cyberpunk nightclub.
Write a dramatic spoken recap for the host to read aloud.

GAME CONTEXT:
- Day: $dayCount
- Players Remaining Alive: $aliveCount
- Voice Style: $voice
${variationPrompt == null || variationPrompt.isEmpty ? '' : '- Variation Directive: $variationPrompt'}

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

SOURCE EVENTS (lastNightReport):
- $report
''';
  }

  String _buildStepPrompt({
    required String baseReadAloudText,
    required String stepTitle,
    required String voice,
    String? variationPrompt,
  }) {
    return '''
You are the narrator for Club Blackout, a neon social-deduction party game.
Rewrite the host read-aloud line as a punchier variation while preserving intent.

Step title: $stepTitle
Voice style: $voice
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

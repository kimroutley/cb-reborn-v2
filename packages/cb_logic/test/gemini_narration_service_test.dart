import 'package:cb_logic/src/gemini_narration_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeminiNarrationService', () {
    test('generateNightNarration returns no-events message when report empty', () async {
      final service = GeminiNarrationService();
      final result = await service.generateNightNarration(
        lastNightReport: const [],
      );

      expect(result, 'No night events were recorded.');
    });

    test('generateNightNarration falls back without API key', () async {
      final service = GeminiNarrationService();
      const report = ['Player A died.'];

      final result = await service.generateNightNarration(lastNightReport: report);

      expect(result, contains('Player A died.'));
      expect(result, contains('By sunrise'));
    });

    test('generatePersonalityPreview without API key returns key warning',
        () async {
      final service = GeminiNarrationService();

      final result = await service.generatePersonalityPreview(
        voice: 'host_hype',
        variationPrompt: 'Energetic',
      );

      expect(result, contains('API Key not found'));
    });

    test('generateStepNarrationVariation returns empty when base text empty',
        () async {
      final service = GeminiNarrationService();
      final result = await service.generateStepNarrationVariation(
        baseReadAloudText: '',
      );

      expect(result, '');
    });

    test('generateStepNarrationVariation without API key returns fallback',
        () async {
      final service = GeminiNarrationService();
      final result = await service.generateStepNarrationVariation(
        baseReadAloudText: 'Original text.',
        voice: 'nightclub_noir',
      );

      expect(result, contains('Neon-noir tone.'));
      expect(result, contains('Original text.'));
    });
  });
}

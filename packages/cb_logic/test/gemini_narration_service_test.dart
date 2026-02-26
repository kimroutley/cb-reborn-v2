import 'dart:convert';

import 'package:cb_logic/src/gemini_narration_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GeminiNarrationService', () {
    const validApiKey = 'test_api_key';

    test('generateNightNarration returns generated text on success', () async {
      final client = MockClient((request) async {
        expect(request.url.toString(), contains(validApiKey));
        expect(request.method, 'POST');
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Generated narration text.'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service =
          GeminiNarrationService(client: client, apiKey: validApiKey);
      final result = await service.generateNightNarration(
        lastNightReport: ['Player A died.'],
      );

      expect(result, 'Generated narration text.');
    });

    test('generateNightNarration returns fallback on API error', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service =
          GeminiNarrationService(client: client, apiKey: validApiKey);
      final result = await service.generateNightNarration(
        lastNightReport: ['Player A died.'],
      );

      // Verify it returns fallback (starts with one of the voice intros)
      expect(result, contains('Player A died.'));
      expect(result, contains('By sunrise, the room had fewer certainties'));
    });

    test('generateNightNarration returns fallback on malformed response',
        () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'candidates': []}), 200);
      });

      final service =
          GeminiNarrationService(client: client, apiKey: validApiKey);
      final result = await service.generateNightNarration(
        lastNightReport: ['Player A died.'],
      );

      expect(result, contains('Player A died.'));
    });

    test('generateNightNarration returns fallback on network exception',
        () async {
      final client = MockClient((request) async {
        throw http.ClientException('Network error');
      });

      final service =
          GeminiNarrationService(client: client, apiKey: validApiKey);
      final result = await service.generateNightNarration(
        lastNightReport: ['Player A died.'],
      );

      expect(result, contains('Player A died.'));
    });

    test('generateNightNarration uses fallback when no API key provided',
        () async {
      // Create service without API key (and assuming env var is empty in test env)
      final service = GeminiNarrationService();
      // Note: We can't easily mock the internal client if we don't pass it,
      // but if no API key is present, it shouldn't even call the client.

      final result = await service.generateNightNarration(
        lastNightReport: ['Player A died.'],
      );

      expect(result, contains('Player A died.'));
    });

    test('generatePersonalityPreview returns text on success', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'I am your host.'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service =
          GeminiNarrationService(client: client, apiKey: validApiKey);
      final result = await service.generatePersonalityPreview(
        voice: 'host_hype',
        variationPrompt: 'Energetic',
      );

      expect(result, 'I am your host.');
    });

    test('generatePersonalityPreview returns error message on API error',
        () async {
      final client = MockClient((request) async {
        return http.Response('Error', 500);
      });

      final service =
          GeminiNarrationService(client: client, apiKey: validApiKey);
      final result = await service.generatePersonalityPreview(
        voice: 'host_hype',
        variationPrompt: 'Energetic',
      );

      expect(result, 'The club is silent tonight. (API Error)');
    });

    test('generatePersonalityPreview returns error message on exception',
        () async {
      final client = MockClient((request) async {
        throw Exception('Boom');
      });

      final service =
          GeminiNarrationService(client: client, apiKey: validApiKey);
      final result = await service.generatePersonalityPreview(
        voice: 'host_hype',
        variationPrompt: 'Energetic',
      );

      expect(result, 'Connection lost in the static. Try again later.');
    });

    test('generateStepNarrationVariation returns text on success', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Step variation.'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final service =
          GeminiNarrationService(client: client, apiKey: validApiKey);
      final result = await service.generateStepNarrationVariation(
        baseReadAloudText: 'Original text.',
      );

      expect(result, 'Step variation.');
    });

    test('generateStepNarrationVariation returns fallback on API error',
        () async {
      final client = MockClient((request) async {
        return http.Response('Error', 500);
      });

      final service =
          GeminiNarrationService(client: client, apiKey: validApiKey);
      final result = await service.generateStepNarrationVariation(
        baseReadAloudText: 'Original text.',
        voice: 'nightclub_noir',
      );

      // Fallback format: "$styleLead $baseReadAloudText"
      expect(result, contains('Original text.'));
      expect(result, contains('Neon-noir tone.'));
    });
  });
}

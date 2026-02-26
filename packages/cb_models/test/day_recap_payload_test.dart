import 'dart:convert';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DayRecapCardPayload', () {
    test('round-trips via JSON', () {
      const payload = DayRecapCardPayload(
        v: 1,
        recapId: 'day-2-recap-v1',
        day: 2,
        title: 'DAY 2 RECAP',
        bullets: ['A patron was exiled.', 'Suspicion lingers.'],
        generatedAtMs: 1000,
      );

      final json = payload.toJsonString();
      final restored = DayRecapCardPayload.tryParse(json);

      expect(restored, isNotNull);
      expect(restored!.v, 1);
      expect(restored.recapId, 'day-2-recap-v1');
      expect(restored.day, 2);
      expect(restored.title, 'DAY 2 RECAP');
      expect(restored.bullets, hasLength(2));
      expect(restored.generatedAtMs, 1000);
    });

    test('tryParse returns null for malformed JSON', () {
      expect(DayRecapCardPayload.tryParse('not json'), isNull);
    });

    test('tryParse returns null for JSON array', () {
      expect(DayRecapCardPayload.tryParse('[1,2,3]'), isNull);
    });

    test('tryParse returns null for unsupported version', () {
      final json = jsonEncode({'v': 99, 'recapId': 'x', 'day': 1});
      expect(DayRecapCardPayload.tryParse(json), isNull);
    });

    test('fromJson applies defaults for missing optional fields', () {
      final payload = DayRecapCardPayload.fromJson({'v': 1});
      expect(payload.recapId, '');
      expect(payload.day, 0);
      expect(payload.title, '');
      expect(payload.bullets, isEmpty);
      expect(payload.generatedAtMs, 0);
    });
  });

  group('DayRecapHostPayload', () {
    test('round-trips via JSON', () {
      const payload = DayRecapHostPayload(
        v: 1,
        recapId: 'day-3-recap-host-v1',
        day: 3,
        title: 'DAY 3 RECAP (HOST)',
        bullets: ['Alice (Medic) was exiled.', 'Votes: Bob 4, Charlie 1'],
        generatedAtMs: 2000,
      );

      final json = payload.toJsonString();
      final restored = DayRecapHostPayload.tryParse(json);

      expect(restored, isNotNull);
      expect(restored!.v, 1);
      expect(restored.recapId, 'day-3-recap-host-v1');
      expect(restored.day, 3);
      expect(restored.bullets, hasLength(2));
    });

    test('tryParse returns null for empty string', () {
      expect(DayRecapHostPayload.tryParse(''), isNull);
    });

    test('tryParse returns null for unsupported version', () {
      final json = jsonEncode({'v': 0, 'recapId': 'x', 'day': 1});
      expect(DayRecapHostPayload.tryParse(json), isNull);
    });
  });
}

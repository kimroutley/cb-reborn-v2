import 'dart:convert';
import 'package:cb_models/cb_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DayRecapCardPayload', () {
    test('round-trips via JSON', () {
      const payload = DayRecapCardPayload(
        v: 1,
        day: 2,
        playerTitle: 'DAY 2 RECAP',
        playerBullets: ['A patron was exiled.', 'Suspicion lingers.'],
        hostTitle: 'DAY 2 RECAP',
        hostBullets: ['Alice (Medic) was exiled.', 'Votes: Alice: 3'],
      );

      final json = payload.toJsonString();
      final restored = DayRecapCardPayload.tryParse(json);

      expect(restored, isNotNull);
      expect(restored!.v, 1);
      expect(restored.day, 2);
      expect(restored.playerTitle, 'DAY 2 RECAP');
      expect(restored.playerBullets, hasLength(2));
      expect(restored.hostTitle, 'DAY 2 RECAP');
      expect(restored.hostBullets, hasLength(2));
    });

    test('tryParse returns null for malformed JSON', () {
      expect(DayRecapCardPayload.tryParse('not json'), isNull);
    });

    test('tryParse returns null for JSON array', () {
      expect(DayRecapCardPayload.tryParse('[1,2,3]'), isNull);
    });

    test('tryParse returns null for unsupported version', () {
      final json = jsonEncode({'v': 99, 'day': 1});
      expect(DayRecapCardPayload.tryParse(json), isNull);
    });

    test('fromJson applies defaults for missing optional fields', () {
      final payload = DayRecapCardPayload.fromJson({'v': 1});
      expect(payload.day, 0);
      expect(payload.playerTitle, '');
      expect(payload.playerBullets, isEmpty);
      expect(payload.hostTitle, '');
      expect(payload.hostBullets, isEmpty);
    });
  });
}

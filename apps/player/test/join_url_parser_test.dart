import 'package:cb_player/screens/connect_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseJoinUrlPayload', () {
    test('parses cloud URL and normalizes code', () {
      final parsed = parseJoinUrlPayload(
        'https://cb-reborn.web.app/join?mode=cloud&code=NEONABCDEF',
      );

      expect(parsed, isNotNull);
      expect(parsed!.mode, PlayerSyncMode.cloud);
      expect(parsed.normalizedCode, 'NEON-ABCDEF');
      expect(parsed.hostUrl, isNull);
    });

    test('treats legacy local URL as cloud and decodes host endpoint', () {
      final parsed = parseJoinUrlPayload(
        'https://cb-reborn.web.app/join?mode=local&code=NEONABCDEF&host=ws%3A%2F%2F192.168.1.10%3A8080',
      );

      expect(parsed, isNotNull);
      expect(parsed!.mode, PlayerSyncMode.cloud);
      expect(parsed.normalizedCode, 'NEON-ABCDEF');
      expect(parsed.hostUrl, 'ws://192.168.1.10:8080');
    });

    test('returns null when code is missing', () {
      final parsed = parseJoinUrlPayload(
        'https://cb-reborn.web.app/join?mode=cloud',
      );

      expect(parsed, isNull);
    });

    test('returns null for non-url text', () {
      final parsed = parseJoinUrlPayload('NEON-ABCDEF');
      expect(parsed, isNull);
    });

    test('unknown mode still parses code but leaves mode unset', () {
      final parsed = parseJoinUrlPayload(
        'https://cb-reborn.web.app/join?mode=weird&code=NEONABCDEF',
      );

      expect(parsed, isNotNull);
      expect(parsed!.mode, isNull);
      expect(parsed.normalizedCode, 'NEON-ABCDEF');
    });
  });

  group('normalizeJoinCode', () {
    test('normalizes 10-char compact code to NEON-ABCDEF format', () {
      expect(normalizeJoinCode('neonabcdef'), 'NEON-ABCDEF');
    });

    test('preserves uppercase when length is not compact 10 chars', () {
      expect(normalizeJoinCode('neon-abc'), 'NEON-ABC');
    });
  });
}

import 'package:cb_player/screens/home_screen.dart';
import 'package:cb_player/screens/connect_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldAcceptJoinUrlEvent', () {
    test('accepts first non-empty URL', () {
      final now = DateTime(2026, 2, 17, 10, 0, 0);

      final accepted = shouldAcceptJoinUrlEvent(
        incomingUrl: 'https://cb-reborn.web.app/join?mode=cloud&code=NEON-ABCDEF',
        lastHandledUrl: null,
        lastHandledAt: null,
        now: now,
      );

      expect(accepted, isTrue);
    });

    test('rejects duplicate URL inside debounce window', () {
      final first = DateTime(2026, 2, 17, 10, 0, 0);
      final second = first.add(const Duration(milliseconds: 900));

      final accepted = shouldAcceptJoinUrlEvent(
        incomingUrl: 'https://cb-reborn.web.app/join?mode=cloud&code=NEON-ABCDEF',
        lastHandledUrl: 'https://cb-reborn.web.app/join?mode=cloud&code=NEON-ABCDEF',
        lastHandledAt: first,
        now: second,
      );

      expect(accepted, isFalse);
    });

    test('accepts duplicate URL after debounce window', () {
      final first = DateTime(2026, 2, 17, 10, 0, 0);
      final second = first.add(const Duration(seconds: 3));

      final accepted = shouldAcceptJoinUrlEvent(
        incomingUrl: 'https://cb-reborn.web.app/join?mode=cloud&code=NEON-ABCDEF',
        lastHandledUrl: 'https://cb-reborn.web.app/join?mode=cloud&code=NEON-ABCDEF',
        lastHandledAt: first,
        now: second,
      );

      expect(accepted, isTrue);
    });

    test('accepts different URL even inside debounce window', () {
      final first = DateTime(2026, 2, 17, 10, 0, 0);
      final second = first.add(const Duration(milliseconds: 500));

      final accepted = shouldAcceptJoinUrlEvent(
        incomingUrl: 'https://cb-reborn.web.app/join?mode=local&code=NEON-XYZ123',
        lastHandledUrl: 'https://cb-reborn.web.app/join?mode=cloud&code=NEON-ABCDEF',
        lastHandledAt: first,
        now: second,
      );

      expect(accepted, isTrue);
    });
  });

  group('shouldNavigateToClaim', () {
    test('returns true when mounted and not currently navigating', () {
      final allowed = shouldNavigateToClaim(
        isNavigating: false,
        mounted: true,
      );

      expect(allowed, isTrue);
    });

    test('returns false when already navigating', () {
      final allowed = shouldNavigateToClaim(
        isNavigating: true,
        mounted: true,
      );

      expect(allowed, isFalse);
    });

    test('returns false when widget is unmounted', () {
      final allowed = shouldNavigateToClaim(
        isNavigating: false,
        mounted: false,
      );

      expect(allowed, isFalse);
    });
  });
}

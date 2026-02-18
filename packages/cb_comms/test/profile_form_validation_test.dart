import 'package:cb_comms/cb_comms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileFormValidation.validateUsername', () {
    test('accepts valid username', () {
      expect(ProfileFormValidation.validateUsername('Neon Host'), isNull);
    });

    test('rejects short username', () {
      expect(
        ProfileFormValidation.validateUsername('ab'),
        isNotNull,
      );
    });

    test('rejects invalid characters', () {
      expect(
        ProfileFormValidation.validateUsername('bad@name'),
        isNotNull,
      );
    });
  });

  group('ProfileFormValidation public player id helpers', () {
    test('sanitizes to lowercase and strips invalid chars', () {
      expect(
        ProfileFormValidation.sanitizePublicPlayerId('  Night#Fox!!  '),
        'nightfox',
      );
    });

    test('allows empty public id', () {
      expect(ProfileFormValidation.validatePublicPlayerId(''), isNull);
    });

    test('rejects too-short public id', () {
      expect(
        ProfileFormValidation.validatePublicPlayerId('ab'),
        isNotNull,
      );
    });
  });
}

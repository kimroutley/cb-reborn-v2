import 'package:cb_comms/src/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileRepository.normalizePublicPlayerId', () {
    test('handles mixed case', () {
      expect(ProfileRepository.normalizePublicPlayerId('TestUser'), 'testuser');
    });

    test('handles spaces', () {
      expect(ProfileRepository.normalizePublicPlayerId(' Test User '), 'testuser');
    });

    test('handles special chars', () {
      expect(ProfileRepository.normalizePublicPlayerId('user!@#name'), 'username');
    });

    test('handles numbers', () {
      expect(ProfileRepository.normalizePublicPlayerId('User123'), 'user123');
    });

    test('handles hyphens and underscores', () {
      expect(ProfileRepository.normalizePublicPlayerId('User-Name_1'), 'user-name_1');
    });

    test('handles empty string', () {
      expect(ProfileRepository.normalizePublicPlayerId(''), '');
    });
  });

  group('ProfileRepository.maskEmail', () {
    test('handles null', () {
      expect(ProfileRepository.maskEmail(null), 'unknown@email');
    });

    test('handles empty string', () {
      expect(ProfileRepository.maskEmail(''), 'unknown@email');
    });

    test('handles invalid email (no @)', () {
      expect(ProfileRepository.maskEmail('invalid'), 'unknown@email');
    });

    test('handles short name (1 char)', () {
      expect(ProfileRepository.maskEmail('a@b.com'), '**@b.com');
    });

    test('handles short name (2 chars)', () {
      expect(ProfileRepository.maskEmail('ab@b.com'), '**@b.com');
    });

    test('handles long name (3 chars)', () {
      expect(ProfileRepository.maskEmail('abc@b.com'), 'a***c@b.com');
    });

    test('handles long name (multiple chars)', () {
      expect(ProfileRepository.maskEmail('johndoe@example.com'), 'j***e@example.com');
    });

    test('handles multiple @ symbols (edge case)', () {
      // The implementation splits by '@' and takes first and last parts.
      // So 'a@b@c' -> first='a', last='c'.
      expect(ProfileRepository.maskEmail('a@b@c'), '**@c');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:cb_models/cb_models.dart';

void main() {
  group('generateJoinCode', () {
    test('returns a string starting with NEON-', () {
      final code = generateJoinCode();
      expect(code.startsWith('NEON-'), isTrue);
    });

    test('returns a string with length 9', () {
      final code = generateJoinCode();
      expect(code.length, equals(9));
    });

    test('returns a string with valid characters', () {
      final code = generateJoinCode();
      final validChars = RegExp(r'^NEON-[A-HJ-NP-Z2-9]{4}$');
      expect(validChars.hasMatch(code), isTrue);
    });
  });
}

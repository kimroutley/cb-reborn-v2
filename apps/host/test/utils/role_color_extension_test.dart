import 'package:cb_host/utils/role_color_extension.dart';
import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Role createRole(String colorHex) {
    return Role(
      id: 'test_role',
      name: 'Test Role',
      type: 'test',
      description: 'A test role',
      nightPriority: 0,
      assetPath: 'assets/roles/test.png',
      colorHex: colorHex,
    );
  }

  group('RoleColorExtension', () {
    test('parses 6-digit hex string correctly', () {
      final role = createRole('aabbcc');
      expect(role.color, equals(const Color(0xffaabbcc)));
    });

    test('parses 7-digit hex string with # correctly', () {
      final role = createRole('#aabbcc');
      expect(role.color, equals(const Color(0xffaabbcc)));
    });

    test('parses 8-digit hex string correctly', () {
      final role = createRole('ffaabbcc');
      expect(role.color, equals(const Color(0xffaabbcc)));
    });

    test('parses 9-digit hex string with # correctly', () {
      final role = createRole('#ffaabbcc');
      expect(role.color, equals(const Color(0xffaabbcc)));
    });

    test('throws FormatException for invalid hex string', () {
      final role = createRole('invalid');
      expect(() => role.color, throwsFormatException);
    });

    test('throws FormatException for empty string', () {
      final role = createRole('');
      expect(() => role.color, throwsFormatException);
    });
  });
}

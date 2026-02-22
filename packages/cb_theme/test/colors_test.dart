import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cb_theme/src/colors.dart';

void main() {
  group('CBColors.fromHex', () {
    test('parses 6-digit hex correctly', () {
      expect(CBColors.fromHex('#FF0000'), const Color(0xFFFF0000)); // Red
      expect(CBColors.fromHex('00FF00'), const Color(0xFF00FF00)); // Green
      expect(CBColors.fromHex('#0000FF'), const Color(0xFF0000FF)); // Blue
    });

    test('parses 8-digit hex correctly (ARGB)', () {
      // 80 (alpha ~50%), FF (red), 00 (green), 00 (blue)
      expect(CBColors.fromHex('#80FF0000'), const Color(0x80FF0000));
    });

    test('handles invalid hex gracefully (fallback to electricCyan)', () {
      final fallback = CBColors.electricCyan;
      expect(CBColors.fromHex('invalid'), fallback);
      expect(CBColors.fromHex('#'), fallback);
      expect(CBColors.fromHex(''), fallback);
    });

    test('parses 3-digit hex correctly', () {
      expect(CBColors.fromHex('#F00'), const Color(0xFFFF0000));
      expect(CBColors.fromHex('0F0'), const Color(0xFF00FF00));
      expect(CBColors.fromHex('00F'), const Color(0xFF0000FF));
    });
  });
}

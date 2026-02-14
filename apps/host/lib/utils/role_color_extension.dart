import 'package:cb_models/cb_models.dart';
import 'package:flutter/material.dart';

extension RoleColorExtension on Role {
  Color get color {
    final buffer = StringBuffer();
    if (colorHex.length == 6 || colorHex.length == 7) buffer.write('ff');
    buffer.write(colorHex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}

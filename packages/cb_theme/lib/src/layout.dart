import 'package:flutter/widgets.dart';

/// Spacing, radius, and motion tokens for consistent layout across Host + Player.
class CBSpace {
  CBSpace._();

  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;
}

class CBInsets {
  CBInsets._();

  /// Standard screen padding (Style Guide: 16px).
  static const EdgeInsets screen = EdgeInsets.all(CBSpace.x4);
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: CBSpace.x4);
  static const EdgeInsets screenV = EdgeInsets.symmetric(vertical: CBSpace.x4);

  /// Spacious content blocks (Style Guide: 24px).
  static const EdgeInsets panel = EdgeInsets.all(CBSpace.x6);

  /// Bottom sheets: slightly tighter top, roomier bottom.
  static const EdgeInsets sheet = EdgeInsets.fromLTRB(
    CBSpace.x4,
    CBSpace.x3,
    CBSpace.x4,
    CBSpace.x6,
  );
}

class CBRadius {
  CBRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double dialog = 28;
  static const double xl = 32;
  static const double pill = 999;
}

class CBMotion {
  CBMotion._();

  // Style Guide: micro 250ms, transitions ~400ms.
  static const Duration micro = Duration(milliseconds: 250);
  static const Duration transition = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 800);

  static const Curve standardCurve = Curves.easeInOut;
  static const Curve emphasizedCurve = Curves.easeOutCubic;
}

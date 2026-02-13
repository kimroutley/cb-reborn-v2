import 'package:flutter/material.dart';

class CBColors {
  // Convenience token: prefer this over `Colors.transparent` in app code so
  // all styling still routes through `cb_theme`.
  static const Color transparent = Color(0x00000000);

  // --- Radiant Neon Palette ---
  static const Color radiantPink = Color(0xFFF72585);
  static const Color radiantTurquoise = Color(0xFF4CC9F0);

  // --- NEON M3 PALETTE (Radiant Neon) ---
  static const Color neonBlue = radiantTurquoise; // Primary – vibrant cyan
  static const Color neonPink = radiantPink; // Secondary – vibrant magenta-pink
  static const Color neonPurple =
      radiantPink; // Strict palette: map tertiary to pink

  // --- ROLE-INSPIRED ACCENT COLORS ---
  static const Color whoreTeal = Color(0xFF35C9DF);
  static const Color seasonedMint = Color(0xFF78DFF2);
  static const Color secondWindCerise = Color(0xFFF43A97);

  // Additional role-based accent colors
  static const Color dealerMagenta = radiantPink; // Dealer
  static const Color allyCatYellow = radiantTurquoise; // Ally Cat
  static const Color creepPurple = Color(0xFFE13CB2); // Creep

  static const Color darkGrey = Color(0xFF191C1D); // Surface
  static const Color voidBlack = Color(0xFF0E1112); // Background

  // --- SEMANTIC MAPPINGS ---
  static const Color background = voidBlack;
  static const Color surface = darkGrey;
  static const Color onSurface = Color(0xFFF0F0F0);
  static const Color primary = radiantTurquoise;
  static const Color secondary = radiantPink;
  static const Color coolGrey = Color(0xFF495867);

  // Status & Accents
  static const Color yellow = radiantPink;

  // Match the Radiant Neon spec: saturated, readable on dark surfaces.
  static const Color error = Color(0xFFFF4FA8);
  static const Color success = radiantTurquoise; // "matrixGreen"
  static const Color warning = Color(0xFF2FE3D6); // "alertOrange"

  static const Color red = error;
  static const Color green = success;
  static const Color orange = warning;

  // Special Effects (Glows)
  static final Color cyanGlow = neonBlue.withValues(alpha: 0.5);
  static final Color magentaGlow = neonPink.withValues(alpha: 0.4);

  // Extended Color Palette (role-inspired colors for UI variety)
  static const Color neonGreen = Color(0xFF78DFF2); // Turquoise variant
  static const Color purpleHaze = Color(0xFFE13CB2); // Pink-magenta variant
  static const Color ultraViolet = radiantPink; // Pink variant
  static const Color bloodOrange = Color(0xFFF24FAE); // Warm pink accent
  static const Color brightYellow = radiantTurquoise; // Turquoise variant

  // ── GLOW FACTORIES (Ported from Legacy) ──

  /// Multi-layer text/icon shadows for neon glow effect.
  /// [intensity] scales blur radius (default 1.0).
  static List<Shadow> textGlow(Color color, {double intensity = 1.0}) => [
        Shadow(color: color, blurRadius: 8 * intensity),
        Shadow(color: color.withValues(alpha: 0.8), blurRadius: 16 * intensity),
        Shadow(color: color.withValues(alpha: 0.5), blurRadius: 24 * intensity),
      ];

  /// Alias – icons use the same triple-shadow stack.
  static List<Shadow> iconGlow(Color color, {double intensity = 1.0}) =>
      textGlow(color, intensity: intensity);

  /// Multi-layer box shadow for rectangular/rounded containers.
  static List<BoxShadow> boxGlow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.6 * intensity),
          blurRadius: 12,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.4 * intensity),
          blurRadius: 24,
          spreadRadius: 4,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.2 * intensity),
          blurRadius: 32,
          spreadRadius: 0,
        ),
      ];

  /// Multi-layer circular glow (no spread to avoid square halo).
  static List<BoxShadow> circleGlow(Color color, {double intensity = 1.0}) => [
        BoxShadow(
          color: color.withValues(alpha: 0.6 * intensity),
          blurRadius: 10,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.35 * intensity),
          blurRadius: 20,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.18 * intensity),
          blurRadius: 32,
          spreadRadius: 0,
        ),
      ];

  /// Glassmorphism decoration factory – frosted-glass panel.
  static BoxDecoration glassmorphism({
    Color? color,
    double opacity = 0.1,
    Color borderColor = const Color(0x3DF0F0F0),
    double borderWidth = 1,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: (color ?? onSurface).withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: voidBlack.withValues(alpha: 0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // --- COMPATIBILITY MAPPINGS (Aliased to Neon Palette) ---
  static const Color offBlack = Color(0xFF1D2021);
  static const Color darkMetal = Color(0xFF282A2B);
  static const Color dead = Color(0xFF4A8190);

  // --- TEXT COLOR MAPPINGS ---
  static const Color textDim = coolGrey;
  static const Color textBright = onSurface;

  // --- THE SHIMMER PALETTE (Biorefraction/Prismatic Horror) ---
  static const Color deepSwamp = Color(0xFF0a1412);
  static const Color magentaShift = radiantPink;
  static const Color cyanRefract = radiantTurquoise;

  static const LinearGradient oilSlickGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1a1a1a), // Base dark
      Color(0xFFF72585), // Radiant pink
      Color(0xFF4CC9F0), // Radiant turquoise
      Color(0xFFF72585), // Radiant pink
      Color(0xFF1a1a1a), // Back to dark
    ],
    stops: [0.0, 0.4, 0.5, 0.6, 1.0],
  );

  static const Color electricCyan = neonBlue;
  static const Color hotPink = neonPink;
  static const Color cyan = neonBlue;
  static const Color magenta = neonPink;
  static const Color purple = neonPurple;
  static const Color matrixGreen = success;
  static const Color alertOrange = warning;

  static Color roleColorFromHex(String hexString) {
    try {
      final buffer = StringBuffer();
      final cleaned = hexString.replaceFirst('#', '');
      if (cleaned.length == 6) buffer.write('FF');
      buffer.write(cleaned);
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return electricCyan;
    }
  }

  static List<Color> roleShimmerStops(Color base) {
    final hsl = HSLColor.fromColor(base);

    Color tone(double hueShift, double saturationDelta, double lightnessDelta) {
      final hue = (hsl.hue + hueShift) % 360;
      final sat = (hsl.saturation + saturationDelta).clamp(0.35, 1.0);
      final light = (hsl.lightness + lightnessDelta).clamp(0.24, 0.76);
      return hsl
          .withHue(hue < 0 ? hue + 360 : hue)
          .withSaturation(sat)
          .withLightness(light)
          .toColor();
    }

    return [
      tone(-18, 0.06, -0.10),
      tone(0, 0.08, 0.04),
      tone(22, 0.06, 0.12),
      tone(-10, 0.04, -0.04),
    ];
  }

  static Color roleShimmerColor(Color base, double t) {
    final stops = roleShimmerStops(base);
    final a = Color.lerp(stops[0], stops[2], t) ?? base;
    final b = Color.lerp(stops[1], stops[3], t) ?? base;
    return Color.lerp(a, b, 0.5) ?? base;
  }

  /// Converts a hex color string (e.g. `#FF00FF` or `FF00FF`) to a [Color].
  /// Falls back to [electricCyan] on invalid input.
  static Color fromHex(String hexString) {
    return roleColorFromHex(hexString);
  }
}

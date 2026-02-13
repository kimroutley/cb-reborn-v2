import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system for Club Blackout.
///
/// Headers: Roboto Condensed (bold, impactful, attention-grabbing)
/// Body/Info: Roboto (clean, modern, highly readable)
class CBTypography {
  CBTypography._();

  // --- Base Text Themes ---
  static final TextTheme _robotoTheme = GoogleFonts.robotoTextTheme();

  /// Returns a full [TextTheme] with Roboto Condensed for headers and Roboto for body/info.
  /// Colors are left null so they can be controlled by the [ColorScheme].
  static final TextTheme textTheme = _robotoTheme.copyWith(
    // Display Styles (Roboto Condensed - Large Headers)
    displayLarge: _robotoTheme.displayLarge!.copyWith(
      fontFamily: 'Roboto Condensed',
      fontWeight: FontWeight.bold,
      letterSpacing: 1.0,
    ),
    displayMedium: _robotoTheme.displayMedium!.copyWith(
      fontFamily: 'Roboto Condensed',
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
    displaySmall: _robotoTheme.displaySmall!.copyWith(
      fontFamily: 'Roboto Condensed',
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
    ),

    // Headline Styles (Roboto Condensed - Headers)
    headlineLarge: _robotoTheme.headlineLarge!.copyWith(
      fontFamily: 'Roboto Condensed',
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
    ),
    headlineMedium: _robotoTheme.headlineMedium!.copyWith(
      fontFamily: 'Roboto Condensed',
      fontWeight: FontWeight.bold,
      letterSpacing: 0.25,
    ),
    headlineSmall: _robotoTheme.headlineSmall!.copyWith(
      fontFamily: 'Roboto Condensed',
      fontWeight: FontWeight.bold,
      letterSpacing: 0,
    ),

    // Title Styles (Roboto - Smaller Titles)
    titleLarge: _robotoTheme.titleLarge!.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleMedium: _robotoTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleSmall: _robotoTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),

    // Body Styles (Roboto - Information Text)
    bodyLarge: _robotoTheme.bodyLarge!.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.5,
    ),
    bodyMedium: _robotoTheme.bodyMedium!.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.25,
    ),
    bodySmall: _robotoTheme.bodySmall!.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.normal,
      letterSpacing: 0.4,
    ),

    // Label Styles (Roboto - UI Elements)
    labelLarge: _robotoTheme.labelLarge!.copyWith(
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
    labelMedium: _robotoTheme.labelMedium!.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 1.0,
    ),
    labelSmall: _robotoTheme.labelSmall!.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.8,
    ),
  );

  // ── SPECIAL STYLES ──

  /// Join code / big numbers (Roboto with tabular figures)
  static final TextStyle code = GoogleFonts.robotoMono(
    textStyle: _robotoTheme.displaySmall,
    fontWeight: FontWeight.w700,
    letterSpacing: 2,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Monospace body for logs/intel/system output.
  static final TextStyle monoSmall = GoogleFonts.robotoMono(
    textStyle: textTheme.bodySmall,
    letterSpacing: 0.3,
  );

  /// Timer display (Roboto Condensed for impact)
  static final TextStyle timer = _robotoTheme.displayLarge!.copyWith(
    fontFamily: 'Roboto Condensed',
    fontSize: 48,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Extra-small labels for dense HUD-like UI (8px default).
  static final TextStyle nano = textTheme.labelSmall!.copyWith(
    fontSize: 8,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w600,
  );

  /// Small labels for chips/badges (10px default).
  static final TextStyle micro = textTheme.labelSmall!.copyWith(
    fontSize: 10,
    letterSpacing: 1.1,
    fontWeight: FontWeight.w600,
  );

  /// Hero numbers/headlines (e.g., big counters).
  static final TextStyle heroNumber = textTheme.displayLarge!.copyWith(
    fontSize: 64,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  // ── CONVENIENCE ALIASES ──
  static final TextStyle label = textTheme.labelLarge!;
  static final TextStyle body = textTheme.bodyMedium!;
  static final TextStyle bodyBold =
      textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold);
  static final TextStyle caption = textTheme.bodySmall!;
  static final TextStyle h2 = textTheme.headlineMedium!;
  static final TextStyle h3 = textTheme.headlineSmall!;

  // Material-style static getters kept for compatibility with existing app code.
  static TextStyle get displayLarge => textTheme.displayLarge!;
  static TextStyle get displayMedium => textTheme.displayMedium!;
  static TextStyle get displaySmall => textTheme.displaySmall!;
  static TextStyle get headlineLarge => textTheme.headlineLarge!;
  static TextStyle get headlineMedium => textTheme.headlineMedium!;
  static TextStyle get headlineSmall => textTheme.headlineSmall!;
  static TextStyle get titleLarge => textTheme.titleLarge!;
  static TextStyle get titleMedium => textTheme.titleMedium!;
  static TextStyle get titleSmall => textTheme.titleSmall!;
  static TextStyle get bodyLarge => textTheme.bodyLarge!;
  static TextStyle get bodyMedium => textTheme.bodyMedium!;
  static TextStyle get bodySmall => textTheme.bodySmall!;
  static TextStyle get labelLarge => textTheme.labelLarge!;
  static TextStyle get labelMedium => textTheme.labelMedium!;
  static TextStyle get labelSmall => textTheme.labelSmall!;
}

import 'package:flutter/material.dart';

import 'colors.dart';
import 'layout.dart';
import 'typography.dart';

/// The central theme management class for Club Blackout.
///
/// Handles Material 3 configuration, shape definitions (rounded corners),
/// and color scheme generation.
class CBTheme {
  CBTheme._();

  static const String globalBackgroundAsset =
      'packages/cb_theme/assets/backgrounds/club_blackout_v2_game_background.png';

  /// The default seed color for the design system.
  /// Uses radiant turquoise (#4CC9F0) as the primary brand color.
  static const Color defaultSeedColor = CBColors.radiantTurquoise;

  /// Builds a [ColorScheme] from a seed color.
  ///
  /// Uses [Brightness.dark] by default as this is a dark-mode-first app.
  /// Pins the actual neon palette values to primary/secondary/tertiary
  /// instead of letting `fromSeed` desaturate them.
  static ColorScheme buildColorScheme(
    Color? seedColor, {
    Brightness brightness = Brightness.dark,
  }) {
    final seed = seedColor ?? defaultSeedColor;

    Color tintOnSurface(Color tint, {double alpha = 0.22}) {
      // Keep scheme colors opaque (Material 3 expects opaque tokens).
      return Color.alphaBlend(tint.withValues(alpha: alpha), CBColors.surface);
    }

    // Use fromSeed as a base to get all the container/on* variants,
    // then override the hero colours with our actual neon palette.
    final base = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    return base.copyWith(
      // ── Hero colours: role-inspired palette ──
      // Keep brand identity stable; seed only influences neutral tones.
      primary: CBColors.radiantTurquoise,
      onPrimary: CBColors.voidBlack,
      secondary: CBColors.neonPink,
      onSecondary: CBColors.voidBlack,
      tertiary: CBColors.neonPurple,
      onTertiary: CBColors.onSurface,

      // ── Containers: slightly dimmed neon for backgrounds ──
      primaryContainer: tintOnSurface(CBColors.radiantTurquoise),
      onPrimaryContainer: CBColors.radiantTurquoise,
      secondaryContainer: tintOnSurface(CBColors.neonPink),
      onSecondaryContainer: CBColors.neonPink,
      tertiaryContainer: tintOnSurface(CBColors.neonPurple),
      onTertiaryContainer: CBColors.neonPurple,

      // ── Surfaces: Void Black aesthetic ──
      surface: CBColors.surface,
      onSurface: CBColors.onSurface,
      surfaceContainer: CBColors.darkGrey,
      surfaceContainerHigh: CBColors.offBlack,
      surfaceContainerHighest: CBColors.darkMetal,
      surfaceContainerLow: CBColors.voidBlack,

      // ── Error ──
      error: CBColors.error,
      onError: CBColors.onSurface,
      errorContainer: tintOnSurface(CBColors.error, alpha: 0.18),
      onErrorContainer: CBColors.error,
    );
  }

  /// Builds the [ThemeData] using the provided [ColorScheme].
  static ThemeData buildTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: scheme.brightness,
      scaffoldBackgroundColor: CBColors.background, // Absolute black
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      // ── TYPOGRAPHY ──
      // Apply the color scheme to the text theme
      textTheme: CBTypography.textTheme.apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.primary,
        decorationColor: scheme.primary,
      ),

      // ── COMPONENT THEMES ──

      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: CBColors.transparent,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: CBTypography.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          letterSpacing: 2.0,
        ),
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CBRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
              vertical: CBSpace.x4, horizontal: CBSpace.x6),
          textStyle: CBTypography.textTheme.labelLarge!,
          elevation: 0, // M3 Flat
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CBRadius.md),
          ),
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          textStyle: CBTypography.textTheme.labelLarge!,
          padding: const EdgeInsets.symmetric(
              vertical: CBSpace.x4, horizontal: CBSpace.x6),
          elevation: 2,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CBRadius.md),
          ),
          side: BorderSide(color: scheme.outline, width: 1),
          foregroundColor: scheme.primary,
          textStyle: CBTypography.textTheme.labelLarge!,
          padding: const EdgeInsets.symmetric(
              vertical: CBSpace.x4, horizontal: CBSpace.x6),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CBRadius.sm),
          ),
          foregroundColor: scheme.primary,
          textStyle: CBTypography.textTheme.labelLarge!,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        // Slight translucency so the app-wide neon radiance can read through
        // without turning panels into a muddy double-overlay.
        color: scheme.surfaceContainerLow.withValues(alpha: 0.62),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            CBRadius.lg,
          ), // M3 Standard is 12, we use 24 for "Squircle" vibe
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // Navigation Bar (Bottom)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return CBTypography.textTheme.labelSmall!.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
            );
          }
          return CBTypography.textTheme.labelSmall!.copyWith(
            color: scheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.onSecondaryContainer);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
        hintStyle: CBTypography.textTheme.bodyLarge!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle:
            CBTypography.textTheme.bodySmall!.copyWith(color: scheme.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CBSpace.x5,
          vertical: CBSpace.x4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CBRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CBRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CBRadius.md),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CBRadius.md),
          borderSide: BorderSide(color: scheme.error, width: 1),
        ),
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CBRadius.dialog)),
        titleTextStyle: CBTypography.textTheme.headlineSmall?.copyWith(
          color: scheme.onSurface,
        ),
        contentTextStyle: CBTypography.textTheme.bodyMedium!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      // Tabs
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.5),
        indicatorColor: scheme.primary,
        dividerColor: scheme.outlineVariant.withValues(alpha: 0.35),
        labelStyle: CBTypography.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),

      // Drawers / Menus
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surfaceContainerLow.withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CBRadius.lg)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CBRadius.md),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        textStyle: CBTypography.textTheme.bodyMedium
            ?.copyWith(color: scheme.onSurface),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
          surfaceTintColor: const WidgetStatePropertyAll(CBColors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CBRadius.md),
              side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CBRadius.md),
            borderSide: BorderSide.none,
          ),
        ),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
          surfaceTintColor: const WidgetStatePropertyAll(CBColors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CBRadius.md),
              side: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ),

      // Bottom Sheets
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainer.withValues(alpha: 0.92),
        modalBackgroundColor: scheme.surfaceContainer.withValues(alpha: 0.92),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(CBRadius.dialog)),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedColor: scheme.primary.withValues(alpha: 0.16),
        disabledColor: scheme.surfaceContainerLow.withValues(alpha: 0.6),
        labelStyle: CBTypography.textTheme.labelSmall!.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.85),
          letterSpacing: 1.0,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: CBTypography.textTheme.labelSmall!.copyWith(
          color: scheme.onSurfaceVariant,
          letterSpacing: 1.0,
        ),
        side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.8), width: 1.5),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
            horizontal: CBSpace.x3, vertical: CBSpace.x2),
      ),

      // Switches
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.onSurfaceVariant.withValues(alpha: 0.85);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.35);
          }
          return scheme.surfaceContainerHighest.withValues(alpha: 0.85);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.55);
          }
          return scheme.outlineVariant.withValues(alpha: 0.7);
        }),
      ),

      // Sliders
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.outlineVariant.withValues(alpha: 0.35),
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.14),
        trackHeight: 4,
      ),

      // Tooltips
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(CBRadius.sm),
          border:
              Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        textStyle: CBTypography.textTheme.bodySmall?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.9),
        ),
        waitDuration: const Duration(milliseconds: 350),
        showDuration: const Duration(seconds: 3),
      ),

      // Scrollbars (Host desktop especially)
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(6),
        radius: const Radius.circular(999),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return scheme.primary.withValues(alpha: 0.6);
          }
          return scheme.onSurfaceVariant.withValues(alpha: 0.35);
        }),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // List Tiles
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: CBSpace.x4, vertical: CBSpace.x2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CBRadius.md)),
        tileColor: CBColors.transparent,
        selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.5),
        selectedColor: scheme.primary,
        textColor: scheme.onSurface,
        iconColor: scheme.onSurfaceVariant,
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CBRadius.md)),
      ),
    );
  }
}

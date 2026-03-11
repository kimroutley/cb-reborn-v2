import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';

/// Splash screen shown during app initialization.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    return CBPrismScaffold(
      title: '',
      showAppBar: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CBFadeSlide(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(CBRadius.lg),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.5), width: 1.5),
                  boxShadow: CBColors.boxGlow(scheme.primary, intensity: 0.25),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(CBRadius.md),
                  child: Image.asset(
                    'assets/images/neon_x_brand.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x8),
            CBFadeSlide(
              delay: const Duration(milliseconds: 150),
              child: Text(
                'CLUB BLACKOUT',
                style: textTheme.displayLarge!.copyWith(
                  shadows: CBColors.textGlow(scheme.primary, intensity: 0.6),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x2),
            CBFadeSlide(
              delay: const Duration(milliseconds: 300),
              child: Text(
                'REBORN',
                style: textTheme.labelLarge!.copyWith(
                  color: scheme.secondary,
                  shadows: CBColors.textGlow(scheme.secondary, intensity: 0.4),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8.0,
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x16),
            const CBFadeSlide(
              delay: Duration(milliseconds: 600),
              child: CBBreathingSpinner(size: 48),
            ),
          ],
        ),
      ),
    );
  }
}

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
      title: 'CLUB BLACKOUT',
      showAppBar: false,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder - replace with actual asset when available
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(CBRadius.lg),
                border: Border.all(color: scheme.primary, width: 1.5),
                boxShadow:
                    CBColors.boxGlow(scheme.primary, intensity: 0.25),
              ),
              child: Icon(
                Icons.nightlife,
                size: 60,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: CBSpace.x8),
            Text(
              'CLUB BLACKOUT',
              style: textTheme.displayLarge!.copyWith(
                shadows: CBColors.textGlow(scheme.primary, intensity: 0.6),
              ),
            ),
            const SizedBox(height: CBSpace.x2),
            Text(
              'REBORN',
              style: textTheme.labelLarge!.copyWith(
                color: scheme.secondary,
                shadows:
                    CBColors.textGlow(scheme.secondary, intensity: 0.4),
              ),
            ),
            const SizedBox(height: CBSpace.x12),
            const CBBreathingSpinner(size: 48),
          ],
        ),
      ),
    );
  }
}

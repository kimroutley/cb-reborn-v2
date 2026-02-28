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
            // Logo placeholder - replaced with Radiant Neon branding
            CBFadeSlide(
              child: Hero(
                tag: 'auth_icon',
                child: CBRoleAvatar(
                  color: scheme.secondary,
                  size: 100,
                  pulsing: true,
                  icon: Icons.nightlife_rounded,
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x8),
            CBFadeSlide(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'CLUB BLACKOUT',
                style: textTheme.displayLarge!.copyWith(
                  shadows: CBColors.textGlow(scheme.secondary, intensity: 0.8),
                  color: scheme.secondary,
                  letterSpacing: 4.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: CBSpace.x2),
            CBFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: CBBadge(
                text: 'REBORN',
                color: scheme.secondary,
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

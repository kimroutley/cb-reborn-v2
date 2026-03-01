import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';

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
            CBFadeSlide(
              child: Hero(
                tag: 'auth_icon',
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: scheme.secondary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.secondary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: CBColors.circleGlow(scheme.secondary, intensity: 0.4),
                  ),
                  child: Icon(
                    Icons.nightlife_rounded,
                    size: 80,
                    color: scheme.secondary,
                    shadows: CBColors.iconGlow(scheme.secondary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            CBFadeSlide(
              delay: const Duration(milliseconds: 200),
              child: Column(
                children: [
                  Text(
                    'CLUB BLACKOUT',
                    style: textTheme.displayMedium!.copyWith(
                      shadows: CBColors.textGlow(scheme.secondary, intensity: 0.8),
                      color: scheme.secondary,
                      letterSpacing: 6.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CBBadge(
                    text: 'REBORN',
                    color: scheme.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 64),
            CBFadeSlide(
              delay: const Duration(milliseconds: 400),
              child: const CBBreathingSpinner(size: 48),
            ),
          ],
        ),
      ),
    );
  }
}

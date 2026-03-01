import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class StartTransitionScreen extends StatelessWidget {
  const StartTransitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CBPrismScaffold(
      title: 'ENTERING CLUB...',
      showAppBar: false,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(CBSpace.x8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CBBreathingSpinner(size: 80), // Keep as is, looks good
                const SizedBox(height: CBSpace.x10),
                CBFadeSlide(
                  child: Text(
                    'INITIALIZING NEURAL LINK...',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      shadows: CBColors.textGlow(scheme.primary, intensity: 0.8),
                    ),
                  ),
                ),
                const SizedBox(height: CBSpace.x4),
                CBFadeSlide(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'ESTABLISHING SECURE CONNECTION TO THE HOST TERMINAL. PREPARE FOR ASSIGNMENT.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge!.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.8),
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: CBSpace.x10),
                CBFadeSlide(
                  delay: const Duration(milliseconds: 200),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(CBRadius.xs),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      backgroundColor: scheme.primary.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: CBSpace.x3),
                CBFadeSlide(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'ENCRYPTING DATA PACKETS...',
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.primary.withValues(alpha: 0.6),
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

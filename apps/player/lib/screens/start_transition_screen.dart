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
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CBBreathingLoader(size: 80),
                const SizedBox(height: 48),
                Text(
                  'INITIALIZING NEURAL LINK...',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    shadows: CBColors.textGlow(scheme.primary, intensity: 0.6),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Establishing secure connection to the host terminal. Prepare for assignment.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge!.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 48),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    backgroundColor: scheme.primary.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ENCRYPTING DATA PACKETS...',
                  textAlign: TextAlign.center,
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.primary.withValues(alpha: 0.6),
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
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

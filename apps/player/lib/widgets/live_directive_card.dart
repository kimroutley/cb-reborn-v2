import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import '../player_bridge.dart';

class LiveDirectiveCard extends StatelessWidget {
  final StepSnapshot? step;
  final String phase;

  const LiveDirectiveCard({
    super.key,
    required this.step,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final title = step?.title ?? phase.toUpperCase();
    final text = step?.readAloudText ?? 'AWAITING HOST INSTRUCTION.';

    return CBFadeSlide(
      child: CBGlassTile(
        borderColor: scheme.primary.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(CBSpace.x5),
        isPrismatic: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(CBSpace.x2),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.emergency_rounded, color: scheme.primary, size: 18),
                ),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: Text(
                    'LIVE DIRECTIVE',
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CBSpace.x4),
            Text(
              title.toUpperCase(),
              style: textTheme.labelLarge!.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                shadows: CBColors.textGlow(scheme.primary, intensity: 0.3),
              ),
            ),
            const SizedBox(height: CBSpace.x3),
            Container(
              padding: const EdgeInsets.all(CBSpace.x4),
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(CBRadius.sm),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.1)),
              ),
              child: Text(
                text.toUpperCase(),
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

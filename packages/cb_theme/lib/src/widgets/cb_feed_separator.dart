import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

/// A sleek, centered "Phase/Time" separator for the feed.
/// M3-compliant: uses [CBRadius], [CBSpace], and theme surface tokens.
class CBFeedSeparator extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isCinematic;

  const CBFeedSeparator({
    super.key,
    required this.label,
    this.color,
    this.isCinematic = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = color ?? scheme.outlineVariant;

    if (isCinematic) {
      return Semantics(
        label: label,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: CBSpace.x8,
            horizontal: CBSpace.x4,
          ),
          child: CBGlassTile(
            isPrismatic: true,
            padding: const EdgeInsets.symmetric(
              vertical: CBSpace.x3,
              horizontal: CBSpace.x4,
            ),
            borderRadius: BorderRadius.circular(CBRadius.xs),
            child: Center(
              child: Text(
                label.toUpperCase(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  shadows: CBColors.textGlow(accent, intensity: 0.6),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: CBSpace.x6),
        child: Row(
          children: [
            Expanded(
              child: Divider(
                color: accent.withValues(alpha: 0.2),
                endIndent: CBSpace.x4,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: CBSpace.x3,
                vertical: CBSpace.x1,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(CBRadius.sm),
                border: Border.all(color: accent.withValues(alpha: 0.3)),
              ),
              child: Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 10,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: accent.withValues(alpha: 0.2),
                indent: CBSpace.x4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

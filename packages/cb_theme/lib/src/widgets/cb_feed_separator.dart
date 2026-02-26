import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

/// A sleek, centered "Phase/Time" separator for the feed.
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: CBGlassTile(
          isPrismatic: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          borderRadius: BorderRadius.circular(8),
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
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: accent.withValues(alpha: 0.2), endIndent: 16),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
            child: Divider(color: accent.withValues(alpha: 0.2), indent: 16),
          ),
        ],
      ),
    );
  }
}

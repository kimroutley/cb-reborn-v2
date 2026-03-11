import 'package:flutter/material.dart';

/// A sleek, centered "Phase/Time" separator for the feed.
class CBFeedSeparator extends StatelessWidget {
  final String label;
  final Color? color;

  const CBFeedSeparator({
    super.key,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = color ?? scheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          label, // removed toUpperCase to allow fine control (e.g. Saturday 28...)
          style: theme.textTheme.labelSmall?.copyWith(
            color: accent.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

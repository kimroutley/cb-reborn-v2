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

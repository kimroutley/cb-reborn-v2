import 'package:flutter/material.dart';

/// Compact label chip (e.g., role badge, status tag) with neon styling.
class CBBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final IconData? icon;

  const CBBadge({
    super.key,
    required this.text,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: badgeColor,
              shadows: [
                Shadow(color: badgeColor, blurRadius: 4),
              ],
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w800,
              fontSize: 10,
              letterSpacing: 1.0,
              shadows: [
                Shadow(color: badgeColor.withValues(alpha: 0.6), blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

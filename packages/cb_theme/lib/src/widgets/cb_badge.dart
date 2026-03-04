import 'package:flutter/material.dart';

/// Compact label chip (e.g., role badge, status tag).
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: badgeColor),
            const SizedBox(width: 6),
          ],
          Text(
            text.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(color: badgeColor),
          ),
        ],
      ),
    );
  }
}

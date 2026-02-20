import 'package:flutter/material.dart';
import 'cb_badge.dart';

/// Section header bar with label + optional count badge.
class CBSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color? color;
  final IconData? icon;

  const CBSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.titleMedium!.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                shadows: [
                  Shadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                  )
                ],
              ),
            ),
          ),
          if (count != null)
            CBBadge(text: count.toString(), color: accentColor),
        ],
      ),
    );
  }
}

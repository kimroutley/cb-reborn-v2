import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A lightweight, neon-friendly filter chip (no avatar) for small toggles.
class CBFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;
  final IconData? icon;
  final bool dense;

  const CBFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
    this.icon,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = color ?? scheme.primary;

    final bg = selected
        ? accent.withValues(alpha: 0.16)
        : scheme.surfaceContainerLow.withValues(alpha: 0.9);
    final border = selected
        ? accent.withValues(alpha: 0.9)
        : scheme.outlineVariant.withValues(alpha: 0.7);
    final fg = selected ? accent : scheme.onSurface.withValues(alpha: 0.8);

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onSelected();
        },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: dense
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 7)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border, width: 1.5),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg,
                  letterSpacing: 1.0,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

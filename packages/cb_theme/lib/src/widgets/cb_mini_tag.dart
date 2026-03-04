import 'package:cb_theme/src/colors.dart';
import 'package:cb_theme/src/typography.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

import 'package:cb_theme/src/layout.dart';

/// Tiny colored tag for status indicators with a neon glow and glassmorphism.
class CBMiniTag extends StatelessWidget {
  final String text;
  final Color? color;
  final String? tooltip;
  final bool isOutline;
  final Color? textColor;
  final Color? outlineColor;

  const CBMiniTag({
    super.key,
    required this.text,
    this.color,
    this.tooltip,
    this.isOutline = false,
    this.textColor,
    this.outlineColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tagColor = color ?? scheme.primary;
    final effectiveTextColor =
        textColor ?? (isOutline ? tagColor : scheme.onSurface);
    final effectiveOutlineColor =
        outlineColor ?? tagColor.withValues(alpha: 0.6);

    final tag = ClipRRect(
      borderRadius: BorderRadius.circular(CBRadius.xs),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isOutline
                ? CBColors.transparent
                : tagColor.withValues(alpha: 0.15),
            border: Border.all(color: effectiveOutlineColor, width: 1.2),
            borderRadius: BorderRadius.circular(CBRadius.xs),
            boxShadow: !isOutline
                ? [
                    BoxShadow(
                      color: tagColor.withValues(alpha: 0.1),
                      blurRadius: 4,
                    )
                  ]
                : null,
          ),
          child: Text(
            text.toUpperCase(),
            style: CBTypography.nano.copyWith(
              color: effectiveTextColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              fontSize: 8,
              shadows: !isOutline
                  ? CBColors.textGlow(tagColor, intensity: 0.3)
                  : null,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null && tooltip!.isNotEmpty) {
      return Tooltip(
        message: tooltip!,
        child: tag,
      );
    }
    return tag;
  }
}

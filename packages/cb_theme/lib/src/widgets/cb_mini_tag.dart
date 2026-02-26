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

  const CBMiniTag({
    super.key,
    required this.text,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tagColor = color ?? CBColors.neonPurple;

    final tag = ClipRRect(
      borderRadius: BorderRadius.circular(CBRadius.xs),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tagColor.withValues(alpha: 0.4),
                tagColor.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(color: tagColor.withValues(alpha: 0.7), width: 0.8),
            borderRadius: BorderRadius.circular(CBRadius.xs),
            boxShadow: [
              BoxShadow(
                color: tagColor.withValues(alpha: 0.25),
                blurRadius: 5,
                spreadRadius: 3,
              )
            ],
          ),
          child: Text(
            text,
            style: CBTypography.nano.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              shadows: CBColors.textGlow(tagColor, intensity: 0.4),
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

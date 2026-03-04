import 'package:flutter/material.dart';
import 'package:cb_theme/cb_theme.dart';
import 'dart:ui';

/// Tiny colored tag for roster status indicators (Rumour, Alibi, Creep, Clinger).
class MiniTag extends StatelessWidget {
  final String text;
  final Color color;
  final String tooltip;

  const MiniTag(
      {super.key, required this.text, required this.color, this.tooltip = ''});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip.toUpperCase(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CBRadius.xs),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1.2),
              borderRadius: BorderRadius.circular(CBRadius.xs),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 4,
                )
              ],
            ),
            child: Text(
              text.toUpperCase(),
              style: CBTypography.nano.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                shadows: CBColors.textGlow(color, intensity: 0.3),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

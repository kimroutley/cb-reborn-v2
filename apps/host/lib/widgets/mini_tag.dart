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
      message: tooltip,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CBRadius.xs),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.4),
                  color.withValues(alpha: 0.1),
                ],
              ),
              border:
                  Border.all(color: color.withValues(alpha: 0.7), width: 0.6),
              borderRadius: BorderRadius.circular(CBRadius.xs),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 3,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Text(
              text,
              style: CBTypography.nano.copyWith(color: scheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}

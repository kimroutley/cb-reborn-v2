import 'dart:ui';

import 'package:flutter/material.dart';

/// A glowing panel for grouping related content.
class CBPanel extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const CBPanel({
    super.key,
    required this.child,
    this.borderColor,
    this.borderWidth = 1,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = borderColor ?? theme.colorScheme.primary;
    final panelRadius = BorderRadius.circular(16);

    return Container(
      width: double.infinity,
      margin: margin,
      child: ClipRRect(
        borderRadius: panelRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: (theme.cardTheme.color ?? scheme.surfaceContainerLow)
                  .withValues(alpha: 0.44),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  scheme.onSurface.withValues(alpha: 0.06),
                  scheme.primary.withValues(alpha: 0.11),
                  scheme.secondary.withValues(alpha: 0.09),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.22, 0.56, 1.0],
              ),
              borderRadius: panelRadius,
              border: Border.all(
                  color: color.withValues(alpha: 0.54), width: borderWidth),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.1),
                  blurRadius: 12,
                ),
                BoxShadow(
                  color: scheme.secondary.withValues(alpha: 0.08),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

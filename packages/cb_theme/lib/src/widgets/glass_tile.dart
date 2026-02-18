import 'dart:ui';

import 'package:flutter/material.dart';

/// A versatile glassmorphism tile with an optional prismatic/oilslick effect.
class CBGlassTile extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isPrismatic;
  final bool isSelected;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final BorderRadius? borderRadius;
  final Color? borderColor;

  const CBGlassTile({
    super.key,
    required this.child,
    this.onTap,
    this.isPrismatic = false,
    this.isSelected = false,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius,
    this.borderColor,
  });

  @override
  State<CBGlassTile> createState() => _CBGlassTileState();
}

class _CBGlassTileState extends State<CBGlassTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    if (widget.isPrismatic) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant CBGlassTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPrismatic != oldWidget.isPrismatic) {
      if (widget.isPrismatic) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(16);
    final effectiveBorderColor = widget.isSelected
        ? scheme.primary
        : (widget.borderColor ?? scheme.onSurface.withValues(alpha: 0.2));

    return Container(
      margin: widget.margin,
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: effectiveRadius,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final baseDecoration = BoxDecoration(
                    color: widget.isSelected
                        ? scheme.primary.withValues(alpha: 0.25)
                        : scheme.surface.withValues(alpha: 0.15),
                    borderRadius: effectiveRadius,
                    border: Border.all(
                      color: effectiveBorderColor,
                      width: widget.isSelected ? 2.5 : 1.5,
                    ),
                  );

                  if (!widget.isPrismatic) {
                    return Container(
                      padding: widget.padding,
                      decoration: baseDecoration,
                      child: child,
                    );
                  }

                  final shimmerDecoration = BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0.4),
                        scheme.secondary.withValues(alpha: 0.4),
                        scheme.primary.withValues(alpha: 0.4),
                      ],
                      transform: GradientRotation(
                        _controller.value * 2 * 3.14159,
                      ),
                    ),
                    borderRadius: effectiveRadius,
                    border: Border.all(
                      color: scheme.tertiary.withValues(alpha: 0.5),
                      width: widget.isSelected ? 2.5 : 1.5,
                    ),
                  );

                  final decoration = BoxDecoration.lerp(
                    baseDecoration,
                    shimmerDecoration,
                    _controller.value,
                  );

                  return Container(
                    padding: widget.padding,
                    decoration: decoration,
                    child: child,
                  );
                },
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

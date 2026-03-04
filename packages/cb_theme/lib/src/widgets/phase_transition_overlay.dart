import 'dart:async';

import 'package:flutter/material.dart';

import '../colors.dart';
import '../layout.dart';
import 'cb_fade_slide.dart';
import 'glass_tile.dart';

/// Full-screen cinematic overlay for phase changes (e.g. "NIGHT 1 FALLS", "VICTORY").
/// Uses [CBFadeSlide] and scale animation per [STYLE_GUIDE.md]. Tap or auto-dismiss.
class CBPhaseTransitionOverlay extends StatefulWidget {
  final String label;
  final Color? color;
  final Duration displayDuration;
  final VoidCallback? onDismiss;

  const CBPhaseTransitionOverlay({
    super.key,
    required this.label,
    this.color,
    this.displayDuration = const Duration(milliseconds: 2200),
    this.onDismiss,
  });

  @override
  State<CBPhaseTransitionOverlay> createState() =>
      _CBPhaseTransitionOverlayState();
}

class _CBPhaseTransitionOverlayState extends State<CBPhaseTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
    _timer = Timer(widget.displayDuration, () {
      if (!mounted) return;
      _dismiss();
    });
  }

  void _dismiss() {
    _timer?.cancel();
    widget.onDismiss?.call();
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = widget.color ?? scheme.primary;

    return Material(
      color: CBColors.transparent,
      child: GestureDetector(
        onTap: _dismiss,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: CBColors.voidBlack.withValues(alpha: 0.88),
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: child,
                  ),
                );
              },
              child: CBFadeSlide(
                duration: const Duration(milliseconds: 400),
                beginOffset: const Offset(0, 0.03),
                child: CBGlassTile(
                  isPrismatic: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: CBSpace.x8,
                    vertical: CBSpace.x6,
                  ),
                  borderColor: accent.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(CBRadius.sm),
                  child: Text(
                    widget.label.toUpperCase(),
                    style: textTheme.headlineMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.0,
                      shadows: CBColors.textGlow(accent, intensity: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

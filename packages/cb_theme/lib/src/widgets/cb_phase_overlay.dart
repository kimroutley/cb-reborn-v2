import 'package:flutter/material.dart';
import '../colors.dart';

/// Animated overlay that shifts visual atmosphere between Day and Night phases.
///
/// Night: deeper darkness, subtle scanline texture, cool-tinted neon glow.
/// Day: lighter contrast, warmer tones, no scanlines.
///
/// Wrap the game screen body with this widget and toggle [isNight].
class CBPhaseOverlay extends StatelessWidget {
  final Widget child;
  final bool isNight;
  final Duration transitionDuration;

  const CBPhaseOverlay({
    super.key,
    required this.child,
    this.isNight = false,
    this.transitionDuration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final nightTint = scheme.secondary.withValues(alpha: 0.06);
    final dayTint = scheme.primary.withValues(alpha: 0.02);

    return Stack(
      children: [
        child,
        // Phase-aware color tint
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: transitionDuration,
              curve: Curves.easeInOutCubic,
              color: isNight
                  ? CBColors.voidBlack.withValues(alpha: 0.18)
                  : CBColors.transparent,
            ),
          ),
        ),
        // Neon accent tint
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: transitionDuration,
              curve: Curves.easeInOutCubic,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    isNight ? nightTint : dayTint,
                    CBColors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Scanline effect (night only)
        if (isNight)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedOpacity(
                duration: transitionDuration,
                opacity: isNight ? 1.0 : 0.0,
                child: const _ScanlineTexture(),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScanlineTexture extends StatelessWidget {
  const _ScanlineTexture();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScanlinePainter(
        color: Colors.black.withValues(alpha: 0.04),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final Color color;

  _ScanlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 4.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 1),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter old) => old.color != color;
}

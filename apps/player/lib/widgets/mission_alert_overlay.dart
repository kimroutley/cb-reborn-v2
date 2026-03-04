
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

/// Full-screen "Neural Link" overlay that triggers when a player's turn begins.
/// Shows expanding concentric rings + scan lines that fade to reveal the action UI.
Future<void> showMissionAlertOverlay({
  required BuildContext context,
  required String stepTitle,
  required Color accentColor,
}) {
  HapticService.eyesOpen();

  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, __, ___) => _MissionAlertContent(
      stepTitle: stepTitle,
      accentColor: accentColor,
    ),
  );
}

class _MissionAlertContent extends StatefulWidget {
  final String stepTitle;
  final Color accentColor;

  const _MissionAlertContent({
    required this.stepTitle,
    required this.accentColor,
  });

  @override
  State<_MissionAlertContent> createState() => _MissionAlertContentState();
}

class _MissionAlertContentState extends State<_MissionAlertContent>
    with TickerProviderStateMixin {
  late final AnimationController _ringController;
  late final AnimationController _fadeController;
  late final Animation<double> _ringExpand;
  late final Animation<double> _textFade;
  late final Animation<double> _dismiss;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _ringExpand = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );
    _textFade = CurvedAnimation(
      parent: _ringController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
    );
    _dismiss = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInCubic,
    );

    _ringController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        _fadeController.forward().then((_) {
          if (mounted) Navigator.of(context).pop();
        });
      });
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_ringExpand, _dismiss]),
      builder: (context, _) {
        final opacity = 1.0 - _dismiss.value;
        return Opacity(
          opacity: opacity,
          child: Material(
            color: scheme.surface.withValues(alpha: 0.85 * opacity),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: _ringExpand.value,
                        color: widget.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        Text(
                          'NEURAL LINK ESTABLISHED',
                          style: textTheme.labelLarge?.copyWith(
                            color: widget.accentColor,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.0,
                            shadows: CBColors.textGlow(widget.accentColor,
                                intensity: 0.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.stepTitle.toUpperCase(),
                          style: textTheme.headlineSmall?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'AWAITING YOUR INPUT',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final ringProgress = (progress - (i * 0.15)).clamp(0.0, 1.0);
      if (ringProgress <= 0) continue;

      final radius = maxRadius * ringProgress;
      final alpha = (1.0 - ringProgress) * 0.6;

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 - (ringProgress * 1.2);

      canvas.drawCircle(center, radius, paint);
    }

    // Scan line cross-hairs
    if (progress > 0.2) {
      final lineAlpha = ((progress - 0.2) / 0.3).clamp(0.0, 0.4);
      final linePaint = Paint()
        ..color = color.withValues(alpha: lineAlpha)
        ..strokeWidth = 0.5;

      final extent = maxRadius * progress;
      canvas.drawLine(
        Offset(center.dx - extent, center.dy),
        Offset(center.dx + extent, center.dy),
        linePaint,
      );
      canvas.drawLine(
        Offset(center.dx, center.dy - extent),
        Offset(center.dx, center.dy + extent),
        linePaint,
      );

      // Corner brackets
      if (progress > 0.5) {
        final bracketAlpha = ((progress - 0.5) * 2).clamp(0.0, 0.5);
        final bracketPaint = Paint()
          ..color = color.withValues(alpha: bracketAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        final bracketSize = maxRadius * 0.3;
        final offset = maxRadius * 0.6;

        for (final corner in [
          Offset(center.dx - offset, center.dy - offset),
          Offset(center.dx + offset, center.dy - offset),
          Offset(center.dx - offset, center.dy + offset),
          Offset(center.dx + offset, center.dy + offset),
        ]) {
          final dx = corner.dx < center.dx ? 1.0 : -1.0;
          final dy = corner.dy < center.dy ? 1.0 : -1.0;
          canvas.drawLine(
            corner,
            Offset(corner.dx + bracketSize * dx, corner.dy),
            bracketPaint,
          );
          canvas.drawLine(
            corner,
            Offset(corner.dx, corner.dy + bracketSize * dy),
            bracketPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

import 'dart:math';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class CBRotaryDial extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double minValue;
  final double maxValue;
  final String label;
  final Color color;

  const CBRotaryDial({
    super.key,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 100,
    this.label = '',
    this.color = CBColors.radiantTurquoise,
  });

  @override
  State<CBRotaryDial> createState() => _CBRotaryDialState();
}

class _CBRotaryDialState extends State<CBRotaryDial> {
  double _currentAngle = 0;

  @override
  void initState() {
    super.initState();
    _currentAngle = _valueToAngle(widget.value);
  }

  @override
  void didUpdateWidget(covariant CBRotaryDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _currentAngle = _valueToAngle(widget.value);
    }
  }

  double _valueToAngle(double value) {
    final double normalizedValue =
        (value - widget.minValue) / (widget.maxValue - widget.minValue);
    return -pi / 2 + (normalizedValue * 2 * pi);
  }

  double _angleToValue(double angle) {
    final double normalizedAngle = (angle + pi / 2) / (2 * pi);
    return widget.minValue +
        (normalizedAngle * (widget.maxValue - widget.minValue));
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final position = details.localPosition;
    final angle = atan2(position.dy - center.dy, position.dx - center.dx);

    setState(() {
      _currentAngle = angle;
      final value = _angleToValue(_currentAngle);
      widget.onChanged(value.clamp(widget.minValue, widget.maxValue));
      HapticService.selection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size.square(constraints.maxWidth);
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final textTheme = theme.textTheme;

      final labelStyle = textTheme.labelSmall?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.4),
        fontWeight: FontWeight.w900,
        letterSpacing: 2.0,
        fontSize: 10,
      );
      final valueStyle = textTheme.displayLarge?.copyWith(
        color: scheme.onSurface,
        fontWeight: FontWeight.w900,
        fontFamily: 'RobotoMono',
        fontSize: 48,
        shadows: CBColors.textGlow(widget.color, intensity: 0.5),
      );
      final maxStyle = textTheme.labelSmall?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.3),
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        fontFamily: 'RobotoMono',
      );

      return GestureDetector(
        onPanUpdate: (details) => _handlePanUpdate(details, size),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.05),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: CustomPaint(
            size: size,
            painter: _DialPainter(
              angle: _currentAngle,
              label: widget.label,
              color: widget.color,
              value: widget.value,
              maxValue: widget.maxValue,
              onSurface: scheme.onSurface,
              outline: scheme.outlineVariant.withValues(alpha: 0.2),
              labelStyle: labelStyle ?? const TextStyle(),
              valueStyle: valueStyle ?? const TextStyle(),
              maxStyle: maxStyle ?? const TextStyle(),
            ),
          ),
        ),
      );
    });
  }
}

class _DialPainter extends CustomPainter {
  final double angle;
  final String label;
  final Color color;
  final double value;
  final double maxValue;
  final Color onSurface;
  final Color outline;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final TextStyle maxStyle;

  _DialPainter({
    required this.angle,
    required this.label,
    required this.color,
    required this.value,
    required this.maxValue,
    required this.onSurface,
    required this.outline,
    required this.labelStyle,
    required this.valueStyle,
    required this.maxStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.85;
    const strokeWidth = 10.0;

    // Background track
    final trackPaint = Paint()
      ..color = outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Active track
    final activePaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.1), color],
        startAngle: -pi / 2,
        endAngle: angle,
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      angle + pi / 2,
      false,
      activePaint,
    );

    // Glow for active track
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      angle + pi / 2,
      false,
      glowPaint,
    );

    // Thumb (handle)
    final thumbOffset =
        center + Offset(cos(angle) * radius, sin(angle) * radius);

    final thumbShadowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    canvas.drawCircle(thumbOffset, 14, thumbShadowPaint);

    final thumbOuterPaint = Paint()..color = onSurface;
    canvas.drawCircle(thumbOffset, 12, thumbOuterPaint);

    final thumbInnerPaint = Paint()..color = color;
    canvas.drawCircle(thumbOffset, 8, thumbInnerPaint);

    // Central text
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Label
    textPainter.text = TextSpan(text: label.toUpperCase(), style: labelStyle);
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, 45));

    // Value
    textPainter.text = TextSpan(text: value.toStringAsFixed(0), style: valueStyle);
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));

    // Max
    textPainter.text = TextSpan(text: '/ ${maxValue.toStringAsFixed(0)}', style: maxStyle);
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(canvas, center + Offset(-textPainter.width / 2, 35));
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.label != label ||
        oldDelegate.color != color ||
        oldDelegate.value != value;
  }
}

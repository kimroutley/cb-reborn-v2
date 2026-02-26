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
    this.color = CBColors.electricCyan,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size.square(constraints.maxWidth);
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        final labelStyle = CBTypography.micro.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
        );
        final valueStyle = CBTypography.heroNumber.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
          shadows: CBColors.textGlow(widget.color, intensity: 0.5),
        );
        final maxStyle = theme.textTheme.labelLarge!.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
          fontWeight: FontWeight.w700,
        );

        return GestureDetector(
          onPanUpdate: (details) => _handlePanUpdate(details, size),
          child: CustomPaint(
            size: size,
            painter: _DialPainter(
              angle: _currentAngle,
              label: widget.label,
              color: widget.color,
              value: widget.value,
              maxValue: widget.maxValue,
              onSurface: scheme.onSurface,
              outline: scheme.outlineVariant.withValues(alpha: 0.55),
              labelStyle: labelStyle,
              valueStyle: valueStyle,
              maxStyle: maxStyle,
            ),
          ),
        );
      },
    );
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
    final radius = size.width / 2 * 0.8;
    const strokeWidth = 8.0;

    // Background track
    final trackPaint = Paint()
      ..color = outline.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Active track
    final activePaint = Paint()
      ..shader = SweepGradient(
        colors: [color.withValues(alpha: 0.2), color],
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

    // Thumb (handle)
    final thumbOffset =
        center + Offset(cos(angle) * radius, sin(angle) * radius);
    final thumbPaint = Paint()..color = onSurface;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);

    canvas.drawCircle(thumbOffset, 12, glowPaint);
    canvas.drawCircle(thumbOffset, 10, thumbPaint);
    canvas.drawCircle(
      thumbOffset,
      8,
      Paint()..color = color.withValues(alpha: 0.8),
    );

    // Central Label
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Label text
    textPainter.text = TextSpan(text: label.toUpperCase(), style: labelStyle);
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, 20));

    // Value text
    textPainter.text = TextSpan(
      text: value.toStringAsFixed(0),
      style: valueStyle,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2 - 10),
    );

    // Max value text
    textPainter.text = TextSpan(
      text: '/ ${maxValue.toStringAsFixed(0)}',
      style: maxStyle,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    textPainter.paint(canvas, center + Offset(-textPainter.width / 2, 25));
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.label != label ||
        oldDelegate.color != color ||
        oldDelegate.value != value;
  }
}

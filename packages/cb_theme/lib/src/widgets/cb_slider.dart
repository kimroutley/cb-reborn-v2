import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Neon-styled slider wrapper (thin track + clean thumb + subtle overlay).
class CBSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final double min;
  final double max;
  final int? divisions;
  final Color? color;

  const CBSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: accent,
        inactiveTrackColor: scheme.outlineVariant.withValues(alpha: 0.35),
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.14),
        trackHeight: 4,
      ),
      child: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        onChangeEnd: (v) {
          HapticFeedback.lightImpact();
          onChangeEnd?.call(v);
        },
      ),
    );
  }
}

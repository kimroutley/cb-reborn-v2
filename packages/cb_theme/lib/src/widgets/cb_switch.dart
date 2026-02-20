import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Neon-styled switch with consistent track/thumb treatment + haptics.
class CBSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? color;

  const CBSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = color ?? scheme.primary;

    return Switch(
      value: value,
      onChanged: onChanged == null
          ? null
          : (v) {
              HapticFeedback.selectionClick();
              onChanged!(v);
            },
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return accent;
        return scheme.onSurfaceVariant.withValues(alpha: 0.85);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent.withValues(alpha: 0.35);
        }
        return scheme.surfaceContainerHighest.withValues(alpha: 0.85);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return accent.withValues(alpha: 0.55);
        }
        return scheme.outlineVariant.withValues(alpha: 0.7);
      }),
    );
  }
}

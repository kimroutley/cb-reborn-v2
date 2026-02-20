import 'package:flutter/material.dart';

/// Standard bottom-sheet handle (used when you need a handle inside a custom sheet,
/// e.g. a [DraggableScrollableSheet]).
class CBBottomSheetHandle extends StatelessWidget {
  final EdgeInsets margin;

  const CBBottomSheetHandle({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 44,
        height: 5,
        margin: margin,
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
    );
  }
}

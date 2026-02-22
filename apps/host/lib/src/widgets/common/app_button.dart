// ... existing code ...
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    this.onPressed,
    this.isExpanded = false,
    this.height,
    this.width,
    this.child,
    this.text,
    this.icon,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool isExpanded;
  final double? height;
  final double? width;
  final Widget? child;
  final String? text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      width: width,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: onPressed != null
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.12),
          foregroundColor: onPressed != null
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface.withValues(alpha: 0.38),
          padding: const EdgeInsets.all(16),
        ),
        child: DefaultTextStyle(
          style: theme.textTheme.labelLarge!.copyWith(
            color: onPressed != null
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withValues(alpha: 0.38),
          ),
          child: child ??
              (text != null
                  ? (isExpanded ? Center(child: Text(text!)) : Text(text!))
                  : const SizedBox.shrink()),
        ),
      ),
    );
  }
}

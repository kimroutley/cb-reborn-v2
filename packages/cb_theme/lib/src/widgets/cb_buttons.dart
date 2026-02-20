import 'package:flutter/material.dart';
import '../../cb_theme.dart';

/// Full-width primary action button. Inherits all styling from the central theme.
class CBPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CBPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.fullWidth = true,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor;
    final fg = foregroundColor ??
        (bg == null
            ? null
            : (ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
                ? theme.colorScheme.onSurface
                : CBColors.voidBlack));

    final button = FilledButton(
      style: (bg != null || fg != null)
          ? FilledButton.styleFrom(backgroundColor: bg, foregroundColor: fg)
          : null,
      onPressed: onPressed != null
          ? () {
              HapticService.light();
              onPressed!();
            }
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label.toUpperCase()),
        ],
      ),
    );

    if (!fullWidth) return button;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return button;
        }
        return SizedBox(width: double.infinity, child: button);
      },
    );
  }
}

/// Outlined ghost button. Inherits styling from the central theme,
/// but can be customized with a specific color.
class CBGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color; // Retained for accent customization
  final bool fullWidth;
  final IconData? icon;

  const CBGhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.fullWidth = true,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    final button = OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: buttonColor, width: 2),
        foregroundColor: buttonColor,
      ),
      onPressed: onPressed != null
          ? () {
              HapticService.light();
              onPressed!();
            }
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelLarge,
          ),
        ],
      ),
    );

    if (!fullWidth) return button;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return button;
        }
        return SizedBox(width: double.infinity, child: button);
      },
    );
  }
}

class CBTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final IconData? icon;

  const CBTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonColor = color ?? theme.colorScheme.primary;

    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: buttonColor,
      ),
      onPressed: onPressed != null
          ? () {
              HapticService.light();
              onPressed!();
            }
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

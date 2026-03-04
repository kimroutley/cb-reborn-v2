import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

Future<String?> showStartSessionDialog(BuildContext context) async {
  final controller = TextEditingController();
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final textTheme = theme.textTheme;

  return showThemedDialog<String>(
    context: context,
    accentColor: scheme.tertiary,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'INITIATE GAMES NIGHT',
          style: textTheme.headlineSmall!.copyWith(
            color: scheme.tertiary,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w900,
            shadows: CBColors.textGlow(scheme.tertiary, intensity: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'CONNECT MULTIPLE MISSION CYCLES FOR A COMPREHENSIVE RECAP.',
          style: textTheme.labelSmall!.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
            fontSize: 9,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        CBTextField(
          controller: controller,
          autofocus: true,
          hintText: 'E.G. NEON NOIR PROTOCOL',
          monospace: true,
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: CBGhostButton(
                label: 'ABORT',
                onPressed: () {
                  HapticService.light();
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CBPrimaryButton(
                label: 'INITIALIZE',
                backgroundColor: scheme.tertiary,
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    HapticService.heavy();
                    Navigator.pop(context, controller.text.trim());
                  }
                },
              ),
            ),
          ],
        )
      ],
    ),
  );
}

Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'CONFIRM',
  String cancelLabel = 'ABORT',
  Color? confirmColor,
}) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final textTheme = theme.textTheme;
  final accent = confirmColor ?? scheme.secondary;

  return showThemedDialog<bool>(
    context: context,
    accentColor: accent,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title.toUpperCase(),
          style: textTheme.headlineSmall!.copyWith(
            color: accent,
            letterSpacing: 2.0,
            fontWeight: FontWeight.w900,
            shadows: CBColors.textGlow(accent, intensity: 0.4),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Text(
          content.toUpperCase(),
          style: textTheme.bodyMedium!.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.8),
            height: 1.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            Expanded(
              child: CBGhostButton(
                label: cancelLabel,
                onPressed: () {
                  HapticService.light();
                  Navigator.pop(context, false);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CBPrimaryButton(
                label: confirmLabel,
                backgroundColor: accent,
                onPressed: () {
                  HapticService.medium();
                  Navigator.pop(context, true);
                },
              ),
            ),
          ],
        )
      ],
    ),
  );
}

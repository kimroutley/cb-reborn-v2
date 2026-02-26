import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

Future<String?> showStartSessionDialog(BuildContext context) async {
  final controller = TextEditingController();
  final scheme = Theme.of(context).colorScheme;
  return showThemedDialog<String>(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'START GAMES NIGHT',
          style: CBTypography.headlineSmall.copyWith(
            color: scheme.tertiary, // Migrated from CBColors.matrixGreen
            letterSpacing: 2.0,
            fontWeight: FontWeight.bold,
            shadows: CBColors.textGlow(
              scheme.tertiary,
            ), // Migrated from CBColors.matrixGreen
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'CONNECT MULTIPLE ROUNDS FOR A FULL RECAP',
          style: CBTypography.labelSmall.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.5),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        CBTextField(
          controller: controller,
          autofocus: true,
          textStyle: CBTypography.bodyLarge.copyWith(color: scheme.onSurface),
          decoration: InputDecoration(
            labelText: 'SESSION NAME',
            labelStyle: CBTypography.bodyMedium.copyWith(
              color: scheme.tertiary.withValues(alpha: 0.7),
            ), // Migrated from CBColors.matrixGreen
            hintText: 'e.g. SATURDAY NIGHT FEVER',
            hintStyle: CBTypography.bodyMedium.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.2),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: scheme.tertiary,
              ), // Migrated from CBColors.matrixGreen
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CBGhostButton(
              label: 'ABORT',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            CBPrimaryButton(
              label: 'INITIALIZE',
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context, controller.text);
                }
              },
            ),
          ],
        ),
      ],
    ),
  );
}

Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'OK',
  String cancelLabel = 'CANCEL',
  Color? confirmColor,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showThemedDialog<bool>(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: CBTypography.headlineSmall.copyWith(
            color: confirmColor ?? scheme.secondary,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          content,
          style: CBTypography.body.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CBGhostButton(
              label: cancelLabel,
              onPressed: () => Navigator.pop(context, false),
            ),
            const SizedBox(width: 12),
            CBPrimaryButton(
              label: confirmLabel,
              backgroundColor: confirmColor,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ],
    ),
  );
}

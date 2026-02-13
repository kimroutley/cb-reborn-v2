import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showAIRecapExportMenu({
  required BuildContext context,
  required Game controller,
}) async {
  final textTheme = Theme.of(context).textTheme;
  final scheme = Theme.of(context).colorScheme;

  final selectedStyle = await showThemedBottomSheet<String>(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'GENERATE AI RECAP',
          style: textTheme.headlineMedium!.copyWith(color: scheme.primary),
        ),
        const SizedBox(height: CBSpace.x2),
        Text(
          'Select a personality style for Gemini to summarize the session.',
          style: textTheme.bodySmall!
              .copyWith(color: scheme.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: CBSpace.x6),
        _RecapOption(
          label: 'R-RATED & BRUTAL',
          icon: Icons.psychology,
          color: scheme.secondary, // Migrated from CBColors.hotPink
          style: 'r-rated',
        ),
        const SizedBox(height: CBSpace.x3),
        _RecapOption(
          label: 'SPICY CLUB VIBES',
          icon: Icons.local_bar,
          color: scheme.error, // Migrated from CBColors.alertOrange
          style: 'spicy',
        ),
        const SizedBox(height: CBSpace.x3),
        _RecapOption(
          label: 'PG DRAMATIC MYSTERY',
          icon: Icons.search,
          color: scheme.tertiary, // Migrated from CBColors.matrixGreen
          style: 'pg',
        ),
        const SizedBox(height: CBSpace.x6),
        Text(
          'This will copy a formatted prompt and game log to your clipboard.',
          style: CBTypography.nano.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.32),
          ),
        ),
      ],
    ),
  );

  if (selectedStyle == null) return;
  if (!context.mounted) return;

  final prompt = controller.generateAIRecapPrompt(selectedStyle);
  Clipboard.setData(ClipboardData(text: prompt));

  showThemedSnackBar(
    context,
    'Recap prompt ($selectedStyle) copied to clipboard!',
  );
}

class _RecapOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String style;

  const _RecapOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return CBGlassTile(
      title: label,
      icon: Icon(icon, color: color, size: 18),
      accentColor: color,
      isPrismatic: true,
      onTap: () => Navigator.of(context).pop(style),
      content: const SizedBox.shrink(),
    );
  }
}

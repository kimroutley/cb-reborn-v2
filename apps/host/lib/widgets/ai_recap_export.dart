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
    accentColor: scheme.secondary,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CBBottomSheetHandle(),
        Padding(
          padding: const EdgeInsets.fromLTRB(CBSpace.x5, CBSpace.x2, CBSpace.x5, CBSpace.x6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'AI MISSION RECAP',
                style: textTheme.headlineSmall!.copyWith(
                  color: scheme.secondary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  shadows: CBColors.textGlow(scheme.secondary, intensity: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CBSpace.x3),
              Text(
                'SELECT A PERSONALITY PROTOCOL FOR GEMINI TO SYNTHESIZE THE MISSION DEBRIEF.',
                style: textTheme.bodySmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: CBSpace.x6),
              _RecapOption(
                label: 'R-RATED & BRUTAL',
                icon: Icons.psychology_rounded,
                color: scheme.secondary,
                style: 'r-rated',
              ),
              const SizedBox(height: CBSpace.x3),
              _RecapOption(
                label: 'SPICY CLUB VIBES',
                icon: Icons.local_bar_rounded,
                color: scheme.error,
                style: 'spicy',
              ),
              const SizedBox(height: CBSpace.x3),
              _RecapOption(
                label: 'DRAMATIC MYSTERY',
                icon: Icons.search_rounded,
                color: scheme.tertiary,
                style: 'pg',
              ),
              const SizedBox(height: CBSpace.x6),
              Container(
                padding: const EdgeInsets.all(CBSpace.x3),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(CBRadius.sm),
                  border: Border.all(color: scheme.onSurface.withValues(alpha: 0.1)),
                ),
                child: Text(
                  'THIS WILL COPY A FORMATTED PROMPT AND GAME LOG TO YOUR TERMINAL CLIPBOARD.',
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
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
    'RECAP PROMPT (${selectedStyle.toUpperCase()}) ARCHIVED TO CLIPBOARD.',
    accentColor: scheme.secondary,
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
      borderColor: color.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(CBSpace.x4),
      onTap: () {
        HapticService.selection();
        Navigator.of(context).pop(style);
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CBSpace.x2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: CBSpace.x4),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5), size: 20),
        ],
      ),
    );
  }
}

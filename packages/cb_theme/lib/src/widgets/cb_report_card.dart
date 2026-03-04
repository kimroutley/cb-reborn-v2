import 'package:flutter/material.dart';
import '../../cb_theme.dart';

/// Report card showing a list of events or results.
class CBReportCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final Color? color;

  const CBReportCard({
    super.key,
    required this.title,
    required this.lines,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final accentColor = color ?? scheme.primary;

    return CBFadeSlide(
      child: CBGlassTile(
        borderColor: accentColor.withValues(alpha: 0.5),
        padding: const EdgeInsets.all(CBSpace.x6),
        isPrismatic: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(CBSpace.x2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.analytics_rounded,
                      color: accentColor, size: 20),
                ),
                const SizedBox(width: CBSpace.x3),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: textTheme.headlineSmall!.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      shadows: CBColors.textGlow(accentColor, intensity: 0.4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: CBSpace.x6),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '> ',
                      style: textTheme.bodySmall!.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'RobotoMono',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line.toUpperCase(),
                        style: textTheme.bodySmall!.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.8),
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

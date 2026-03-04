import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class HomeMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? accentColor;
  final int index;

  const HomeMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.accentColor,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final color = accentColor ?? scheme.primary;

    return CBFadeSlide(
      delay: Duration(milliseconds: 100 * index),
      child: CBGlassTile(
        onTap: () {
          HapticService.selection();
          onTap();
        },
        borderColor: color.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(CBSpace.x6),
        isPrismatic: index == 0, // Make the first item pop
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(CBSpace.x4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
                boxShadow: CBColors.circleGlow(color, intensity: 0.3),
              ),
              child: Icon(icon, size: 40, color: color, shadows: CBColors.iconGlow(color)),
            ),
            const SizedBox(height: CBSpace.x5),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: textTheme.labelLarge!.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                shadows: CBColors.textGlow(color, intensity: 0.4),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: CBSpace.x2),
              Text(
                subtitle!.toUpperCase(),
                textAlign: TextAlign.center,
                style: textTheme.labelSmall!.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

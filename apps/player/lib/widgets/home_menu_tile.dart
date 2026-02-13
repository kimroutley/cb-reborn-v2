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
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = accentColor ?? scheme.primary;

    return CBFadeSlide(
      delay: Duration(milliseconds: 90 * index),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(CBRadius.md),
          onTap: () {
            HapticService.selection();
            onTap();
          },
          child: CBPanel(
            padding: const EdgeInsets.all(CBSpace.x4),
            borderColor: color.withValues(alpha: 0.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 48, color: color),
                const SizedBox(height: CBSpace.x4),
                Text(
                  title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge!.copyWith(
                    color: color,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: CBSpace.x2),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall!.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

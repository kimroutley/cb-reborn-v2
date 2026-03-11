import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

/// An interactive "System Directive" card mimicking rich link-previews in messaging apps.
class CBActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? instruction;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String actionLabel;
  final Widget? trailing;
  final bool isPrimary;

  const CBActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.instruction,
    required this.icon,
    required this.color,
    required this.onTap,
    this.actionLabel = 'TAP TO ACT',
    this.trailing,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: CBSpace.x2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Strip (Mimicking a message header or rich card domain)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: CBSpace.x4, vertical: CBSpace.x3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: CBSpace.x2),
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            
            // Body Content
            Padding(
              padding: const EdgeInsets.all(CBSpace.x5),
              child: Column(
                children: [
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (instruction != null && instruction!.isNotEmpty) ...[
                    const SizedBox(height: CBSpace.x3),
                    Text(
                      instruction!,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: CBSpace.x5),
                  
                  // Faux "Link Preview" Action Button styling
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    decoration: BoxDecoration(
                      color: isPrimary ? color : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          actionLabel.toUpperCase(),
                          style: textTheme.labelSmall?.copyWith(
                            color: isPrimary ? scheme.onPrimary : scheme.onSurface,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color: isPrimary ? scheme.onPrimary : scheme.onSurface,
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

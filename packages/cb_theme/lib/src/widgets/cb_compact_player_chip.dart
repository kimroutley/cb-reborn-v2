import 'package:flutter/material.dart';

import '../layout.dart';

/// A compact player chip for inline selection in chat action bubbles.
class CBCompactPlayerChip extends StatelessWidget {
  final String name;
  final String? assetPath;
  final Color? color;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isDisabled;

  const CBCompactPlayerChip({
    super.key,
    required this.name,
    this.assetPath,
    this.color,
    this.onTap,
    this.isSelected = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = color ?? theme.colorScheme.primary;
    final effectiveOpacity = isDisabled ? 0.35 : 1.0;
    final bgColor = isSelected
        ? accentColor.withValues(alpha: 0.15)
        : theme.colorScheme.surface;
    final borderClr =
        isSelected ? accentColor : theme.colorScheme.outlineVariant;

    return Opacity(
      opacity: effectiveOpacity,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(CBRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(CBRadius.lg),
              border: Border.all(color: borderClr, width: 1.5),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tiny avatar
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: accentColor, width: 1),
                  ),
                  child: ClipOval(
                    child: assetPath != null
                        ? Image.asset(
                            assetPath!,
                            width: 14,
                            height: 14,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: accentColor,
                              size: 12,
                            ),
                          )
                        : Icon(Icons.person, color: accentColor, size: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name.toUpperCase(),
                  style: theme.textTheme.labelSmall!.copyWith(
                    color:
                        isSelected ? accentColor : theme.colorScheme.onSurface,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

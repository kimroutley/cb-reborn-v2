import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../colors.dart';
import '../layout.dart';
import 'cb_buttons.dart';
import 'glass_tile.dart';

class CBProfileActionButtons extends StatelessWidget {
  const CBProfileActionButtons({
    super.key,
    required this.saving,
    required this.canSave,
    required this.canDiscard,
    required this.onSave,
    required this.onDiscard,
    required this.onReload,
  });

  final bool saving;
  final bool canSave;
  final bool canDiscard;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CBPrimaryButton(
                label: saving ? 'SAVING...' : 'SAVE CHANGES',
                icon: Icons.save_rounded,
                onPressed: canSave ? onSave : null,
              ),
            ),
            const SizedBox(width: CBSpace.x2),
            Expanded(
              child: CBGhostButton(
                label: 'DISCARD',
                color: scheme.error,
                onPressed: canDiscard ? onDiscard : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: CBSpace.x3),
        TextButton.icon(
          label: Text(
            'FORCE RELOUD FROM CLOUD',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.5),
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
          icon: Icon(
            Icons.cloud_sync_rounded,
            size: 14,
            color: scheme.onSurface.withValues(alpha: 0.5),
          ),
          onPressed: saving ? null : onReload,
        ),
      ],
    );
  }
}

class CBProfileReadonlyRow extends StatelessWidget {
  const CBProfileReadonlyRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return CBGlassTile(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderColor: scheme.outlineVariant.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label COPIED TO CLIPBOARD'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: scheme.surfaceContainerHigh,
          ),
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface,
                    fontFamily: 'RobotoMono',
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.copy_rounded,
            size: 16,
            color: scheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}

class CBProfileAvatarChip extends StatelessWidget {
  const CBProfileAvatarChip({
    super.key,
    required this.emoji,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? scheme.tertiary.withValues(alpha: 0.15)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? scheme.tertiary
                  : scheme.outlineVariant.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? CBColors.boxGlow(scheme.tertiary, intensity: 0.4)
                : null,
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}

class CBProfilePreferenceChip extends StatelessWidget {
  const CBProfilePreferenceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: CBGlassTile(
        isSelected: selected,
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        borderColor: selected
            ? scheme.tertiary
            : scheme.outlineVariant.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: selected ? scheme.tertiary : scheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            shadows: selected ? CBColors.textGlow(scheme.tertiary, intensity: 0.4) : null,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CBPrimaryButton(
                label: saving ? 'Saving...' : 'Save Profile',
                icon: Icons.save_outlined,
                onPressed: canSave ? onSave : null,
              ),
            ),
            const SizedBox(width: CBSpace.x2),
            CBTextButton(
              label: 'Discard',
              onPressed: canDiscard ? onDiscard : null,
            ),
          ],
        ),
        const SizedBox(height: CBSpace.x2),
        CBTextButton(
          label: 'Reload From Cloud',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          value,
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface,
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.22)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
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
        borderRadius: BorderRadius.circular(12),
        borderColor: selected
            ? scheme.secondary
            : scheme.outlineVariant.withValues(alpha: 0.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: selected ? scheme.secondary : scheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

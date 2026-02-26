import 'package:flutter/material.dart';

class NarrationModeBadge extends StatelessWidget {
  final bool geminiNarrationEnabled;

  const NarrationModeBadge({super.key, required this.geminiNarrationEnabled});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (geminiNarrationEnabled ? scheme.tertiary : scheme.secondary)
                .withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: geminiNarrationEnabled
                  ? scheme.tertiary.withValues(alpha: 0.45)
                  : scheme.secondary.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            geminiNarrationEnabled
                ? 'NARRATION MODE: AI'
                : 'NARRATION MODE: STANDARD',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: geminiNarrationEnabled
                  ? scheme.tertiary
                  : scheme.secondary,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/ai_recap_export.dart';

class AIExportPanel extends ConsumerWidget {
  const AIExportPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return CBPanel(
      padding: const EdgeInsets.all(20),
      borderColor: scheme.secondary.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBBadge(text: 'AI RECAP EXPORT', color: scheme.secondary),
          const SizedBox(height: 16),

          Text(
            'Generate a Gemini-ready prompt for game recap',
            style: textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),

          // Export button (opens style menu)
          CBPrimaryButton(
            label: 'GENERATE AI RECAP',
            icon: Icons.auto_awesome,
            backgroundColor: scheme.secondary,
            foregroundColor: scheme.onSecondary,
            onPressed: () => showAIRecapExportMenu(
              context: context,
              controller: ref.read(gameProvider.notifier),
            ),
          ),
        ],
      ),
    );
  }
}

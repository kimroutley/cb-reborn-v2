import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai_recap_export.dart';

class AIExportPanel extends ConsumerWidget {
  const AIExportPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CBPanel(
      padding: const EdgeInsets.all(CBSpace.x5),
      borderColor: scheme.secondary.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CBSectionHeader(
            title: 'AI MISSION RECAP',
            icon: Icons.auto_awesome_rounded,
            color: scheme.secondary,
          ),
          const SizedBox(height: CBSpace.x4),

          Text(
            'GENERATE A GEMINI-READY PROMPT FOR AN IMMERSIVE MISSION DEBRIEF.',
            style: textTheme.bodySmall!.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: CBSpace.x5),

          CBPrimaryButton(
            label: 'GENERATE AI PROMPT',
            icon: Icons.auto_awesome_rounded,
            backgroundColor: scheme.secondary,
            onPressed: () {
              HapticService.heavy();
              showAIRecapExportMenu(
                context: context,
                controller: ref.read(gameProvider.notifier),
              );
            },
          ),
        ],
      ),
    );
  }
}

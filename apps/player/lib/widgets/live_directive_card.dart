import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

import '../player_bridge.dart';

class LiveDirectiveCard extends StatelessWidget {
  final StepSnapshot? step;
  final String phase;

  const LiveDirectiveCard({super.key, required this.step, required this.phase});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final title = step?.title ?? phase.toUpperCase();
    final text = step?.readAloudText ?? 'Awaiting host instruction.';

    return CBPanel(
      borderColor: scheme.primary,
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CBBadge(text: 'LIVE DIRECTIVE', color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            style: textTheme.labelLarge!.copyWith(
              color: scheme.onSurface,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(text, style: textTheme.bodySmall!),
        ],
      ),
    );
  }
}

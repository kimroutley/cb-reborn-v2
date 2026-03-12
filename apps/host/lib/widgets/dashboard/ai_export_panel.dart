import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/services.dart';

import '../host_settings.dart';

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
            title: 'MISSION LOG EXPORT',
            icon: Icons.receipt_long_rounded,
            color: scheme.secondary,
          ),
          const SizedBox(height: CBSpace.x4),

          Text(
            'COPY THE RAW MISSION LOG TO YOUR CLIPBOARD FOR ARCHIVING OR EXTERNAL USE.',
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
            label: 'COPY GAME LOG',
            icon: Icons.copy_rounded,
            backgroundColor: scheme.secondary,
            onPressed: () {
              HapticService.heavy();
              final log = ref.read(gameProvider.notifier).exportGameLog();
              Clipboard.setData(ClipboardData(text: log));
              showThemedSnackBar(
                context,
                'MISSION LOG COPIED TO CLIPBOARD.',
                accentColor: scheme.secondary,
              );
            },
          ),
        ],
      ),
    );
  }
}

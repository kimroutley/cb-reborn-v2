import 'package:cb_logic/cb_logic.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SimulationModeBadgeAction extends ConsumerWidget {
  const SimulationModeBadgeAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final gameState = ref.watch(gameProvider);
    final isSimulationSandbox = gameState.gameHistory.any(
      (entry) => entry.startsWith('[TEST] Sandbox game loaded.'),
    );

    if (!isSimulationSandbox) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.tertiary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.tertiary.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: scheme.tertiary.withValues(alpha: 0.18),
              blurRadius: 8,
              spreadRadius: 0.4,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.science_rounded,
              size: 14,
              color: CBColors.matrixGreen,
            ),
            const SizedBox(width: 4),
            Text(
              'SIMULATION MODE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.tertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

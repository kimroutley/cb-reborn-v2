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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: CBBadge(
        text: 'SIMULATION MODE',
        color: scheme.tertiary,
        icon: Icons.science_rounded,
      ),
    );
  }
}

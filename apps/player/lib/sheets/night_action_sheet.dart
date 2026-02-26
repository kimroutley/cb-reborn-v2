import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';
import '../player_bridge.dart';

class NightActionSheet extends StatelessWidget {
  final StepSnapshot step;
  final List<PlayerSnapshot> players;
  final Function(String) onAction;

  const NightActionSheet({
    super.key,
    required this.step,
    required this.players,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final accent = scheme.tertiary; // Was matrixGreen
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: CBInsets.screen,
          child: Text(
            'YOUR ACTION',
            style: textTheme.labelLarge!.copyWith(color: accent),
          ),
        ),

        // Content
        if (step.actionType == 'binaryChoice')
          Padding(
            padding: CBInsets.screen,
            child: Column(
              children: step.options.map((option) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: CBSpace.x3),
                  child: SizedBox(
                    width: double.infinity,
                    child: CBGhostButton(
                      label: option,
                      color: scheme.primary, // Was electricCyan
                      onPressed: () => onAction(option),
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: CBInsets.screen,
            itemCount: players.length,
            separatorBuilder: (_, __) => const SizedBox(height: CBSpace.x2),
            itemBuilder: (context, index) {
              final player = players[index];

              return CBPanel(
                padding: const EdgeInsets.symmetric(
                  horizontal: CBSpace.x4,
                  vertical: CBSpace.x3,
                ),
                borderColor: accent.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        player.name.toUpperCase(),
                        style: textTheme.bodyLarge!,
                      ),
                    ),
                    SizedBox(
                      width: 112,
                      child: CBGhostButton(
                        label: 'SELECT',
                        color: accent,
                        onPressed: () => onAction(player.id),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: CBSpace.x4),
      ],
    );
  }
}

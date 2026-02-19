import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class GameBottomControls extends StatelessWidget {
  const GameBottomControls({
    super.key,
    required this.step,
    required this.gameState,
    required this.controller,
    required this.onConfirm,
    required this.onContinue,
  });

  final ScriptStep? step;
  final GameState gameState;
  final Game controller;
  final VoidCallback onConfirm;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    if (step == null) {
      return const SizedBox.shrink();
    }

    final isMultiSelect =
        step!.actionType == ScriptActionType.selectTwoPlayers ||
            step!.actionType == ScriptActionType.multiSelect;

    final currentSelection = gameState.actionLog[step!.id];
    final canConfirm = isMultiSelect
        ? (currentSelection != null && currentSelection.split(',').length >= 2)
        : currentSelection != null;

    final canSimulate = step!.id == 'day_vote' ||
        step!.actionType == ScriptActionType.selectPlayer ||
        isMultiSelect ||
        step!.actionType == ScriptActionType.optional ||
        step!.actionType == ScriptActionType.binaryChoice;

    final theme = Theme.of(context);

    return CBPanel(
      margin: const EdgeInsets.all(12),
      borderColor: theme.colorScheme.primary,
      child: Row(
        children: [
          if (canSimulate)
            Expanded(
              child: CBGhostButton(
                label: 'SIMULATE BOTS',
                color: theme.colorScheme.tertiary,
                onPressed: () {
                  final count = controller.simulateBotTurns();

                  // If no bots acted, try falling back to full simulation if no real players exist (Legacy Sandbox support)
                  // Or just inform user.
                  if (count == 0) {
                    // Check if we should fallback to legacy simulation (e.g. if I am testing alone without bots added explicitly)
                    // For now, let's stick to the requested bot logic.
                    showThemedSnackBar(
                      context,
                      'No active bots found for this step.',
                      accentColor: theme.colorScheme.error,
                      duration: const Duration(seconds: 2),
                    );
                  } else {
                    showThemedSnackBar(
                      context,
                      'Simulated $count bot action${count == 1 ? '' : 's'}.',
                      accentColor: theme.colorScheme.tertiary,
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
              ),
            ),
          if (canSimulate) const SizedBox(width: 8),
          if (isMultiSelect)
            Expanded(
              child: CBPrimaryButton(
                label: 'CONFIRM',
                icon: Icons.check_circle_outline,
                onPressed: canConfirm ? onConfirm : null,
              ),
            ),
          if (!isMultiSelect)
            Expanded(
              child: CBPrimaryButton(
                label: 'CONTINUE',
                icon: Icons.arrow_forward,
                onPressed: () => onContinue(),
              ),
            ),
        ],
      ),
    );
  }
}

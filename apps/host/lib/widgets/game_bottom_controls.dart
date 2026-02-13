import 'package:cb_logic/cb_logic.dart';
import 'package:cb_models/cb_models.dart';
import 'package:cb_theme/cb_theme.dart';
import 'package:flutter/material.dart';

class GameBottomControls extends StatelessWidget {
  const GameBottomControls({
    super.key,
    required this.step,
    required this.controller,
    required this.firstPickId,
    required this.onConfirm,
    required this.onContinue,
  });

  final ScriptStep? step;
  final Game controller;
  final String? firstPickId;
  final VoidCallback onConfirm;
  final Future<void> Function() onContinue;

  @override
  Widget build(BuildContext context) {
    if (step == null) {
      return const SizedBox.shrink();
    }

    final canConfirm = firstPickId != null;
    final canSimulate = step!.id == 'day_vote' ||
        step!.actionType == ScriptActionType.selectPlayer ||
        step!.actionType == ScriptActionType.selectTwoPlayers ||
        step!.actionType == ScriptActionType.optional ||
        step!.actionType == ScriptActionType.multiSelect ||
        step!.actionType == ScriptActionType.binaryChoice;

    return CBPanel(
      margin: const EdgeInsets.all(12),
      borderColor: CBColors.primary,
      child: Row(
        children: [
          if (canSimulate)
            Expanded(
              child: CBGhostButton(
                label: 'SIMULATE PLAYERS',
                color: CBColors.matrixGreen,
                onPressed: () {
                  final count = controller.simulatePlayersForCurrentStep();
                  showThemedSnackBar(
                    context,
                    count > 0
                        ? 'Simulated $count player action${count == 1 ? '' : 's'}.'
                        : 'No simulated input available for this step.',
                    accentColor:
                        count > 0 ? CBColors.matrixGreen : CBColors.warning,
                    duration: const Duration(seconds: 2),
                  );
                },
              ),
            ),
          if (canSimulate) const SizedBox(width: 8),
          if (step!.actionType == ScriptActionType.selectTwoPlayers)
            Expanded(
              child: CBPrimaryButton(
                label: 'CONFIRM',
                icon: Icons.check_circle_outline,
                onPressed: canConfirm
                    ? () {
                        controller.handleInteraction(
                          stepId: step!.id,
                          targetId: firstPickId,
                        );
                        onConfirm();
                      }
                    : null,
              ),
            ),
          if (step!.actionType != ScriptActionType.selectTwoPlayers)
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
